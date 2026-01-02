FROM ghcr.io/geocompx/pythonr:latest

# Install Rust for sedonadb R package compilation
RUN apt-get update && apt-get install -y --no-install-recommends \
    cargo \
    rustc \
    && rm -rf /var/lib/apt/lists/*

# Install Python sedona-db
# Note: "apache-sedona[db]" installs the python package with db extras
RUN pip install "apache-sedona[db]"

# Install R sedonadb
# using pak which is available in the base image
RUN Rscript -e "pak::pak('apache/sedona-db/r/sedonadb')"

# Install microbenchmark for R benchmarking
RUN Rscript -e "pak::pak('microbenchmark')"

# Install terra and spData if not present (likely in geocompkg but to be safe)
RUN Rscript -e "pak::pak(c('terra', 'spData'))"