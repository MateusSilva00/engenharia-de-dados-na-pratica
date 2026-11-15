SELECT
    *
FROM
    {{ ref('stg_itens') }}
WHERE
    motivo_rejeicao IS NOT NULL
