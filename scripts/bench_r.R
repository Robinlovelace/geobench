library(sf)
library(microbenchmark)
library(dplyr)

# Helper to log results
log_result <- function(operation, benchmark) {
  mean_sec <- mean(benchmark$time) / 1e9
  cat(sprintf("sf,R,%s,%.6f\n", operation, mean_sec), 
      file = "results.csv", append = TRUE)
}

message("Starting R (sf) Benchmarks [NZ]...")

# 1. Read
bench_read <- microbenchmark(
  read_points = { pts <- st_read("nz.gpkg", layer = "points", quiet = TRUE) },
  read_regions = { regions <- st_read("nz.gpkg", layer = "regions", quiet = TRUE) },
  times = 5
)
print(bench_read)
log_result("read_points", bench_read[bench_read$expr == "read_points",])
log_result("read_regions", bench_read[bench_read$expr == "read_regions",])

pts <- st_read("nz.gpkg", layer = "points", quiet = TRUE)
regions <- st_read("nz.gpkg", layer = "regions", quiet = TRUE)

# 2. Spatial Join
# Join 'Name' from regions to points
regions_subset <- regions[, "Name"]

bench_sjoin <- microbenchmark(
  spatial_join = { 
    result <- st_join(pts, regions_subset) 
  },
  times = 5
)
print(bench_sjoin)
log_result("spatial_join", bench_sjoin)

message("R Benchmarks Complete.")