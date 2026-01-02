library(sf)
library(dplyr)

set.seed(42)

# Parameters
n_points <- 100000
n_polys <- 100

message("Generating ", n_points, " points...")
# Generate random points in lon/lat
# Bounds roughly UK
lon <- runif(n_points, min = -6, max = 2)
lat <- runif(n_points, min = 50, max = 59)
points <- st_as_sf(data.frame(lon, lat), coords = c("lon", "lat"), crs = 4326)

message("Generating ", n_polys, " polygons...")
# Generate random small polygons
# Create centers
poly_centers <- st_as_sf(data.frame(
  lon = runif(n_polys, min = -6, max = 2),
  lat = runif(n_polys, min = 50, max = 59)
), coords = c("lon", "lat"), crs = 4326)

# Buffer centers to create polygons (approx 10km radius)
polys <- st_buffer(poly_centers, dist = 10000) # This is in degrees if 4326, but st_buffer in sf acts on s2 by default for 4326.
# To be safe and simple for comparison, let's project first for generation or just use raw degrees if we accept distortion.
# Actually, let's generate in 4326, project to 3857 for buffering to get meters, then standardise.
# But for the input file, let's keep them in 4326 as that's a common starting point.
# We'll just save the points and "polygons" (buffered points).

message("Saving to data.gpkg...")
st_write(points, "data.gpkg", layer = "points", delete_layer = TRUE, quiet = TRUE)
st_write(polys, "data.gpkg", layer = "polygons", delete_layer = TRUE, quiet = TRUE)
message("Done.")
