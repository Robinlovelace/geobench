import sedona.db
import geopandas as gpd
import pandas as pd
import numpy as np
from shapely.geometry import Point

print("Generating synthetic data (100k points, 100 polys)...")

# 1. Generate Data (Mimic benchmark)
n_points = 100000
n_polys = 100

# Points
lons = np.random.uniform(-6, 2, n_points)
lats = np.random.uniform(50, 59, n_points)
pts_df = pd.DataFrame({'geometry': [Point(x, y) for x, y in zip(lons, lats)]})
pts_gdf = gpd.GeoDataFrame(pts_df, crs="EPSG:4326")

# Polygons
# Centers
plons = np.random.uniform(-6, 2, n_polys)
plats = np.random.uniform(50, 59, n_polys)
poly_centers = gpd.GeoDataFrame(
    {'geometry': [Point(x, y) for x, y in zip(plons, plats)]}, 
    crs="EPSG:4326"
)
# Buffer to make polygons (approx 10km ~ 0.1 deg for simplicity in 4326 to avoid projecting back and forth for reprex)
# Benchmark projected to 3857 for buffer then back. 
# Let's just buffer in 4326 with 0.1 degrees to keep it simple but "polygon-y".
polys_gdf = poly_centers.buffer(0.1).to_frame(name='geometry') # already gdf

# Connect
sd = sedona.db.connect()

# 2. Load
print("Loading views...")
sd.create_data_frame(pts_gdf).to_view("points", overwrite=True)
sd.create_data_frame(polys_gdf).to_view("polygons", overwrite=True)

# 3. Transform
print("Transforming...")
sd.sql("SELECT ST_Transform(geometry, 'EPSG:27700') as geometry FROM points").to_view("points_proj", overwrite=True)
sd.sql("SELECT ST_Transform(geometry, 'EPSG:27700') as geometry FROM polygons").to_view("polys_proj", overwrite=True)

# 4. Intersection
query = """
    SELECT p.geometry 
    FROM points_proj AS p, polys_proj AS poly 
    WHERE ST_Intersects(p.geometry, poly.geometry)
"""

print("Running intersection query...")
try:
    res = sd.sql(query).to_pandas()
    print("Success!")
    print(len(res))
except Exception as e:
    print("\nCaught expected error:")
    print(e)
