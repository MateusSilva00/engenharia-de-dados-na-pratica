select *
from {{ ref('stg_itens') }}
where motivo_rejeicao is not null
