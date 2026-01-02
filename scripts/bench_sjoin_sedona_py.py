import sedona.db
import geopandas as gpd
import time
import os

print("Starting Python (sedona.db) Spatial Join Benchmarks...")

sd = sedona.db.connect()

# Read projected data
pts_gdf = gpd.read_file("data_projected.gpkg", layer="points", engine="pyogrio")
polys_gdf = gpd.read_file("data_projected.gpkg", layer="polygons", engine="pyogrio")

def clean_load_view(gdf, name):
    temp_df = sd.create_data_frame(gdf)
    table = temp_df.to_arrow_table()
    clean_table = table.replace_schema_metadata(None)
    final_df = sd.create_data_frame(clean_table)
    final_df.to_view(name, overwrite=True)
    return final_df

clean_load_view(pts_gdf, "points")
clean_load_view(polys_gdf, "polygons")

def log_result(operation, time_sec):
    with open("results.csv", "a") as f:
        f.write(f"sedonadb_clean,Python,{operation},{time_sec:.6f}\n")

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

def run_query(query):
    return sd.sql(query).to_pandas()

# Left Join
# Note: In SQL, a Spatial Left Join is standard.
# Select p.* and poly.id
query = """
    SELECT p.geometry, poly.id
    FROM points AS p
    LEFT JOIN polygons AS poly ON ST_Intersects(p.geometry, poly.geometry)
"""

try:
    time_func("Spatial Join", run_query, query)
except Exception as e:
    print(f"Skipping Spatial Join benchmark due to error: {e}")

print("Python (sedona.db) Spatial Join Benchmarks Complete.")
