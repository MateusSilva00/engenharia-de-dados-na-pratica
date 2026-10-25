import sys
from io import BytesIO
from pathlib import Path
from zipfile import ZipFile

import pandas as pd
import requests
from loguru import logger
from pydantic import BaseModel, HttpUrl

logger.remove()
logger.add(sys.stdout, format="{message}")


class Configuracao(BaseModel):
    url: HttpUrl = "https://archive.ics.uci.edu/static/public/352/online+retail.zip"
    diretorio_dados: Path = Path(__file__).resolve().parent / "data"


def baixar_excel() -> None:
    config = Configuracao()
    arquivo_excel = config.diretorio_dados / "raw" / "Online Retail.xlsx"
    arquivo_excel.parent.mkdir(parents=True, exist_ok=True)

    logger.info("Baixando a base Online Retail da UCI")
    resposta = requests.get(str(config.url), timeout=120)
    resposta.raise_for_status()

    with ZipFile(BytesIO(resposta.content)) as zip_uci:
        arquivo_excel.write_bytes(zip_uci.read("Online Retail.xlsx"))


def salvar_parquet() -> None:
    config = Configuracao()
    arquivo_excel = config.diretorio_dados / "raw" / "Online Retail.xlsx"
    arquivo_parquet = config.diretorio_dados / "bronze" / "online_retail.parquet"
    arquivo_parquet.parent.mkdir(parents=True, exist_ok=True)

    dados = pd.read_excel(
        arquivo_excel,
        dtype={"InvoiceNo": "string", "StockCode": "string", "Description": "string"},
    )
    dados.to_parquet(arquivo_parquet, index=False)
    logger.info("{} linhas gravadas em {}", len(dados), arquivo_parquet)


if __name__ == "__main__":
    baixar_excel()
    salvar_parquet()
