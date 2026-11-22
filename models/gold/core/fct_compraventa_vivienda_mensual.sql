-- =============================================================================
-- fct_compraventa_vivienda_mensual
-- =============================================================================
-- Hecho de foto periódica: una fila por provincia y mes (50 × 96 = 4.800
-- filas). Alimenta los casos 2 (pandemia) y 3 (mapa del mercado).
-- Se une a dim_lugar por sk_lugar, calculada con la misma función que la
-- dimensión, y a dim_tiempo por id_mes.
-- Los 4 tipos de vivienda pasan de filas a columnas con un bucle Jinja sobre
-- sus códigos: cada código genera su columna num_<código>. El tipo de vivienda
-- no es una dimensión porque sus dos criterios (régimen y estado) reparten el
-- mismo total: como dimensión, sumar todos los tipos daría el doble.
-- Medidas (todas aditivas salvo la variación):
-- - num_libre, num_protegida, num_nueva, num_usada: compraventas por tipo.
-- - num_total: libre + protegida (el total que Silver no guarda). Un test
--   comprueba que también es nueva + usada.
-- - variacion_interanual_total: frente al mismo mes del año anterior (NULL en
--   el primer año del periodo). No aditiva.
-- =============================================================================

{% set tipos_vivienda = ['LIBRE', 'PROTEGIDA', 'NUEVA', 'USADA'] %}

WITH compraventas AS (

    SELECT
        id_provincia,
        id_mes,
        {%- for tipo in tipos_vivienda %}
        SUM(IFF(id_tipo_vivienda = '{{ tipo }}', num_compraventas, 0)) AS num_{{ tipo | lower }}{{ ',' if not loop.last }}
        {%- endfor %}
    FROM {{ ref('slv_compraventa_vivienda_mensual') }}
    GROUP BY
        id_provincia,
        id_mes

),

calculos AS (

    SELECT
        *,
        num_libre + num_protegida AS num_total,
        LAG(num_libre + num_protegida, 12) OVER (
            PARTITION BY id_provincia
            ORDER BY id_mes
        ) AS num_total_anio_anterior
    FROM compraventas

)

SELECT
    CAST({{ dbt_utils.generate_surrogate_key(['id_provincia']) }} AS VARCHAR(32)) AS sk_lugar,
    CAST(id_mes AS NUMBER(6, 0)) AS id_mes,
    CAST(num_libre AS NUMBER(9, 0)) AS num_libre,
    CAST(num_protegida AS NUMBER(9, 0)) AS num_protegida,
    CAST(num_nueva AS NUMBER(9, 0)) AS num_nueva,
    CAST(num_usada AS NUMBER(9, 0)) AS num_usada,
    CAST(num_total AS NUMBER(9, 0)) AS num_total,
    CAST({{ variacion_pct('num_total', 'num_total_anio_anterior') }} AS NUMBER(9, 4)) AS variacion_interanual_total
FROM calculos