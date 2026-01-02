# GeoBench: Spatial Data Benchmarks (NZ)


Benchmarks for spatial data operations using the `spData::nz` dataset
(New Zealand regions).

## Source Code

- [sf (R)](scripts/bench_r.R)
- [geopandas (Python)](scripts/bench_py.py)
- [sedonadb (Python)](scripts/bench_sedona_py.py)

## Experimental Setup

We use the New Zealand regions (16 polygons) and generate 100,000 random
points within the bounding box of New Zealand. The primary operation
benchmarked is a **Spatial Left Join**: joining the region `Name` to
each point.

``` r
library(sf)
library(spData)
library(ggplot2)

data(nz)
set.seed(42)
# Sample 100 points for visualization
bbox_poly <- st_as_sfc(st_bbox(nz))
points_sample <- st_sf(geometry = st_sample(bbox_poly, size = 100))

ggplot() +
  geom_sf(data = nz, fill = "lightblue", color = "white") +
  geom_sf(data = points_sample, color = "red", alpha = 0.5, size = 1) +
  scale_x_continuous(labels = function(x) paste0(x / 1000, " km")) +
  scale_y_continuous(labels = function(y) paste0(y / 1000, " km")) +
  coord_sf(datum = st_crs(nz)) +
  theme_minimal() +
  ggtitle("Experimental Setup (n=100)")
```

![](README_files/figure-commonmark/setup-1.png)

## Benchmark Results

Run on 100,000 points and 16 polygons (Regions).

| system          | language | operation    | ops_per_sec |
|:----------------|:---------|:-------------|------------:|
| sf              | R        | read_points  |        7.06 |
| sf              | R        | read_regions |      405.49 |
| sf              | R        | spatial_join |        3.00 |
| sf              | R        | buffer_pts   |        0.78 |
| geopandas       | Python   | read_points  |       15.02 |
| geopandas       | Python   | read_regions |      323.81 |
| geopandas       | Python   | buffer_pts   |        2.04 |
| geopandas       | Python   | spatial_join |       34.38 |
| sedonadb-pandas | Python   | read_points  |       28.75 |
| sedonadb-pandas | Python   | read_regions |      848.16 |
| sedonadb-pandas | Python   | buffer_pts   |        5.97 |
| sedonadb-pandas | Python   | spatial_join |       17.35 |
| sedonadb-polars | Python   | read_points  |       29.46 |
| sedonadb-polars | Python   | read_regions |      860.65 |
| sedonadb-polars | Python   | buffer_pts   |       11.35 |
| sedonadb-polars | Python   | spatial_join |       25.85 |
| sedonadb-sf     | R        | read_points  |      111.56 |
| sedonadb-sf     | R        | read_regions |      373.55 |
| sedonadb-sf     | R        | buffer_pts   |       67.99 |
| sedonadb-sf     | R        | spatial_join |      227.29 |

![](README_files/figure-commonmark/plot-results-1.png)
