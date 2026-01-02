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
| sf          | R        | read_points  |        2.89 |
| sf          | R        | read_regions |      183.16 |
| sf          | R        | spatial_join |        1.12 |
| sf          | R        | buffer_pts   |        0.35 |
| geopandas   | Python   | read_points  |        4.97 |
| geopandas   | Python   | read_regions |      112.48 |
| geopandas   | Python   | buffer_pts   |        0.63 |
| geopandas   | Python   | spatial_join |       15.65 |
| sedonadb-py | Python   | read_points  |       19.82 |
| sedonadb-py | Python   | read_regions |      264.77 |
| sedonadb-py | Python   | buffer_pts   |        1.52 |
| sedonadb-py | Python   | spatial_join |        3.71 |
| sedonadb-r  | R        | read_points  |       29.61 |
| sedonadb-r  | R        | read_regions |      142.42 |
| sedonadb-r  | R        | buffer_pts   |       20.67 |
| sedonadb-r  | R        | spatial_join |       47.52 |

![](README_files/figure-commonmark/plot-results-1.png)
