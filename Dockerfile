FROM python:3.12-slim

WORKDIR /app

# Install Python dependencies first for better layer caching.
COPY requirements.txt ./
RUN pip install --no-cache-dir -r requirements.txt

# App source.
COPY . .

# Bake the DuckDB warehouse into the image at build time. Railway's release
# phase runs in a throwaway container, so the build must happen here (fetches
# the SNHD bundle + ArcGIS layers, then materializes the dbt marts). The DB
# stays out of git and is rebuilt fresh on every deploy.
#
# NVROADS_API_KEY is a Railway service variable; it reaches the runtime by
# default but NOT a Dockerfile RUN step, so declare it as a build arg and pass
# it inline (kept out of the final image's ENV). Without it, build_warehouse
# skips the Nevada 511 roadwork source and only the keyless CLV CIP layer ships.
# `--exclude-resource-type seed` keeps the CI fixture CSVs in seeds/ from ever
# running here — they exist only to let CI build the marts offline, and must not
# overwrite the full-size raw.* tables that build_warehouse.py just loaded.
ARG NVROADS_API_KEY
RUN NVROADS_API_KEY=${NVROADS_API_KEY} python build_warehouse.py && dbt build --profiles-dir . --exclude-resource-type seed

# Railway injects $PORT at runtime; default to 8501 for local runs.
EXPOSE 8501
CMD streamlit run streamlit_app.py --server.port ${PORT:-8501} --server.address 0.0.0.0
