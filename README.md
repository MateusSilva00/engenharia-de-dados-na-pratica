# Engenharia de Dados na Prática

## Aula 3 — Ingestão com Python e Airflow

Baixamos a base real **Online Retail**, preservamos o Excel original e gravamos seus dados em Parquet na camada Bronze. Não há limpeza, deduplicação ou dados simulados nesta aula.

### 1. Executar com Python

Instale o [uv](https://docs.astral.sh/uv/getting-started/installation/) e execute na raiz deste repositório:

No Windows, use WSL2 para seguir os comandos da aula.

```bash
uv sync --locked
uv run python ingestao.py
```

O uv prepara o Python 3.12 e instala as dependências do `uv.lock`. A primeira instalação e o download da base precisam de internet.

Arquivos gerados, sobrescritos em cada execução:

- `data/raw/Online Retail.xlsx`: arquivo original da UCI.
- `data/bronze/online_retail.parquet`: todas as linhas e colunas da planilha, sem o índice do pandas.

`InvoiceNo` e `StockCode` são lidos como texto porque identificadores podem conter letras. `Description` também é lido como texto: o Excel contém valores numéricos nessa coluna, e o Parquet exige um tipo consistente por coluna. O Excel original permanece intacto. Cancelamentos, valores ausentes e registros repetidos permanecem na Bronze.

Para inspecionar o resultado:

```bash
uv run python -c 'import pandas as pd; dados = pd.read_parquet("data/bronze/online_retail.parquet"); print(dados.shape); print(dados.head().to_string(index=False))'
```

### 2. Executar pelo Airflow

Com Docker e Docker Compose instalados:

```bash
docker compose up --build -d
docker compose logs -f airflow
```

A primeira construção pode demorar. Espere o Airflow iniciar e abra [localhost:8080](http://localhost:8080). Use `Ctrl+C` para sair da exibição dos logs sem parar o serviço.

Consulte o usuário e a senha local gerados pelo Airflow:

```bash
docker compose exec airflow cat /opt/airflow/simple_auth_manager_passwords.json.generated
```

Na interface, habilite a DAG **online_retail**, clique em **Trigger** e acompanhe as tarefas **baixar_excel** e **salvar_parquet** e seus logs.

A DAG usa TaskFlow com dependência explícita:

```python
baixar = task(baixar_excel)()
salvar = task(salvar_parquet)()

baixar >> salvar
```

`task(funcao)` é a forma de aplicar `@task` a uma função importada, sem criar uma função intermediária. Os parênteses registram as tarefas; a execução fica a cargo do Airflow. `baixar >> salvar` faz a conversão esperar o download terminar. `dag = online_retail()` constrói a DAG decorada com `@dag`, sem executar a ingestão.

Todos os imports ficam no topo. As tarefas usam o Excel no diretório compartilhado, sem passagem de dados por XCom. No terminal, o script executa as mesmas duas funções em sequência.

O serviço usa Airflow 3.3.2 em modo `standalone`, com estado persistido em `.airflow/`. É um ambiente didático local, não uma configuração de produção. A porta fica acessível apenas na própria máquina. Execute pelo terminal e pela DAG em momentos separados: ambos sobrescrevem os mesmos arquivos.

Para parar sem apagar os dados:

```bash
docker compose down
```

### Fonte e licença dos dados

Chen, D. (2015). **Online Retail**. UCI Machine Learning Repository. [DOI: 10.24432/C5BW33](https://doi.org/10.24432/C5BW33). Dados de um varejista britânico, de dezembro de 2010 a dezembro de 2011. Licença dos dados: [CC BY 4.0](https://creativecommons.org/licenses/by/4.0/).

Os preços estão em libras esterlinas; a base não informa confirmação de pagamento. Ela é um arquivo histórico obtido por HTTP, não uma API de pedidos.

Referências: [dataset e dicionário](https://archive.ics.uci.edu/dataset/352/online%2Bretail), [Airflow standalone](https://airflow.apache.org/docs/apache-airflow/3.3.2/start.html), [TaskFlow](https://airflow.apache.org/docs/apache-airflow/3.3.2/tutorial/taskflow.html) e [dependências explícitas](https://airflow.apache.org/docs/apache-airflow/3.3.2/core-concepts/dags.html#task-dependencies).

## Aula 4 — Da Bronze à Gold
Execute `cp -n .env.example .env`, ajuste a senha local e rode
`docker compose up -d --build --remove-orphans`. Dispare a DAG
`online_retail` na UI do Airflow. As quatro tarefas baixam o Excel, gravam
o Parquet, recarregam o PostgreSQL e executam `dbt build`.

A posição no Parquet identifica cada linha do lote. A carga usa uma transação
para substituir a entrada. A Silver conserva cancelamentos e quantidades
negativas. A Gold soma quantidade × preço apenas para vendas com quantidade
e preço positivos e nota sem prefixo C. Os totais estão em GBP.

Para gerar a documentação:
`docker compose exec airflow uv run --locked dbt docs generate --project-dir dbt --profiles-dir dbt`.

Para trocar de etapa, use `git switch aula-03`, `git switch aula-04` ou
`git switch aula-05` e rode `docker compose up -d --build --remove-orphans`.
Os arquivos de dados e os volumes nomeados persistem entre as aulas.

## Aula 5 — Painel e qualidade

Acrescente `METABASE_READER_PASSWORD` ao seu `.env` com uma senha local
distinta, se ele já veio da Aula 4. Suba os serviços e execute a DAG.
Abra <http://localhost:3000>, conclua a configuração local e adicione
PostgreSQL com host `postgres`, porta `5432`, banco igual a `POSTGRES_DB`,
usuário `metabase_reader` e senha igual a `METABASE_READER_PASSWORD`.
Sincronize o esquema `gold` depois do primeiro build.

Crie três perguntas SQL e coloque-as em um painel **Online Retail**:

| Cartão | Visualização | Consulta |
| --- | --- | --- |
| Vendas brutas (GBP) | Número | `select sum(vendas_brutas_gbp) as total_gbp from gold.gold_vendas_dia` |
| Vendas por dia | Linha | `select dia, vendas_brutas_gbp from gold.gold_vendas_dia order by dia` |
| Vendas por país | Barras | `select pais, vendas_brutas_gbp from gold.gold_vendas_pais order by vendas_brutas_gbp desc` |

A conciliação compara o mesmo total agrupado por duas dimensões. Rode o
primeiro comando para ver o teste passar. O segundo deve falhar: soma
£1 ao lado de países somente na consulta de teste. As tabelas do painel
continuam com seus valores originais.

```sh
docker compose exec airflow uv run --locked dbt test --project-dir dbt --profiles-dir dbt --select conciliar_gold
docker compose exec airflow uv run --locked dbt test --project-dir dbt --profiles-dir dbt --select conciliar_gold --vars '{"demonstrar_divergencia": true}'
```
