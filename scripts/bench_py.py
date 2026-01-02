import geopandas as gpd
import time
import pandas as pd

print("Starting Python (geopandas) Benchmarks [NZ]...")

def log_result(operation, time_sec):
    ops_per_sec = 1 / time_sec if time_sec > 0 else 0
    with open("results.csv", "a") as f:
        f.write(f"geopandas,Python,{operation},{ops_per_sec:.2f}\n")

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
        "Read Points": "read_points",
        "Read Regions": "read_regions",
        "Spatial Join": "spatial_join",
        "Buffer Points": "buffer_pts"
    }
    if name in key_map:
        log_result(key_map[name], avg_time)
    return res

# 1. Read
def read_layer(layer):
    return gpd.read_file("nz.gpkg", layer=layer, engine="pyogrio")

pts = time_func("Read Points", read_layer, "points")
regions = time_func("Read Regions", read_layer, "regions")

# 2. Buffer
# Buffer by 1000m
def buffer_layer(gdf, dist):
    return gdf.buffer(dist)

time_func("Buffer Points", buffer_layer, pts, 1000)

# 3. Spatial Join
# Join 'Name'
# geopandas uses 'geom' or 'geometry', usually 'geometry' in memory.
# Select Name and geometry
regions_subset = regions[["Name", regions.geometry.name]] 

def run_sjoin(left, right):
    return gpd.sjoin(left, right, how="left", predicate="intersects")

time_func("Spatial Join", run_sjoin, pts, regions_subset)

print("Python Benchmarks Complete.")