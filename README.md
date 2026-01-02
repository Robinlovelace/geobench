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
  theme_minimal() +
  ggtitle("Experimental Setup (n=100)")
```

![](README_files/figure-commonmark/setup-1.png)

## Benchmark Results

Run on 100,000 points and 16 polygons (Regions).

| system          | language | operation    | ops_per_sec |
|:----------------|:---------|:-------------|------------:|
| sf              | R        | read_points  |        2.02 |
| sf              | R        | read_regions |      149.46 |
| sf              | R        | spatial_join |        0.85 |
| sf              | R        | buffer_pts   |        0.33 |
| geopandas       | Python   | read_points  |        5.05 |
| geopandas       | Python   | read_regions |      112.25 |
| geopandas       | Python   | buffer_pts   |        0.74 |
| geopandas       | Python   | spatial_join |       22.57 |
| sedonadb-py     | Python   | read_points  |       27.68 |
| sedonadb-py     | Python   | read_regions |      255.03 |
| sedonadb-py     | Python   | buffer_pts   |        1.70 |
| sedonadb-py     | Python   | spatial_join |        3.06 |
| sedonadb-polars | Python   | read_points  |       17.59 |
| sedonadb-polars | Python   | read_regions |      276.00 |
| sedonadb-polars | Python   | buffer_pts   |        2.74 |
| sedonadb-polars | Python   | spatial_join |       25.40 |
| sedonadb-r      | R        | read_points  |       32.93 |
| sedonadb-r      | R        | read_regions |      153.30 |
| sedonadb-r      | R        | buffer_pts   |       19.76 |
| sedonadb-r      | R        | spatial_join |       48.47 |

![](README_files/figure-commonmark/plot-results-1.png)
