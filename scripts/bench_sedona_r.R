library(sedonadb)
library(sf)
library(microbenchmark)
library(dplyr)

message("Starting R (sedonadb) Benchmarks [NZ]...")

# Helper to log results
log_result <- function(operation, benchmark) {
  mean_sec <- mean(benchmark$time) / 1e9
  ops_per_sec <- 1 / mean_sec
  cat(sprintf("sedonadb-sf,R,%s,%.2f\n", operation, ops_per_sec), 
      file = "results.csv", append = TRUE)
}

# Read data
pts_sf <- st_read("nz_points.gpkg", quiet = TRUE)
regions_sf <- st_read("nz_regions.gpkg", quiet = TRUE)

# 1. Load
bench_load_pts <- microbenchmark(
  load_points = { 
    pts_sf |> sd_to_view("points", overwrite = TRUE)
  },
  times = 5
)
print(bench_load_pts)
log_result("read_points", bench_load_pts)

bench_load_regions <- microbenchmark(
  load_regions = { 
    regions_sf |> sd_to_view("regions", overwrite = TRUE)
  },
  times = 5
)
print(bench_load_regions)
log_result("read_regions", bench_load_regions)

# Ensure views
pts_sf |> sd_to_view("points", overwrite = TRUE)
regions_sf |> sd_to_view("regions", overwrite = TRUE)

# 2. Buffer
tryCatch({
  bench_buffer <- microbenchmark(
    buffer_pts = { 
      sd_sql("SELECT ST_Buffer(geom, 1000) as geom FROM points") |> sd_collect()
    },
    times = 5
  )
  print(bench_buffer)
  log_result("buffer_pts", bench_buffer)
}, error = function(e) message("Buffer failed: ", e$message))

# 3. Spatial Join
tryCatch({
  query <- 'SELECT p.geom, r."Name" FROM points AS p LEFT JOIN regions AS r ON ST_Intersects(p.geom, r.geom)'
  bench_sjoin <- microbenchmark(
    spatial_join = { 
      sd_sql(query) |> sd_collect()
    },
    times = 5
  )
  print(bench_sjoin)
  log_result("spatial_join", bench_sjoin)
}, error = function(e) message("Spatial Join failed: ", e$message))

message("R (sedonadb) Benchmarks Complete.")
