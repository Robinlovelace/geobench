# GeoBench: Spatial Data Benchmarks (NZ)


Benchmarks for spatial data operations using the `spData::nz` dataset
(New Zealand regions).

## Source Code

- [sf (R)](scripts/bench_r.R)
- [geopandas (Python)](scripts/bench_py.py)
- [sedonadb (Python)](scripts/bench_sedona_py.py)
- [sedonadb (Python + Polars)](scripts/bench_sedona_polars.py)
- [sedonadb (R)](scripts/bench_sedona_r.R)
- [duckdb (R)](scripts/bench_duckdb_r.R)
- [duckdb (Python)](scripts/bench_duckdb_py.py)

## Experimental Setup

We use the New Zealand regions (16 polygons) and generate 100,000 random
points within the bounding box of New Zealand. The primary operation
benchmarked is a **Spatial Left Join**: joining the region `Name` to
each point.

**System Configurations:** \* **In-Memory (sf, geopandas, sedonadb,
duckdb-memory)**: Data is fully loaded into RAM before the timer starts.
For DuckDB, this includes converting to native `POINT_2D` types and
building an R-Tree index on the regions. \* **Streaming
(duckdb-parquet)**: Data is queried directly from Parquet files on disk
(Zero-Copy). The timer includes the cost of reading, parsing, and
joining.

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

- **sf / geopandas / sedona**: Standard benchmarks via GPKG.
- **duckdb-parquet**: Best-case I/O. Streams geometry directly from
  Parquet files without loading them.
- **duckdb-memory**: Best-case Compute. Pre-loads data into RAM,
  converts to native 2D types, and uses R-Tree indexes. Comparison point
  for `sf` / `geopandas`.

[Download full results (CSV)](results.csv)

![](README_files/figure-commonmark/plot-results-1.png)

## Running the Benchmarks

This repository includes a Docker submodule designed to handle the
dependencies for R (sf, duckdb, sedonadb) and Python (geopandas, sedona,
polars).

**1. Build the Docker Image:**

``` bash
cd docker_submodule
docker build -t geobench .
```

**2. Run the Benchmarks:**

``` bash
cd ..
docker run --rm -ti --net=host -v ${PWD}:/home/rstudio/project geobench /bin/bash -c "cd /home/rstudio/project && ./scripts/run_all.sh"
```

**3. Render/Update README.md:**

``` bash
docker run --rm -ti --net=host -v ${PWD}:/home/rstudio/project geobench /bin/bash -c "cd /home/rstudio/project && quarto render README.qmd"
```

### Performance Hypothesis

The results show `sedonadb-sf` (R) outperforming Python variants in
spatial operations, particularly joins. We hypothesize this is due to
efficient, low-overhead data transfer between R and the underlying
Sedona/DataFusion engine (likely via `nanoarrow` or C-level pointers),
whereas the standard Python path incurs significant cost deserializing
WKB into Python Shapely objects. The `sedonadb-polars` workaround
bridges this gap significantly by keeping data in Arrow/WKB format, but
R’s integration currently appears more seamless for these workloads.

The inclusion of DuckDB allows us to compare “native” execution against
standard approaches:

1.  **Zero-Copy (duckdb-parquet)**: Utilizes the spatial extension’s
    ability to read geometry data directly from Parquet. This isolates
    the I/O cost and demonstrates the engine’s ability to handle
    larger-than-memory datasets.
2.  **Optimized Compute (duckdb-memory)**: By loading data into native
    2D types (`POINT_2D`) and pre-building an **R-Tree Index**, DuckDB
    achieves high throughput comparable to specialized in-memory tools.
    This demonstrates that DuckDB’s performance is highly dependent on
    using its native internal types rather than generic WKB blobs.

### Next Steps

1.  **Memory Profiling**: Analyze memory usage to verify object overhead
    in Python vs R.
2.  **Scale Testing**: Run benchmarks on larger datasets (e.g., \>1
    million points) to assess scalability.
3.  **Python Optimization**: Develop native Polars/Arrow integration in
    `sedona-db` Python bindings to eliminate serialization bottlenecks.
4.  **Engine Comparison**: Deep dive into the performance differences
    between Sedona’s Rust-based engine and DuckDB’s vectorized execution
    engine for spatial joins.

**Note**: These benchmarks are intended for illustrative purposes and
may not be fully representative of complex, real-world use cases or
performance at larger scales. For more comprehensive benchmarks
comparing Sedona, DuckDB, and GeoPandas, we recommend checking out the
official [Sedona Spatial
Benchmarks](https://sedona.apache.org/spatialbench/single-node-benchmarks/).
