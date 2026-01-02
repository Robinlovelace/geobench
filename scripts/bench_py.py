import geopandas as gpd
import time
import pandas as pd

print("Starting Python (geopandas) Benchmarks...")

def time_func(name, func, *args, **kwargs):
    times = []
    for _ in range(5):
        start = time.time()
        res = func(*args, **kwargs)
        end = time.time()
        times.append(end - start)
    avg_time = sum(times) / len(times)
    print(f"{name}: {avg_time:.4f} s (avg of 5)")
    return res

# 1. Read
def read_layer(layer):
    # use pyogrio engine for fairness (faster than fiona default) if available
    # but let's stick to default or explicitly use pyogrio if we installed it.
    # We installed pyogrio in Dockerfile.
    return gpd.read_file("data.gpkg", layer=layer, engine="pyogrio")

pts = time_func("Read Points", read_layer, "points")
polys = time_func("Read Polys", read_layer, "polygons")

# 2. Transform
# To EPSG:27700
def transform_layer(gdf, crs):
    return gdf.to_crs(crs)

pts_proj = time_func("Transform Points", transform_layer, pts, "EPSG:27700")
polys_proj = time_func("Transform Polys", transform_layer, polys, "EPSG:27700")

# 3. Buffer
# Buffer by 100m
def buffer_layer(gdf, dist):
    return gdf.buffer(dist)

pts_buf = time_func("Buffer Points", buffer_layer, pts_proj, 100)

# 4. Intersection
# Points in Polygons (Spatial Join is usually the optimized way in geopandas vs intersection which is element-wise or overlay)
# st_intersection in sf does an overlay. `gpd.overlay` is the equivalent.
# sjoin is faster if we just want "which points are in which polys".
# st_intersection computes the geometric intersection (clipping).
# To be strictly comparable to sf::st_intersection, we should use overlay(how='intersection').
def intersection_layer(gdf1, gdf2):
    return gpd.overlay(gdf1, gdf2, how='intersection')

result = time_func("Intersection (Overlay)", intersection_layer, pts_proj, polys_proj)

print("Python Benchmarks Complete.")
