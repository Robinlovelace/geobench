import sedona.db
import geopandas as gpd
import time
import os

print("Starting Python (sedona.db) Benchmarks [Projected Input]...")

# Connect to SedonaDB
sd = sedona.db.connect()

# Setup: Read data with geopandas
# We use the projected file now
pts_gdf = gpd.read_file("data_projected.gpkg", layer="points", engine="pyogrio")
polys_gdf = gpd.read_file("data_projected.gpkg", layer="polygons", engine="pyogrio")

def log_result(operation, time_sec):
    # Log with a distinct tag "sedonadb_proj" to differentiate
    with open("results.csv", "a") as f:
        f.write(f"sedonadb_proj,Python,{operation},{time_sec:.6f}\n")

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

time_func("Load Points", load_view, pts_gdf, "points_proj")
time_func("Load Polys", load_view, polys_gdf, "polys_proj")

# Ensure views are ready
load_view(pts_gdf, "points_proj")
load_view(polys_gdf, "polys_proj")

# NO TRANSFORM STEP
# Data is already in 27700.

# 3. Buffer
# Note: "points_proj" is now the table name directly
def run_query(query):
    return sd.sql(query).to_pandas()

buffer_query = "SELECT ST_Buffer(geom, 100) as geom FROM points_proj"
# The column name from GPKG usually ends up as 'geom' or 'geometry'. 
# Let's check the column name in the loaded dataframe or just try 'geom' vs 'geometry'.
# Geopandas usually uses 'geometry'. SedonaDB via create_data_frame likely preserves it.
# Let's verify quickly by peeking or we can try catch.
# In the original bench we used `ST_Transform(geometry, ...)` but source was gpkg layer.
# Let's assume 'geometry' if read from geopandas. 
# BUT `pts_gdf` from file might have 'geom' if the file has 'geom'. 
# `data_projected.gpkg` created by sf usually has 'geom'.
# Let's check the gdf columns.
print(f"Columns in pts_gdf: {pts_gdf.columns}")
# If it is 'geom', use 'geom'.
geom_col = pts_gdf.geometry.name
print(f"Geometry column name: {geom_col}")

buffer_query = f"SELECT ST_Buffer({geom_col}, 100) as {geom_col} FROM points_proj"
time_func("Buffer Points", run_query, buffer_query)

# 4. Intersection
intersect_query = f"""
    SELECT p.{geom_col} 
    FROM points_proj AS p, polys_proj AS poly 
    WHERE ST_Intersects(p.{geom_col}, poly.{geom_col})
"""
try:
    time_func("Intersection", run_query, intersect_query)
except Exception as e:
    print(f"Skipping Intersection benchmark due to error: {e}")

print("Python (sedona.db) Benchmarks [Projected] Complete.")
