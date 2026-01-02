import sedona.db
import geopandas as gpd
import time
import os

print("Starting Python (sedona.db) Benchmarks...")

# Connect to SedonaDB
sd = sedona.db.connect()

# Setup: Read data with geopandas
pts_gdf = gpd.read_file("data.gpkg", layer="points", engine="pyogrio")
polys_gdf = gpd.read_file("data.gpkg", layer="polygons", engine="pyogrio")

def log_result(operation, time_sec):
    with open("results.csv", "a") as f:
        f.write(f"sedonadb,Python,{operation},{time_sec:.6f}\n")

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
        "Load Points": "load_points",
        "Load Polys": "load_polys",
        "Transform Points": "transform_pts",
        "Buffer Points": "buffer_pts",
        "Intersection": "intersection"
    }
    if name in key_map:
        log_result(key_map[name], avg_time)
        
    return res

# 1. Load to SedonaDB
def load_view(gdf, name):
    df = sd.create_data_frame(gdf)
    df.to_view(name, overwrite=True)
    return df

time_func("Load Points", load_view, pts_gdf, "points")
time_func("Load Polys", load_view, polys_gdf, "polygons")

# Ensure views are there (redundant but safe)
load_view(pts_gdf, "points")
load_view(polys_gdf, "polygons")

# 2. Transform
# Note: We use .show() or .to_pandas() or .collect() to force execution.
# .collect() usually returns a list of Rows. .to_pandas() returns a DF.
# Let's use to_pandas() as it mimics sd_collect() in R.
def run_query(query):
    return sd.sql(query).to_pandas()

transform_query = "SELECT ST_Transform(geometry, 'EPSG:27700') as geometry FROM points"
time_func("Transform Points", run_query, transform_query)

# Create transformed views
sd.sql(transform_query).to_view("points_proj")
sd.sql("SELECT ST_Transform(geometry, 'EPSG:27700') as geometry FROM polygons").to_view("polys_proj")

# 3. Buffer
buffer_query = "SELECT ST_Buffer(geometry, 100) as geometry FROM points_proj"
time_func("Buffer Points", run_query, buffer_query)

# 4. Intersection
intersect_query = """
    SELECT p.geometry 
    FROM points_proj AS p, polys_proj AS poly 
    WHERE ST_Intersects(p.geometry, poly.geometry)
"""
try:
    time_func("Intersection", run_query, intersect_query)
except Exception as e:
    print(f"Skipping Intersection benchmark due to error: {e}")

print("Python (sedona.db) Benchmarks Complete.")
