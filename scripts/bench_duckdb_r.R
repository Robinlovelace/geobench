library(duckdb)
library(microbenchmark)
library(dplyr)

# Setup DuckDB connection
con <- dbConnect(duckdb())
dbExecute(con, "INSTALL spatial; LOAD spatial;")

message("Starting R (DuckDB) Benchmarks [NZ]...")

# --- 0. Data Preparation ---
# Ensure Parquet files exist (Generate from GPKG if needed)
if (!file.exists("nz_points.parquet")) {
  message("Generating nz_points.parquet from GPKG...")
  # We use ST_Read to load the GPKG and COPY to write Parquet
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

# Helper to log results to the main CSV
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

# System: duckdb-gpkg (Traditional)
bench_read_gpkg <- microbenchmark(
  read_points = {
    res <- dbGetQuery(con, "SELECT * FROM ST_Read('nz_points.gpkg')")
  },
  read_regions = {
    res <- dbGetQuery(con, "SELECT * FROM ST_Read('nz_regions.gpkg')")
  },
  times = 5
)
print(bench_read_gpkg)
log_result(
  "duckdb-gpkg",
  "read_points",
  bench_read_gpkg[bench_read_gpkg$expr == "read_points", ]
)
log_result(
  "duckdb-gpkg",
  "read_regions",
  bench_read_gpkg[bench_read_gpkg$expr == "read_regions", ]
)

# System: duckdb-parquet (Parquet)
bench_read_parquet <- microbenchmark(
  read_points = {
    res <- dbGetQuery(con, "SELECT * FROM 'nz_points.parquet'")
  },
  read_regions = {
    res <- dbGetQuery(con, "SELECT * FROM 'nz_regions.parquet'")
  },
  times = 5
)
print(bench_read_parquet)
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
# Operation: Join Points with Regions (Left Join)

# System: duckdb-gpkg
# We use ST_Read directly in the query to mimic accessing traditional files
query_join_gpkg <- "
SELECT p.geom, r.Name
FROM ST_Read('nz_points.gpkg') AS p
LEFT JOIN ST_Read('nz_regions.gpkg') AS r
ON ST_Intersects(p.geom, r.geom)
"

bench_join_gpkg <- microbenchmark(
  spatial_join = {
    res <- dbGetQuery(con, query_join_gpkg)
  },
  times = 5
)
print(bench_join_gpkg)
log_result("duckdb-gpkg", "spatial_join", bench_join_gpkg)

# System: duckdb-parquet
# We read Parquet directly. Note: WKB geometry usually requires explicit casting
# via ST_GeomFromWKB when reading from Parquet if not automatically detected.
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

# Clean up
dbDisconnect(con, shutdown = TRUE)
message("DuckDB Benchmarks Complete.")
