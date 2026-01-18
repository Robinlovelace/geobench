library(duckdb)
library(microbenchmark)
library(dplyr)

con <- dbConnect(duckdb())
dbExecute(con, "INSTALL spatial; LOAD spatial;")

message("Starting R (DuckDB) Benchmarks [NZ]...")

# --- 0. Data Preparation ---
if (!file.exists("nz_points.parquet")) {
  message("Generating nz_points.parquet from GPKG...")
  dbExecute(
    con,
    "COPY (SELECT * FROM ST_Read('nz_points.gpkg')) TO 'nz_points.parquet' (FORMAT PARQUET);"
  )
}
if (!file.exists("nz_regions.parquet")) {
  message("Generating nz_regions.parquet from GPKG...")
  dbExecute(
    con,
    "COPY (SELECT * FROM ST_Read('nz_regions.gpkg')) TO 'nz_regions.parquet' (FORMAT PARQUET);"
  )
}

# Helper to log results
log_result <- function(system_name, operation, benchmark) {
  mean_sec <- mean(benchmark$time) / 1e9
  ops_per_sec <- 1 / mean_sec
  cat(
    sprintf("%s,R,%s,%.2f\n", system_name, operation, ops_per_sec),
    file = "results.csv",
    append = TRUE
  )
}

# ---------------------------------------------------------
# SYSTEM 1: duckdb-parquet (Best Case for Reading)
# ---------------------------------------------------------
bench_read <- microbenchmark(
  read_points = {
    res <- dbGetQuery(con, "SELECT * FROM 'nz_points.parquet'")
  },
  read_regions = {
    res <- dbGetQuery(con, "SELECT * FROM 'nz_regions.parquet'")
  },
  times = 5
)
log_result(
  "duckdb-parquet",
  "read_points",
  bench_read[bench_read$expr == "read_points", ]
)
log_result(
  "duckdb-parquet",
  "read_regions",
  bench_read[bench_read$expr == "read_regions", ]
)


# ---------------------------------------------------------
# SETUP FOR MEMORY (Best Case Configuration)
# ---------------------------------------------------------
message("Preparing In-Memory Data (Optimized)...")

# 1. Load Regions & Build R-Tree Index (Crucial for Join Speed)
dbExecute(
  con,
  "CREATE OR REPLACE TABLE regions AS SELECT * FROM 'nz_regions.parquet'"
)
dbExecute(con, "CREATE INDEX idx_regions_geom ON regions USING RTREE (geom)")

# 2. Load Points as Native 2D Structs (Crucial for Memory/Cache Speed)
# We keep a standard 'points' table for Buffer, and 'points_2d' for Join if needed
dbExecute(
  con,
  "CREATE OR REPLACE TABLE points AS SELECT * FROM 'nz_points.parquet'"
)
dbExecute(
  con,
  "CREATE OR REPLACE TABLE points_2d AS SELECT ST_Point2D(ST_X(geom), ST_Y(geom)) AS geom FROM points"
)


# ---------------------------------------------------------
# SYSTEM 2: duckdb-memory (Best Case for Compute)
# ---------------------------------------------------------

# A. Spatial Join (Optimized with Index + Point2D)
query_join_opt <- "
SELECT p.geom, r.Name
FROM points_2d AS p
LEFT JOIN regions AS r
ON ST_Intersects(p.geom, r.geom)
"
bench_join <- microbenchmark(
  spatial_join = {
    res <- dbGetQuery(con, query_join_opt)
  },
  times = 5
)
print(bench_join)
log_result("duckdb-memory", "spatial_join", bench_join)

# B. Buffer (Using Standard Geometry table)
bench_buffer <- microbenchmark(
  buffer_pts = {
    res <- dbGetQuery(con, "SELECT ST_Buffer(geom, 1000) FROM points")
  },
  times = 5
)
print(bench_buffer)
log_result("duckdb-memory", "buffer_pts", bench_buffer)

dbDisconnect(con, shutdown = TRUE)
message("DuckDB Benchmarks Complete.")
