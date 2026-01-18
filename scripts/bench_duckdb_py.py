import duckdb
import time
import os

print("Starting Python (duckdb) Benchmarks [NZ]...")

con = duckdb.connect()
con.install_extension("spatial")
con.load_extension("spatial")

# --- Data Prep ---
if not os.path.exists("nz_points.parquet"):
    con.sql("COPY (SELECT * FROM ST_Read('nz_points.gpkg')) TO 'nz_points.parquet' (FORMAT PARQUET)")
if not os.path.exists("nz_regions.parquet"):
    con.sql("COPY (SELECT * FROM ST_Read('nz_regions.gpkg')) TO 'nz_regions.parquet' (FORMAT PARQUET)")

def log_result(system, operation, time_sec):
    ops_per_sec = 1 / time_sec if time_sec > 0 else 0
    with open("results.csv", "a") as f:
        f.write(f"{system},Python,{operation},{ops_per_sec:.2f}\n")

def time_func(system, name, query):
    times = []
    for _ in range(5):
        start = time.time()
        con.sql(query).fetchall()
        end = time.time()
        times.append(end - start)
    avg_time = sum(times) / len(times)
    print(f"{system} - {name}: {avg_time:.4f} s")

    key_map = {
        "Read Points": "read_points",
        "Read Regions": "read_regions",
        "Spatial Join": "spatial_join",
        "Buffer Points": "buffer_pts"
    }
    if name in key_map:
        log_result(system, key_map[name], avg_time)

# ==============================================================================
# SYSTEM 1: duckdb-parquet (Disk-Based / Zero-Copy)
# ==============================================================================

# 1. READ
time_func("duckdb-parquet", "Read Points", "SELECT * FROM 'nz_points.parquet'")
time_func("duckdb-parquet", "Read Regions", "SELECT * FROM 'nz_regions.parquet'")

# 2. SPATIAL JOIN
query_join_pq = """
SELECT p.geom, r.Name
FROM 'nz_points.parquet' AS p
LEFT JOIN 'nz_regions.parquet' AS r
ON ST_Intersects(p.geom, r.geom)
"""
time_func("duckdb-parquet", "Spatial Join", query_join_pq)

# 3. BUFFER
time_func("duckdb-parquet", "Buffer Points", "SELECT ST_Buffer(geom, 1000) FROM 'nz_points.parquet'")


# ==============================================================================
# SYSTEM 2: duckdb-memory (In-Memory / Optimized)
# ==============================================================================
print("Preparing In-Memory Data (Optimized)...")
# Load tables
con.sql("CREATE OR REPLACE TABLE regions AS SELECT * FROM 'nz_regions.parquet'")
con.sql("CREATE OR REPLACE TABLE points AS SELECT * FROM 'nz_points.parquet'")
# Optimizations for Join
con.sql("CREATE INDEX idx_regions_geom ON regions USING RTREE (geom)")
con.sql("CREATE OR REPLACE TABLE points_2d AS SELECT ST_Point2D(ST_X(geom), ST_Y(geom)) AS geom FROM points")

# 1. READ (Select from Memory)
time_func("duckdb-memory", "Read Points", "SELECT * FROM points")
time_func("duckdb-memory", "Read Regions", "SELECT * FROM regions")

# 2. SPATIAL JOIN (Optimized)
query_join_mem = """
SELECT p.geom, r.Name
FROM points_2d AS p
LEFT JOIN regions AS r
ON ST_Intersects(p.geom, r.geom)
"""
time_func("duckdb-memory", "Spatial Join", query_join_mem)

# 3. BUFFER (Standard)
time_func("duckdb-memory", "Buffer Points", "SELECT ST_Buffer(geom, 1000) FROM points")

print("DuckDB Python Benchmarks Complete.")
