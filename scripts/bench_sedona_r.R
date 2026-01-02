library(sedonadb)
library(sf)
library(microbenchmark)
library(dplyr)

message("Starting R (sedonadb) Benchmarks...")

# Setup: Read data with sf (since sedonadb reads parquet/arrow best, but we have gpkg)
pts_sf <- st_read("data.gpkg", layer = "points", quiet = TRUE)
polys_sf <- st_read("data.gpkg", layer = "polygons", quiet = TRUE)

# 1. Load to SedonaDB (View creation)
bench_load <- microbenchmark(
  load_points = { 
    pts_sf |> sd_to_view("points", overwrite = TRUE)
  },
  load_polys = { 
    polys_sf |> sd_to_view("polygons", overwrite = TRUE)
  },
  times = 5
)
print(bench_load)

# Ensure views are ready
pts_sf |> sd_to_view("points", overwrite = TRUE)
polys_sf |> sd_to_view("polygons", overwrite = TRUE)

# 2. Transform (Projection)
# ST_Transform in Sedona. EPSG:27700.
# Note: We need to collect() to force execution if it's lazy, but sd_sql returns a relation.
# To benchmark processing, we should probably include retrieval or at least execution.
# sd_collect() brings it back to R (arrow table or data frame).
bench_transform <- microbenchmark(
  transform_pts = { 
    sd_sql("SELECT ST_Transform(geometry, 'EPSG:27700') as geometry FROM points") |> 
      sd_collect() 
  },
  times = 5
)
print(bench_transform)

# Create transformed views for next steps
sd_sql("SELECT ST_Transform(geometry, 'EPSG:27700') as geometry FROM points") |> 
  sd_to_view("points_proj", overwrite = TRUE)
sd_sql("SELECT ST_Transform(geometry, 'EPSG:27700') as geometry FROM polygons") |> 
  sd_to_view("polys_proj", overwrite = TRUE)

# 3. Buffer
bench_buffer <- microbenchmark(
  buffer_pts = { 
    sd_sql("SELECT ST_Buffer(geometry, 100) as geometry FROM points_proj") |> 
      sd_collect()
  },
  times = 5
)
print(bench_buffer)

# 4. Intersection
# Spatial Join using ST_Intersects
bench_intersect <- microbenchmark(
  intersection = { 
    sd_sql("
      SELECT p.geometry 
      FROM points_proj AS p, polys_proj AS poly 
      WHERE ST_Intersects(p.geometry, poly.geometry)
    ") |> sd_collect()
  },
  times = 5
)
print(bench_intersect)

message("R (sedonadb) Benchmarks Complete.")
