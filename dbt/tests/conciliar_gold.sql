with dia as (
    select sum(vendas_brutas_gbp) as total from {{ ref('gold_vendas_dia') }}
), pais as (
    select sum(vendas_brutas_gbp) as total from {{ ref('gold_vendas_pais') }}
), comparacao as (
    select dia.total as total_dia,
           pais.total + {% if var('demonstrar_divergencia', false) %} 1 {% else %} 0 {% endif %} as total_pais
    from dia cross join pais
)
select * from comparacao
where total_dia is null or total_pais is null or total_dia <> total_pais
