library(sf)
library(microbenchmark)
library(dplyr)

# Helper to log results
log_result <- function(operation, benchmark) {
  # Get median time in seconds (microbenchmark defaults to nanoseconds or microseconds depending, 
  # but summary returns in the requested unit if specified, or we can convert)
  # Actually summary(benchmark)$median is in the unit of the print output usually.
  # Let's use mean time in seconds for simplicity and consistency with the Python script.
  # microbenchmark$time is in nanoseconds.
  
  mean_sec <- mean(benchmark$time) / 1e9
  
  cat(sprintf("sf,R,%s,%.6f\n", operation, mean_sec), 
      file = "results.csv", append = TRUE)
}

message("Starting R (sf) Benchmarks...")

# Initialize csv if not exists (or just append, run_all.sh can clear it)
# We assume run_all.sh will handle clearing or we just append.

# 1. Read
bench_read <- microbenchmark(
  read_points = { pts <- st_read("data.gpkg", layer = "points", quiet = TRUE) },
  read_polys = { polys <- st_read("data.gpkg", layer = "polygons", quiet = TRUE) },
  times = 5
)
print(bench_read)
log_result("read_points", bench_read[bench_read$expr == "read_points",])
log_result("read_polys", bench_read[bench_read$expr == "read_polys",])

pts <- st_read("data.gpkg", layer = "points", quiet = TRUE)
polys <- st_read("data.gpkg", layer = "polygons", quiet = TRUE)

# 2. Transform (Projection)
# Transform to British National Grid (EPSG:27700)
bench_transform <- microbenchmark(
  transform_pts = { pts_proj <- st_transform(pts, 27700) },
  times = 5
)
print(bench_transform)
log_result("transform_pts", bench_transform)

pts_proj <- st_transform(pts, 27700)
polys_proj <- st_transform(polys, 27700)

# 3. Buffer
# Buffer points by 100 meters
bench_buffer <- microbenchmark(
  buffer_pts = { pts_buf <- st_buffer(pts_proj, dist = 100) },
  times = 5
)
print(bench_buffer)
log_result("buffer_pts", bench_buffer)

# 4. Intersection
# Points in Polygons
bench_intersect <- microbenchmark(
  intersection = { result <- st_intersection(pts_proj, polys_proj) },
  times = 5
)
print(bench_intersect)
log_result("intersection", bench_intersect)

message("R Benchmarks Complete.")
