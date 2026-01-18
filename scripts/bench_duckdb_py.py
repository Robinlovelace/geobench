import duckdb
import time
import os

print("Starting Python (duckdb) Benchmarks [NZ]...")

# Connect and load spatial extension
con = duckdb.connect()
con.install_extension("spatial")
con.load_extension("spatial")

# --- 0. Data Preparation ---
# Ensure Parquet files exist (Generate from GPKG if needed)
if not os.path.exists("nz_points.parquet"):
    print("Generating nz_points.parquet from GPKG...")
    con.sql("COPY (SELECT * FROM ST_Read('nz_points.gpkg')) TO 'nz_points.parquet' (FORMAT PARQUET)")

if not os.path.exists("nz_regions.parquet"):
    print("Generating nz_regions.parquet from GPKG...")
    con.sql("COPY (SELECT * FROM ST_Read('nz_regions.gpkg')) TO 'nz_regions.parquet' (FORMAT PARQUET)")

def log_result(system, operation, time_sec):
    ops_per_sec = 1 / time_sec if time_sec > 0 else 0
    with open("results.csv", "a") as f:
        f.write(f"{system},Python,{operation},{ops_per_sec:.2f}\n")

def time_func(system, name, query):
    times = []
    for _ in range(5):
        start = time.time()
        # execute and fetch to ensure evaluation
        con.sql(query).fetchall()
        end = time.time()
        times.append(end - start)
    avg_time = sum(times) / len(times)
    print(f"{system} - {name}: {avg_time:.4f} s (avg of 5)")

    key_map = {
        "Read Points": "read_points",
        "Read Regions": "read_regions",
        "Spatial Join": "spatial_join",
        "Buffer Points": "buffer_pts"
    }
    if name in key_map:
        log_result(system, key_map[name], avg_time)

# --- 1. Read Benchmarks ---

# System: duckdb-gpkg
time_func("duckdb-gpkg", "Read Points", "SELECT * FROM ST_Read('nz_points.gpkg')")
time_func("duckdb-gpkg", "Read Regions", "SELECT * FROM ST_Read('nz_regions.gpkg')")

# System: duckdb-parquet
time_func("duckdb-parquet", "Read Points", "SELECT * FROM 'nz_points.parquet'")
time_func("duckdb-parquet", "Read Regions", "SELECT * FROM 'nz_regions.parquet'")

# --- 2. Spatial Join Benchmarks ---

# System: duckdb-gpkg
query_join_gpkg = """
SELECT p.geom, r.Name
FROM ST_Read('nz_points.gpkg') AS p
LEFT JOIN ST_Read('nz_regions.gpkg') AS r
ON ST_Intersects(p.geom, r.geom)
"""
time_func("duckdb-gpkg", "Spatial Join", query_join_gpkg)

# System: duckdb-parquet
# FIX: Removed ST_GeomFromWKB() because the columns are already GEOMETRY type.
query_join_parquet = """
SELECT p.geom, r.Name
FROM 'nz_points.parquet' AS p
LEFT JOIN 'nz_regions.parquet' AS r
ON ST_Intersects(p.geom, r.geom)
"""
time_func("duckdb-parquet", "Spatial Join", query_join_parquet)

# --- 3. Buffer Benchmarks ---

# System: duckdb-gpkg
time_func("duckdb-gpkg", "Buffer Points", "SELECT ST_Buffer(geom, 1000) FROM ST_Read('nz_points.gpkg')")

# System: duckdb-parquet
time_func("duckdb-parquet", "Buffer Points", "SELECT ST_Buffer(geom, 1000) FROM 'nz_points.parquet'")

print("DuckDB Python Benchmarks Complete.")
