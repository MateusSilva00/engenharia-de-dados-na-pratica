SELECT
    linha,
    TRIM(nota) AS nota,
    TRIM(produto) AS produto,
    descricao,
    quantidade,
    data_nota,
    preco,
    cliente,
    TRIM(pais) AS pais,
    UPPER(LEFT(TRIM(nota), 1)) = 'C' AS cancelado
FROM
    {{ ref('stg_itens') }}
WHERE
    motivo_rejeicao IS NULL
