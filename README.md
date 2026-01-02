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
| sf              | R        | read_points  |        7.91 |
| sf              | R        | read_regions |      390.86 |
| sf              | R        | spatial_join |        2.97 |
| sf              | R        | buffer_pts   |        0.77 |
| geopandas       | Python   | read_points  |       14.80 |
| geopandas       | Python   | read_regions |      326.74 |
| geopandas       | Python   | buffer_pts   |        2.05 |
| geopandas       | Python   | spatial_join |       33.70 |
| sedonadb-pandas | Python   | read_points  |       26.98 |
| sedonadb-pandas | Python   | read_regions |      853.40 |
| sedonadb-pandas | Python   | buffer_pts   |        6.06 |
| sedonadb-pandas | Python   | spatial_join |       16.33 |
| sedonadb-polars | Python   | read_points  |       28.14 |
| sedonadb-polars | Python   | read_regions |      855.39 |
| sedonadb-polars | Python   | buffer_pts   |       11.52 |
| sedonadb-polars | Python   | spatial_join |       22.53 |
| sedonadb-sf     | R        | read_points  |        6.56 |
| sedonadb-sf     | R        | read_regions |      224.16 |
| sedonadb-sf     | R        | buffer_pts   |       69.84 |
| sedonadb-sf     | R        | spatial_join |      248.10 |

![](README_files/figure-commonmark/plot-results-1.png)
