-- =============================================================================
-- dim_grupo_ipc
-- =============================================================================
-- Dimensión de grupo de gasto del IPC: una fila por grupo (13), el Índice
-- general ('00', la cesta completa) y los 12 grupos ECOICOP. Solo la usa
-- fct_ipc_mensual (caso 4: en qué ha subido el coste de vida).
-- sk_grupo_ipc es una clave subrogada (hash del código ECOICOP) y el código
-- se conserva como atributo.
-- - es_indice_general separa la cesta completa de sus 12 partes: el mapa del
--   caso 4 usa el Índice general y las barras por grupo lo excluyen, para no
--   mezclar el total con sus partes.
-- - es_grupo_vivienda marca el grupo 04 (alquiler y suministros, no la compra
--   de vivienda) para destacarlo en el caso 4 sin escribir el código a mano.
-- =============================================================================

WITH grupos AS (

    SELECT
        id_grupo,
        nombre_grupo,
        es_indice_general
    FROM {{ ref('slv_grupo_ipc') }}

)

SELECT
    CAST({{ dbt_utils.generate_surrogate_key(['id_grupo']) }} AS VARCHAR(32)) AS sk_grupo_ipc,
    CAST(id_grupo AS VARCHAR(2)) AS id_grupo,
    CAST(nombre_grupo AS VARCHAR(100)) AS nombre_grupo,
    CAST(es_indice_general AS BOOLEAN) AS es_indice_general,
    CAST(id_grupo = '04' AS BOOLEAN) AS es_grupo_vivienda
FROM grupos