import sedona.db

sd = sedona.db.connect()
try:
    print("Reading with read_pyogrio...")
    df = sd.read_pyogrio("nz_points.gpkg")
    print("Success! Row count:", df.count())
    df.to_view("points", overwrite=True)
    
    # Load regions too
    sd.read_pyogrio("nz_regions.gpkg").to_view("regions", overwrite=True)
    
    print("Testing intersection...")
    # Using 'geom' because read_pyogrio likely preserves file column name
    # Check column name
    print(df.columns)
    geom_col = "geom" # gpkg default
    
    query = f"""
        SELECT p.{geom_col}, r."Name"
        FROM points AS p
        LEFT JOIN regions AS r ON ST_Intersects(p.{geom_col}, r.{geom_col})
    """
    res = sd.sql(query).to_arrow_table() # Avoid to_pandas for now to check optimization only
    print("Intersection Rows:", res.num_rows)
    print("Success!")
except Exception as e:
    print(f"Failed: {e}")
