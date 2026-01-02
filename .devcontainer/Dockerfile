FROM ghcr.io/geocompx/pythonr:latest

# Install system dependencies
# curl is likely already there but good to ensure
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    build-essential \
    libclang-dev \
    && rm -rf /var/lib/apt/lists/*

# Install Rust using rustup to get the latest version (needed for sedonadb)
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
ENV PATH="/root/.cargo/bin:${PATH}"

# Install Python sedona-db
RUN pip install "apache-sedona[db]"

# Install R sedonadb
# using pak which is available in the base image
RUN Rscript -e "pak::pak('apache/sedona-db/r/sedonadb')"

# Install microbenchmark for R benchmarking
RUN Rscript -e "pak::pak('microbenchmark')"

# Install terra and spData if not present
RUN Rscript -e "pak::pak(c('terra', 'spData'))"
