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

[Download full results (CSV)](results.csv)

![](README_files/figure-commonmark/plot-results-1.png)

### Performance Hypothesis

The results show `sedonadb-sf` (R) outperforming Python variants in
spatial operations, particularly joins. We hypothesize this is due to
efficient, low-overhead data transfer between R and the underlying
Sedona/DataFusion engine (likely via `nanoarrow` or C-level pointers),
whereas the standard Python path incurs significant cost deserializing
WKB into Python Shapely objects. The `sedonadb-polars` workaround
bridges this gap significantly by keeping data in Arrow/WKB format, but
R’s integration currently appears more seamless for these workloads.

### Next Steps

1.  **Memory Profiling**: Analyze memory usage to verify object overhead
    in Python vs R.
2.  **Scale Testing**: Run benchmarks on larger datasets (e.g., \>1
    million points) to assess scalability.
3.  **Python Optimization**: Develop native Polars/Arrow integration in
    `sedona-db` Python bindings to eliminate serialization bottlenecks.

**Note**: These benchmarks are intended for illustrative purposes and
may not be fully representative of complex, real-world use cases or
performance at larger scales. For more comprehensive benchmarks
comparing Sedona, DuckDB, and GeoPandas, we recommend checking out the
official [Sedona Spatial
Benchmarks](https://sedona.apache.org/spatialbench/single-node-benchmarks/).
