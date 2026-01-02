#!/bin/bash
set -e

echo "Running Spatial Join Benchmarks..."

echo "Running R (sf) Spatial Join..."
Rscript scripts/bench_sjoin_r.R

echo "Running Python (geopandas) Spatial Join..."
python3 scripts/bench_sjoin_py.py

echo "Running Python (sedona.db) Spatial Join..."
python3 scripts/bench_sjoin_sedona_py.py
