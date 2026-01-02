import geopandas as gpd
import time
import pandas as pd

print("Starting Python (geopandas) Spatial Join Benchmarks...")

# Read projected data
pts = gpd.read_file("data_projected.gpkg", layer="points", engine="pyogrio")
polys = gpd.read_file("data_projected.gpkg", layer="polygons", engine="pyogrio")

def log_result(operation, time_sec):
    with open("results.csv", "a") as f:
        f.write(f"geopandas,Python,{operation},{time_sec:.6f}\n")

def time_func(name, func, *args, **kwargs):
    times = []
    for _ in range(5):
        start = time.time()
        res = func(*args, **kwargs)
        end = time.time()
        times.append(end - start)
    avg_time = sum(times) / len(times)
    print(f"{name}: {avg_time:.4f} s (avg of 5)")
    log_result("spatial_join", avg_time)
    return res

# Spatial Join
# gpd.sjoin defaults to inner, but st_join defaults to left.
# User asked for equivalent of st_join, so use how="left".
# Also select only 'id' (+geometry) from polys
polys_subset = polys[["id", "geometry"]]

def run_sjoin(left, right):
    return gpd.sjoin(left, right, how="left", predicate="intersects")

time_func("Spatial Join", run_sjoin, pts, polys_subset)

print("Python Spatial Join Benchmarks Complete.")
