import sedona.db
import geopandas as gpd
import pyarrow as pa
import time

print("Starting Python (sedona.db) Benchmarks [Clean Metadata]...")

sd = sedona.db.connect()

# Read projected data
pts_gdf = gpd.read_file("data_projected.gpkg", layer="points", engine="pyogrio")
polys_gdf = gpd.read_file("data_projected.gpkg", layer="polygons", engine="pyogrio")

def clean_load_view(gdf, name):
    # 1. Create Sedona DF (handles geometry conversion)
    temp_df = sd.create_data_frame(gdf)
    # 2. Convert to Arrow Table
    table = temp_df.to_arrow_table()
    # 3. Strip Table-level Metadata (removes Pandas index info)
    clean_table = table.replace_schema_metadata(None)
    # 4. Create new Sedona DF from clean table
    final_df = sd.create_data_frame(clean_table)
    final_df.to_view(name, overwrite=True)
    return final_df

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
    
    key_map = {
        "Load Points": "load_points",
        "Load Polys": "load_polys",
        "Buffer Points": "buffer_pts",
        "Intersection": "intersection"
    }
    if name in key_map:
        log_result(key_map[name], avg_time)
    return res

# 1. Load
time_func("Load Points", clean_load_view, pts_gdf, "points_clean")
time_func("Load Polys", clean_load_view, polys_gdf, "polys_clean")

# Ensure views ready
clean_load_view(pts_gdf, "points_clean")
clean_load_view(polys_gdf, "polys_clean")

def run_query(query):
    return sd.sql(query).to_pandas()

# Check column name (should be preserved from GDF -> Sedona -> Arrow -> Sedona)
# Usually 'geometry'
geom_col = "geometry" 

# 3. Buffer
buffer_query = f"SELECT ST_Buffer({geom_col}, 100) as {geom_col} FROM points_clean"
time_func("Buffer Points", run_query, buffer_query)

# 4. Intersection
intersect_query = f"""
    SELECT p.{geom_col} 
    FROM points_clean AS p, polys_clean AS poly 
    WHERE ST_Intersects(p.{geom_col}, poly.{geom_col})
"""
try:
    time_func("Intersection", run_query, intersect_query)
except Exception as e:
    print(f"Skipping Intersection benchmark due to error: {e}")

print("Python (sedona.db) Benchmarks [Clean] Complete.")
