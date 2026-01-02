library(sf)
library(microbenchmark)
library(dplyr)

message("Starting R (sf) Spatial Join Benchmarks...")

# Helper to log results
log_result <- function(operation, benchmark) {
  mean_sec <- mean(benchmark$time) / 1e9
  cat(sprintf("sf,R,%s,%.6f\n", operation, mean_sec), 
      file = "results.csv", append = TRUE)
}

# Read projected data
pts <- st_read("data_projected.gpkg", layer = "points", quiet = TRUE)
polys <- st_read("data_projected.gpkg", layer = "polygons", quiet = TRUE)

# Ensure polys has the id column (it should)
# Spatial Join: st_join(x, y)
# We select only "id" from polys to mimic world["name_long"]
polys_subset <- polys[, "id"]

bench_sjoin <- microbenchmark(
  sjoin = { 
    result <- st_join(pts, polys_subset) 
  },
  times = 5
)
print(bench_sjoin)
log_result("spatial_join", bench_sjoin)

message("R Spatial Join Benchmarks Complete.")

