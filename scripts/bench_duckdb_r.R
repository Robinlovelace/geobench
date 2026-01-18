library(duckdb)
library(microbenchmark)
library(dplyr)

# Setup DuckDB connection
con <- dbConnect(duckdb())
dbExecute(con, "INSTALL spatial; LOAD spatial;")

message("Starting R (DuckDB) Benchmarks [NZ]...")

# --- 0. Data Preparation ---
# Ensure Parquet files exist
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

# --- Load into Memory (The "Fair" Comparison) ---
message("Loading Parquet into in-memory DuckDB tables...")
dbExecute(
  con,
  "CREATE OR REPLACE TABLE points AS SELECT * FROM 'nz_points.parquet'"
)
dbExecute(
  con,
  "CREATE OR REPLACE TABLE regions AS SELECT * FROM 'nz_regions.parquet'"
)

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

# --- 1. Read Benchmarks (Disk -> R Memory) ---

# System: duckdb-parquet
# We measure the time to select * from parquet
bench_read_parquet <- microbenchmark(
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
  bench_read_parquet[bench_read_parquet$expr == "read_points", ]
)
log_result(
  "duckdb-parquet",
  "read_regions",
  bench_read_parquet[bench_read_parquet$expr == "read_regions", ]
)


# --- 2. Spatial Join Benchmarks ---

# System: duckdb-parquet (Disk-based)
query_join_parquet <- "
SELECT p.geom, r.Name
FROM 'nz_points.parquet' AS p
LEFT JOIN 'nz_regions.parquet' AS r
ON ST_Intersects(p.geom, r.geom)
"

bench_join_parquet <- microbenchmark(
  spatial_join = {
    res <- dbGetQuery(con, query_join_parquet)
  },
  times = 5
)
print(bench_join_parquet)
log_result("duckdb-parquet", "spatial_join", bench_join_parquet)

# System: duckdb-memory (In-Memory)
# This uses the pre-loaded tables 'points' and 'regions'
query_join_memory <- "
SELECT p.geom, r.Name
FROM points AS p
LEFT JOIN regions AS r
ON ST_Intersects(p.geom, r.geom)
"

bench_join_memory <- microbenchmark(
  spatial_join = {
    res <- dbGetQuery(con, query_join_memory)
  },
  times = 5
)
print(bench_join_memory)
log_result("duckdb-memory", "spatial_join", bench_join_memory)


# --- 3. Buffer Benchmarks ---

# System: duckdb-parquet
bench_buffer_parquet <- microbenchmark(
  buffer_pts = {
    res <- dbGetQuery(
      con,
      "SELECT ST_Buffer(geom, 1000) FROM 'nz_points.parquet'"
    )
  },
  times = 5
)
log_result("duckdb-parquet", "buffer_pts", bench_buffer_parquet)

# System: duckdb-memory
bench_buffer_memory <- microbenchmark(
  buffer_pts = {
    res <- dbGetQuery(con, "SELECT ST_Buffer(geom, 1000) FROM points")
  },
  times = 5
)
print(bench_buffer_memory)
log_result("duckdb-memory", "buffer_pts", bench_buffer_memory)

# Clean up
dbDisconnect(con, shutdown = TRUE)
message("DuckDB Benchmarks Complete.")
