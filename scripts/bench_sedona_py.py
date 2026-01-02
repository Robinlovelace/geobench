import sedona.db
import geopandas as gpd
import time
import pyarrow as pa

print("Starting Python (sedona.db) Benchmarks [NZ]...")

sd = sedona.db.connect()

pts_gdf = gpd.read_file("nz.gpkg", layer="points", engine="pyogrio")
regions_gdf = gpd.read_file("nz.gpkg", layer="regions", engine="pyogrio")

def log_result(operation, time_sec):
    ops_per_sec = 1 / time_sec if time_sec > 0 else 0
    with open("results.csv", "a") as f:
        f.write(f"sedonadb,Python,{operation},{ops_per_sec:.2f}\n")

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
        "Load Regions": "load_regions",
        "Spatial Join": "spatial_join",
        "Buffer Points": "buffer_pts"
    }
    if name in key_map:
        log_result(key_map[name], avg_time)
    return res

def clean_load_view(gdf, name):
    temp_df = sd.create_data_frame(gdf)
    table = temp_df.to_arrow_table()
    clean_table = table.replace_schema_metadata(None)
    final_df = sd.create_data_frame(clean_table)
    final_df.to_view(name, overwrite=True)
    return final_df

time_func("Load Points", clean_load_view, pts_gdf, "points")
time_func("Load Regions", clean_load_view, regions_gdf, "regions")

# Ensure views
clean_load_view(pts_gdf, "points")
clean_load_view(regions_gdf, "regions")

# Spatial Join
geom_col = "geom" 
if "geometry" in pts_gdf.columns: geom_col = "geometry"

def run_query(query):
    return sd.sql(query).to_pandas()

# Buffer
buffer_query = f"SELECT ST_Buffer({geom_col}, 1000) as {geom_col} FROM points"
try:
    time_func("Buffer Points", run_query, buffer_query)
except Exception as e:
    print(f"Error buffering: {e}")

# Left Join Name
query = f"""
    SELECT p.{geom_col}, r."Name"
    FROM points AS p
    LEFT JOIN regions AS r ON ST_Intersects(p.{geom_col}, r.{geom_col})
"""

def run_query(query):
    return sd.sql(query).to_pandas()

try:
    time_func("Spatial Join", run_query, query)
except Exception as e:
    print(f"Error: {e}")

print("Sedona Benchmarks Complete.")