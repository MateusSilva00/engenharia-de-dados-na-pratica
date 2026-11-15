SELECT
    CAST(
        data_nota AS DATE
    ) AS dia,
    SUM(
        quantidade * preco
    ) AS vendas_brutas_gbp
FROM
    {{ ref('silver_itens') }}
WHERE
    quantidade > 0
    AND preco > 0
    AND NOT cancelado
GROUP BY
    1
