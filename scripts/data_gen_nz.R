library(sf)
library(spData)
library(dplyr)

set.seed(42)

data(nz)
# Ensure valid
nz <- st_make_valid(nz)

n_points <- 100000

message("Generating ", n_points, " random points in NZ bbox...")
# Generate points within the bounding box of NZ
# st_sample on a bbox polygon returns points in that box
bbox_poly <- st_as_sfc(st_bbox(nz))
points_sfc <- st_sample(bbox_poly, size = n_points)
points <- st_sf(geometry = points_sfc)

message("Saving to nz.gpkg...")
st_write(nz, "nz.gpkg", layer = "regions", delete_layer = TRUE, quiet = TRUE)
st_write(points, "nz.gpkg", layer = "points", delete_layer = TRUE, quiet = TRUE)
message("Done.")
