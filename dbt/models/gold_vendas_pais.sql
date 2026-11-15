{{ config(schema='gold') }}
select pais as pais, sum(quantidade * preco) as vendas_brutas_gbp
from {{ ref('silver_itens') }}
where quantidade > 0 and preco > 0 and not cancelado
group by 1
