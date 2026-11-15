from datetime import datetime, timezone

from airflow.sdk import dag, task

from ingestao import baixar_excel, salvar_parquet
from transformacao import carregar_postgres, executar_dbt


@dag(
    dag_id="online_retail",
    start_date=datetime(2026, 1, 1, tzinfo=timezone.utc),
    schedule=None,
    catchup=False,
    max_active_runs=1,
    default_args={"do_xcom_push": False, "retries": 0},
)
def online_retail():
    baixar = task(baixar_excel)()
    salvar = task(salvar_parquet)()

    carregar = task(carregar_postgres)()
    modelar = task(executar_dbt)()

    baixar >> salvar >> carregar >> modelar


dag = online_retail()
