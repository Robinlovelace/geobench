library(sedonadb)
library(sf)
library(microbenchmark)
library(dplyr)

message("Starting R (sedonadb) Benchmarks...")

# Helper to log results
log_result <- function(operation, benchmark) {
  mean_sec <- mean(benchmark$time) / 1e9
  cat(sprintf("sedonadb,R,%s,%.6f\n", operation, mean_sec), 
      file = "results.csv", append = TRUE)
}

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
log_result("load_points", bench_load[bench_load$expr == "load_points",])
log_result("load_polys", bench_load[bench_load$expr == "load_polys",])

# Ensure views are ready
pts_sf |> sd_to_view("points", overwrite = TRUE)
polys_sf |> sd_to_view("polygons", overwrite = TRUE)

# 2. Transform (Projection)
tryCatch({
  bench_transform <- microbenchmark(
    transform_pts = { 
      sd_sql("SELECT ST_Transform(geom, 'EPSG:27700') as geom FROM points") |> 
        sd_collect() 
    },
    times = 5
  )
  print(bench_transform)
  log_result("transform_pts", bench_transform)

  # Create transformed views for next steps
  sd_sql("SELECT ST_Transform(geom, 'EPSG:27700') as geom FROM points") |> 
    sd_to_view("points_proj", overwrite = TRUE)
  sd_sql("SELECT ST_Transform(geom, 'EPSG:27700') as geom FROM polygons") |> 
    sd_to_view("polys_proj", overwrite = TRUE)

  # 3. Buffer
  bench_buffer <- microbenchmark(
    buffer_pts = { 
      sd_sql("SELECT ST_Buffer(geom, 100) as geom FROM points_proj") |> 
        sd_collect()
    },
    times = 5
  )
  print(bench_buffer)
  log_result("buffer_pts", bench_buffer)

  # 4. Intersection
  # Spatial Join using ST_Intersects
  bench_intersect <- microbenchmark(
    intersection = { 
      sd_sql("
        SELECT p.geom 
        FROM points_proj AS p, polys_proj AS poly 
        WHERE ST_Intersects(p.geom, poly.geom)
      ") |> sd_collect()
    },
    times = 5
  )
  print(bench_intersect)
  log_result("intersection", bench_intersect)

}, error = function(e) {
  message("Skipping remaining SedonaDB benchmarks due to error: ", e$message)
})

message("R (sedonadb) Benchmarks Complete.")
