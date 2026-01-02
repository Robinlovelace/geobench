library(sf)
library(dplyr)

set.seed(42)

# Parameters
n_points <- 100000
n_polys <- 100

message("Generating ", n_points, " points (projected)...")
# Generate random points in lon/lat first for ease, then project
lon <- runif(n_points, min = -6, max = 2)
lat <- runif(n_points, min = 50, max = 59)
points <- st_as_sf(data.frame(lon, lat), coords = c("lon", "lat"), crs = 4326)
points_proj <- st_transform(points, 27700)

message("Generating ", n_polys, " polygons (projected)...")
poly_centers <- st_as_sf(data.frame(
  lon = runif(n_polys, min = -6, max = 2),
  lat = runif(n_polys, min = 50, max = 59)
), coords = c("lon", "lat"), crs = 4326)
poly_centers_proj <- st_transform(poly_centers, 27700)

# Buffer by 10km (10000 meters)
polys_proj <- st_buffer(poly_centers_proj, dist = 10000)

message("Saving to data_projected.gpkg...")
st_write(points_proj, "data_projected.gpkg", layer = "points", delete_layer = TRUE, quiet = TRUE)
st_write(polys_proj, "data_projected.gpkg", layer = "polygons", delete_layer = TRUE, quiet = TRUE)
message("Done.")
