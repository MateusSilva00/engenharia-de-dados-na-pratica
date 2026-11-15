WITH destinos AS (
    SELECT
        linha
    FROM
        {{ ref('silver_itens') }}
    UNION ALL
    SELECT
        linha
    FROM
        {{ ref('silver_rejeitados') }}
),
contagem AS (
    SELECT
        linha,
        COUNT(*) AS total
    FROM
        destinos
    GROUP BY
        linha
)
SELECT
    COALESCE(
        b.linha,
        C.linha
    ) AS linha
FROM
    {{ source(
        'bronze',
        'online_retail'
    ) }}
    b full
    JOIN contagem C USING (linha)
WHERE
    b.linha IS NULL
    OR C.linha IS NULL
    OR C.total <> 1
