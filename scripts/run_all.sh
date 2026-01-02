#!/bin/bash
set -e

echo "Initializing results.csv..."
echo "system,language,operation,time_sec" > results.csv

echo "Generating Data..."
Rscript scripts/data_gen.R

echo "Running R (sf) Benchmarks..."
Rscript scripts/bench_r.R

echo "Running Python (geopandas) Benchmarks..."
python3 scripts/bench_py.py

echo "Running R (sedonadb) Benchmarks..."
Rscript scripts/bench_sedona_r.R

echo "Running Python (sedona.db) Benchmarks..."
python3 scripts/bench_sedona_py.py
