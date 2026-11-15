{{ config(materialized='view') }}
select *,
    case
        when nullif(trim(nota), '') is null then 'nota ausente'
        when nullif(trim(produto), '') is null then 'produto ausente'
        when data_nota is null then 'data ausente'
        when quantidade is null then 'quantidade ausente'
        when preco is null then 'preço ausente'
        when nullif(trim(pais), '') is null then 'país ausente'
    end as motivo_rejeicao
from {{ source('bronze', 'online_retail') }}
