library(sf)
library(microbenchmark)
library(dplyr)

message("Starting R (sf) Benchmarks...")

# 1. Read
bench_read <- microbenchmark(
  read_points = { pts <- st_read("data.gpkg", layer = "points", quiet = TRUE) },
  read_polys = { polys <- st_read("data.gpkg", layer = "polygons", quiet = TRUE) },
  times = 5
)
print(bench_read)

pts <- st_read("data.gpkg", layer = "points", quiet = TRUE)
polys <- st_read("data.gpkg", layer = "polygons", quiet = TRUE)

# 2. Transform (Projection)
# Transform to British National Grid (EPSG:27700)
bench_transform <- microbenchmark(
  transform_pts = { pts_proj <- st_transform(pts, 27700) },
  times = 5
)
print(bench_transform)
pts_proj <- st_transform(pts, 27700)
polys_proj <- st_transform(polys, 27700)

# 3. Buffer
# Buffer points by 100 meters
bench_buffer <- microbenchmark(
  buffer_pts = { pts_buf <- st_buffer(pts_proj, dist = 100) },
  times = 5
)
print(bench_buffer)

# 4. Intersection
# Points in Polygons
bench_intersect <- microbenchmark(
  intersection = { result <- st_intersection(pts_proj, polys_proj) },
  times = 5
)
print(bench_intersect)

message("R Benchmarks Complete.")
