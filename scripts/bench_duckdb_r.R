library(duckdb)
library(microbenchmark)
library(dplyr)

con <- dbConnect(duckdb())
dbExecute(con, "INSTALL spatial; LOAD spatial;")

message("Starting R (DuckDB) Benchmarks [NZ]...")

# --- 0. Data Preparation ---
if (!file.exists("nz_points.parquet")) {
  dbExecute(
    con,
    "COPY (SELECT * FROM ST_Read('nz_points.gpkg')) TO 'nz_points.parquet' (FORMAT PARQUET);"
  )
}
if (!file.exists("nz_regions.parquet")) {
  dbExecute(
    con,
    "COPY (SELECT * FROM ST_Read('nz_regions.gpkg')) TO 'nz_regions.parquet' (FORMAT PARQUET);"
  )
}

log_result <- function(system_name, operation, benchmark) {
  mean_sec <- mean(benchmark$time) / 1e9
  ops_per_sec <- 1 / mean_sec
  cat(
    sprintf("%s,R,%s,%.2f\n", system_name, operation, ops_per_sec),
    file = "results.csv",
    append = TRUE
  )
}

# ==============================================================================
# SYSTEM 1: duckdb-parquet (Disk-Based / Zero-Copy)
# ==============================================================================

# 1. READ
bench_read_pq <- microbenchmark(
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
  bench_read_pq[bench_read_pq$expr == "read_points", ]
)
log_result(
  "duckdb-parquet",
  "read_regions",
  bench_read_pq[bench_read_pq$expr == "read_regions", ]
)

# 2. SPATIAL JOIN (Scan from Disk)
query_join_pq <- "
SELECT p.geom, r.Name
FROM 'nz_points.parquet' AS p
LEFT JOIN 'nz_regions.parquet' AS r
ON ST_Intersects(p.geom, r.geom)
"
bench_join_pq <- microbenchmark(
  spatial_join = {
    res <- dbGetQuery(con, query_join_pq)
  },
  times = 5
)
log_result("duckdb-parquet", "spatial_join", bench_join_pq)

# 3. BUFFER (Scan from Disk)
bench_buffer_pq <- microbenchmark(
  buffer_pts = {
    res <- dbGetQuery(
      con,
      "SELECT ST_Buffer(geom, 1000) FROM 'nz_points.parquet'"
    )
  },
  times = 5
)
log_result("duckdb-parquet", "buffer_pts", bench_buffer_pq)


# ==============================================================================
# SYSTEM 2: duckdb-memory (In-Memory / Optimized)
# ==============================================================================
message("Preparing In-Memory Data (Optimized)...")
# Load standard tables for Read/Buffer benchmarks
dbExecute(
  con,
  "CREATE OR REPLACE TABLE points AS SELECT * FROM 'nz_points.parquet'"
)
dbExecute(
  con,
  "CREATE OR REPLACE TABLE regions AS SELECT * FROM 'nz_regions.parquet'"
)

# Create Optimized Structures for Join Benchmark (Index + Point2D)
dbExecute(con, "CREATE INDEX idx_regions_geom ON regions USING RTREE (geom)")
dbExecute(
  con,
  "CREATE OR REPLACE TABLE points_2d AS SELECT ST_Point2D(ST_X(geom), ST_Y(geom)) AS geom FROM points"
)

# 1. READ (Select from Memory)
bench_read_mem <- microbenchmark(
  read_points = {
    res <- dbGetQuery(con, "SELECT * FROM points")
  },
  read_regions = {
    res <- dbGetQuery(con, "SELECT * FROM regions")
  },
  times = 5
)
log_result(
  "duckdb-memory",
  "read_points",
  bench_read_mem[bench_read_mem$expr == "read_points", ]
)
log_result(
  "duckdb-memory",
  "read_regions",
  bench_read_mem[bench_read_mem$expr == "read_regions", ]
)

# 2. SPATIAL JOIN (Optimized In-Memory)
query_join_opt <- "
SELECT p.geom, r.Name
FROM points_2d AS p
LEFT JOIN regions AS r
ON ST_Intersects(p.geom, r.geom)
"
bench_join_mem <- microbenchmark(
  spatial_join = {
    res <- dbGetQuery(con, query_join_opt)
  },
  times = 5
)
log_result("duckdb-memory", "spatial_join", bench_join_mem)

# 3. BUFFER (Standard In-Memory)
bench_buffer_mem <- microbenchmark(
  buffer_pts = {
    res <- dbGetQuery(con, "SELECT ST_Buffer(geom, 1000) FROM points")
  },
  times = 5
)
log_result("duckdb-memory", "buffer_pts", bench_buffer_mem)

dbDisconnect(con, shutdown = TRUE)
message("DuckDB Benchmarks Complete.")
