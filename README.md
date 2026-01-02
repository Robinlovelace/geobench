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

| system      | language | operation    | ops_per_sec |
|:------------|:---------|:-------------|------------:|
| sf          | R        | read_points  |        2.94 |
| sf          | R        | read_regions |      165.24 |
| sf          | R        | spatial_join |        1.13 |
| sf          | R        | buffer_pts   |        0.36 |
| geopandas   | Python   | read_points  |        4.86 |
| geopandas   | Python   | read_regions |      114.73 |
| geopandas   | Python   | buffer_pts   |        0.69 |
| geopandas   | Python   | spatial_join |       21.00 |
| sedonadb-py | Python   | load_points  |       27.75 |
| sedonadb-py | Python   | load_regions |      252.66 |
| sedonadb-py | Python   | buffer_pts   |        1.58 |
| sedonadb-py | Python   | spatial_join |        7.71 |
| sedonadb-r  | R        | read_points  |       33.34 |
| sedonadb-r  | R        | read_regions |       85.43 |
| sedonadb-r  | R        | buffer_pts   |       20.15 |
| sedonadb-r  | R        | spatial_join |       43.16 |

![](README_files/figure-commonmark/plot-results-1.png)
