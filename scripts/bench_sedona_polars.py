import sedona.db
import time
import polars as pl

print("Starting Python (sedona.db + Polars) Benchmarks [NZ]...")

sd = sedona.db.connect()

def log_result(operation, time_sec):
    ops_per_sec = 1 / time_sec if time_sec > 0 else 0
    with open("results.csv", "a") as f:
        f.write(f"sedonadb-polars,Python,{operation},{ops_per_sec:.2f}\n")

def time_func(name, func, *args, **kwargs):
    times = []
    for _ in range(5):
        start = time.time()
        res = func(*args, **kwargs)
        end = time.time()
        times.append(end - start)
    avg_time = sum(times) / len(times)
    print(f"{name}: {avg_time:.4f} s (avg of 5)")
    
    key_map = {
        "Load Points": "read_points",
        "Load Regions": "read_regions",
        "Spatial Join": "spatial_join",
        "Buffer Points": "buffer_pts"
    }
    if name in key_map:
        log_result(key_map[name], avg_time)
    return res

# 1. Read (Load from Disk)
def load_disk(filename, name):
    df = sd.read_pyogrio(filename)
    df.to_view(name, overwrite=True)
    return df

time_func("Load Points", load_disk, "nz_points.gpkg", "points")
time_func("Load Regions", load_disk, "nz_regions.gpkg", "regions")

# Ensure views are ready
load_disk("nz_points.gpkg", "points")
load_disk("nz_regions.gpkg", "regions")

# Spatial Join
geom_col = "geom"

def run_query_polars(query):
    arrow_table = sd.sql(query).to_arrow_table()
    return pl.from_arrow(arrow_table)

# Buffer
buffer_query = f"SELECT ST_Buffer({geom_col}, 1000) as {geom_col} FROM points"
try:
    time_func("Buffer Points", run_query_polars, buffer_query)
except Exception as e:
    print(f"Error buffering: {e}")

# Left Join Name
query = f"""
    SELECT p.{geom_col}, r."Name"
    FROM points AS p
    LEFT JOIN regions AS r ON ST_Intersects(p.{geom_col}, r.{geom_col})
"""

try:
    time_func("Spatial Join", run_query_polars, query)
except Exception as e:
    print(f"Error join: {e}")

print("Sedona Polars Benchmarks Complete.")
