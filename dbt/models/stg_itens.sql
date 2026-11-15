{{ config(
    materialized = 'view'
) }}

SELECT
    *,
    CASE
        WHEN NULLIF(TRIM(nota), '') IS NULL THEN 'nota ausente'
        WHEN NULLIF(TRIM(produto), '') IS NULL THEN 'produto ausente'
        WHEN data_nota IS NULL THEN 'data ausente'
        WHEN quantidade IS NULL THEN 'quantidade ausente'
        WHEN preco IS NULL THEN 'preço ausente'
        WHEN NULLIF(TRIM(pais), '') IS NULL THEN 'país ausente'END AS motivo_rejeicao
        FROM
            {{ source(
                'bronze',
                'online_retail'
            ) }}
