with destinos as (
    select linha from {{ ref('silver_itens') }}
    union all
    select linha from {{ ref('silver_rejeitados') }}
), contagem as (
    select linha, count(*) as total from destinos group by linha
)
select coalesce(b.linha, c.linha) as linha
from {{ source('bronze', 'online_retail') }} b
full join contagem c using (linha)
where b.linha is null or c.linha is null or c.total <> 1
