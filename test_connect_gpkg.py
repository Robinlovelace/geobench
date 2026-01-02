import sedona.db

try:
    print("Attempting connect('nz_points.gpkg')...")
    sd = sedona.db.connect("nz_points.gpkg")
    print("Success!")
except TypeError as e:
    print(f"Failed (TypeError): {e}")
except Exception as e:
    print(f"Failed: {e}")
