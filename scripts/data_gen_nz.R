library(sf)
library(spData)
library(dplyr)

set.seed(42)

message("Loading spData::nz...")
data(nz)
# Ensure valid
nz <- st_make_valid(nz)

# Verify CRS
crs_code <- st_crs(nz)$epsg
message("NZ CRS: EPSG:", crs_code)
if (is.na(crs_code) || crs_code != 2193) {
  stop("Expected EPSG:2193 for NZ data, got ", crs_code)
}

n_points <- 100000

message("Generating ", n_points, " random points in NZ bbox...")
# Generate points within the bounding box of NZ
bbox_poly <- st_as_sfc(st_bbox(nz))
points_sfc <- st_sample(bbox_poly, size = n_points)
points <- st_sf(geometry = points_sfc)

# Verify Points CRS
pts_crs <- st_crs(points)$epsg
message("Points CRS: EPSG:", pts_crs)
if (is.na(pts_crs) || pts_crs != 2193) {
  message("Transforming points to EPSG:2193...")
  points <- st_transform(points, 2193)
}

# Check coordinate values (first point)
coords <- st_coordinates(points[1,])
message("Sample Point Coordinates: ", paste(coords, collapse = ", "))

message("Saving to separate GPKG files...")
st_write(nz, "nz_regions.gpkg", delete_layer = TRUE, quiet = TRUE)
st_write(points, "nz_points.gpkg", delete_layer = TRUE, quiet = TRUE)
message("Done.")