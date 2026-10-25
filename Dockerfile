FROM python:3.12-slim-bookworm
COPY --from=ghcr.io/astral-sh/uv:0.11.15 /uv /uvx /bin/

WORKDIR /app
ENV UV_LINK_MODE=copy

COPY pyproject.toml uv.lock ./
RUN uv sync --locked --no-dev --no-install-project

COPY ingestao.py ./
COPY dags/ ./dags/

ENV AIRFLOW_HOME=/opt/airflow \
    AIRFLOW__CORE__DAGS_FOLDER=/app/dags \
    AIRFLOW__CORE__LOAD_EXAMPLES=False \
    PYTHONPATH=/app

CMD ["uv", "run", "--locked", "airflow", "standalone"]
