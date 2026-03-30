/* @bruin
name: biomass_analytics_dataset.rep_comparativo_biomasa
type: bq.sql

depends:
  - biomass_analytics_dataset.rep_potencial_agricola
  - biomass_analytics_dataset.stg_semarnat_capacidad

materialization:
  type: table
  partition_by: fecha_reporte
  cluster_by: 
    - estado
@bruin */

WITH agricola AS (
    -- Nuestra tabla base con los 32 estados y su potencial
    SELECT * FROM `biomass-energy-491402.biomass_analytics_dataset.rep_potencial_agricola`
),

semarnat_agrupado AS (
    -- Agrupamos la tabla de SEMARNAT
    SELECT
        estado,
        ROUND(SUM(capacidad_instalada_mw), 2) AS capacidad_instalada_mw,
        ROUND(SUM(generacion_gwh), 2) AS generacion_real_gwh
    FROM `biomass-energy-491402.biomass_analytics_dataset.stg_semarnat_capacidad`
    GROUP BY estado
)

-- Cruce final
SELECT
    -- Inyectamos una columna de fecha para habilitar el particionamiento en BQ
    CAST('2024-01-01' AS DATE) AS fecha_reporte,
    a.estado,
    -- Datos reales (SEMARNAT)
    COALESCE(s.capacidad_instalada_mw, 0) AS capacidad_instalada_mw,
    COALESCE(s.generacion_real_gwh, 0) AS generacion_real_gwh,
    -- Datos potenciales (SIAP)
    a.total_potencial_gwh,
    a.potencial_gwh_cana,
    a.potencial_gwh_maiz,
    -- Brecha de generación
    ROUND((a.total_potencial_gwh - COALESCE(s.generacion_real_gwh, 0)), 2) AS brecha_oportunidad_gwh
FROM agricola a
LEFT JOIN semarnat_agrupado s
    ON a.estado = s.estado;
