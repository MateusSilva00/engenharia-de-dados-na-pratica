select linha, trim(nota) as nota, trim(produto) as produto, descricao,
       quantidade, data_nota, preco, cliente, trim(pais) as pais,
       upper(left(trim(nota), 1)) = 'C' as cancelado
from {{ ref('stg_itens') }}
where motivo_rejeicao is null
