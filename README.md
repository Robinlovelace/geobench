# GeoBench: Spatial Data Benchmarks

Benchmarks for spatial data operations across different systems and languages.

## Systems Benchmarked
- **sf** (R)
- **geopandas** (Python)
- **sedonadb** (R and Python bindings for Apache Sedona / sedona-db)

## Benchmark Results

Run on 100,000 points and 100 polygons.

| System | Language | Operation | Time (s) |
|---|---|---|---|
| sf | R | read_points | 0.322 |
| sf | R | read_polys | 0.008 |
| sf | R | transform_pts | 0.374 |
| sf | R | buffer_pts | 3.506 |
| sf | R | intersection | 0.408 |
| geopandas | Python | read_points | 0.313 |
| geopandas | Python | read_polys | 0.011 |
| geopandas | Python | transform_pts | 0.243 |
| geopandas | Python | transform_polys | 0.042 |
| geopandas | Python | buffer_pts | 1.733 |
| geopandas | Python | intersection | 0.328 |
| sedonadb | R | load_points | 0.023 |
| sedonadb | R | load_polys | 0.004 |
| sedonadb | Python | load_points | 0.035 |
| sedonadb | Python | load_polys | 0.006 |
| sedonadb | Python | transform_pts | 0.205 |
| sedonadb | Python | buffer_pts | 0.658 |
| sedonadb (proj) | Python | load_points | 0.034 |
| sedonadb (proj) | Python | load_polys | 0.002 |
| sedonadb (proj) | Python | buffer_pts | 0.624 |
| sedonadb (clean) | Python | load_points | 0.036 |
| sedonadb (clean) | Python | load_polys | 0.005 |
| sedonadb (clean) | Python | buffer_pts | 0.625 |
| sedonadb (clean) | Python | intersection | 0.037 |
| sf | R | spatial_join | 0.467 |
| geopandas | Python | spatial_join | 0.016 |
| sedonadb (clean) | Python | spatial_join | 0.052 |

**Notes:**
- **SedonaDB R**: `transform_pts` and subsequent operations failed due to missing PROJ feature in the installed package.
- **SedonaDB Python**: `intersection` failed due to an internal schema mismatch error in DataFusion/SedonaDB.
- **SedonaDB Python (Projected)**: Even with pre-projected data (avoiding `ST_Transform`), the `intersection` query fails with the same schema mismatch error.
- **SedonaDB Python (Clean)**: Stripping the **Pandas metadata** (index info) from the Arrow table before loading resolves the schema mismatch issue.
- **Performance**:
    - **Buffering**: SedonaDB (0.66s) is faster than Geopandas (1.73s) and sf (3.51s).
    - **Intersection (Clipping)**: SedonaDB (0.037s) is ~10x faster than Geopandas (0.328s) and sf (0.408s).
    - **Spatial Join (Point-in-Poly)**: Geopandas (0.016s) is fastest, followed by SedonaDB (0.052s) and sf (0.467s).
