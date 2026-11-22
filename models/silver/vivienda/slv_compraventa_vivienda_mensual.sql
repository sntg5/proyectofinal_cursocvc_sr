-- =============================================================================
-- slv_compraventa_vivienda_mensual
-- =============================================================================
-- Una fila por provincia, mes y tipo de vivienda: compraventas de viviendas
-- inscritas (INE tabla 6150). Los últimos meses que publica el INE son
-- provisionales y se revisan: el snapshot snp_compraventa_vivienda guarda
-- cada versión que cambia.
-- Las filas salen de provincias × meses × tipos, no de los datos: si al INE
-- le faltara un dato, la fila existiría con num_compraventas NULL y los
-- tests lo detectarían. 2FN: aquí solo quedan claves y la medida.
-- El total de viviendas no se guarda: es libre + protegida (o nueva + usada)
-- y lo calcula Gold.
-- =============================================================================

WITH provincias AS (

    SELECT
        id_provincia
    FROM {{ ref('slv_provincia') }}

),

meses AS (

    SELECT
        id_mes
    FROM {{ ref('slv_mes') }}

),

tipos AS (

    SELECT
        id_tipo_vivienda
    FROM {{ ref('slv_tipo_vivienda') }}

),

compraventas AS (

    SELECT
        id_provincia,
        id_mes,
        id_tipo_vivienda,
        num_compraventas
    FROM {{ ref('int_ine__compraventa_vivienda_1fn') }}

)

SELECT
    CAST(provincias.id_provincia AS VARCHAR(2)) AS id_provincia,
    CAST(meses.id_mes AS NUMBER(6, 0)) AS id_mes,
    CAST(tipos.id_tipo_vivienda AS VARCHAR(10)) AS id_tipo_vivienda,
    CAST(compraventas.num_compraventas AS NUMBER(9, 0)) AS num_compraventas
FROM provincias
CROSS JOIN meses
CROSS JOIN tipos
LEFT JOIN compraventas
    ON compraventas.id_provincia = provincias.id_provincia
    AND compraventas.id_mes = meses.id_mes
    AND compraventas.id_tipo_vivienda = tipos.id_tipo_vivienda