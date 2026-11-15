import csv
import os
import subprocess
import tempfile
from pathlib import Path

import psycopg2
import pyarrow.parquet as pq

ROOT = Path(__file__).resolve().parent
COLUNAS = (
    "InvoiceNo", "StockCode", "Description", "Quantity",
    "InvoiceDate", "UnitPrice", "CustomerID", "Country",
)


def carregar_postgres() -> None:
    parquet = pq.ParquetFile(ROOT / "data/bronze/online_retail.parquet")
    if parquet.metadata.num_rows == 0:
        raise ValueError("O Parquet da Bronze está vazio")

    conn = psycopg2.connect(
        host="postgres", dbname=os.environ["POSTGRES_DB"],
        user=os.environ["POSTGRES_USER"], password=os.environ["POSTGRES_PASSWORD"],
    )
    try:
        with conn, conn.cursor() as cursor, tempfile.TemporaryFile(mode="w+t") as lote:
            cursor.execute("""
                create schema if not exists bronze;
                create table if not exists bronze.online_retail (
                    linha bigint primary key, nota text, produto text, descricao text,
                    quantidade integer, data_nota timestamp, preco numeric,
                    cliente numeric, pais text
                );
                truncate bronze.online_retail;
            """)
            writer = csv.writer(lote)
            posicao = 0
            for batch in parquet.iter_batches(columns=list(COLUNAS)):
                colunas = batch.to_pydict()
                for valores in zip(*(colunas[c] for c in COLUNAS), strict=True):
                    posicao += 1
                    writer.writerow((posicao, *valores))
            lote.seek(0)
            cursor.copy_expert(
                "COPY bronze.online_retail FROM STDIN WITH (FORMAT CSV)", lote
            )
            if posicao != parquet.metadata.num_rows:
                raise ValueError("Contagem da carga difere da Bronze")
    finally:
        conn.close()


def executar_dbt() -> None:
    subprocess.run(
        ["dbt", "build", "--project-dir", str(ROOT / "dbt"),
         "--profiles-dir", str(ROOT / "dbt")],
        check=True,
    )
