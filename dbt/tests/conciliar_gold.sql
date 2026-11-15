WITH dia AS (
    SELECT
        SUM(vendas_brutas_gbp) AS total
    FROM
        {{ ref('gold_vendas_dia') }}
),
pais AS (
    SELECT
        SUM(vendas_brutas_gbp) AS total
    FROM
        {{ ref('gold_vendas_pais') }}
),
comparacao AS (
    SELECT
        dia.total AS total_dia,
        pais.total + {% if var(
                'demonstrar_divergencia',
                false
            ) %}
            1
        {% else %}
            0
        {% endif %}

        AS total_pais
    FROM
        dia
        CROSS JOIN pais
)
SELECT
    *
FROM
    comparacao
WHERE
    total_dia IS NULL
    OR total_pais IS NULL
    OR total_dia <> total_pais
