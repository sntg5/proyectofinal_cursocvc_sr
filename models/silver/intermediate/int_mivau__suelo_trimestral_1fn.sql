-- =============================================================================
-- int_mivau__suelo_trimestral_1fn
-- =============================================================================
-- Paso a 1FN de las tablas 1 y 4 del MIVAU: una fila por provincia y trimestre.
-- 1. Grupo repetitivo: las 90 columnas de trimestres pasan a filas con
--    unpivot_trimestres, que asigna el periodo por la posición de la columna.
-- 2. Filas que no son datos: los títulos y la cabecera (filas 1 a 13 de
--    Excel) se descartan dentro de la macro.
-- 3. Niveles mezclados en COL_B: solo quedan las 50 provincias del seed,
--    cruzando por nombre_mivau. El total nacional, las CCAA pluriprovinciales
--    y Ceuta y Melilla se quedan en staging para los tests de conciliación.
-- 4. Periodo de análisis: de anio_inicio a anio_fin.
-- Precio y transacciones van juntos porque dependen de la misma clave
-- completa (provincia y trimestre), aunque vengan de dos ficheros.
-- =============================================================================

WITH precio AS (

    {{ unpivot_trimestres(ref('stg_mivau__precio_suelo'), 'precio_m2') }}

),

transacciones AS (

    {{ unpivot_trimestres(ref('stg_mivau__transacciones_suelo'), 'num_transacciones') }}

),

provincias AS (

    SELECT
        id_provincia,
        nombre_mivau
    FROM {{ ref('seed_provincias') }}

),

suelo AS (

    SELECT
        provincias.id_provincia,
        precio.anio * 10 + precio.num_trimestre AS id_trimestre,
        precio.anio,
        precio.num_trimestre,
        precio.precio_m2,
        transacciones.num_transacciones
    FROM provincias
    INNER JOIN precio
        ON precio.territorio = provincias.nombre_mivau
    INNER JOIN transacciones
        ON transacciones.territorio = provincias.nombre_mivau
        AND transacciones.anio = precio.anio
        AND transacciones.num_trimestre = precio.num_trimestre
    WHERE precio.anio BETWEEN {{ var('anio_inicio') }} AND {{ var('anio_fin') }}

)

SELECT *
FROM suelo