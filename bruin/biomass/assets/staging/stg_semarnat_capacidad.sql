/* @bruin
name: biomass_analytics_dataset.stg_semarnat_capacidad
type: bq.sql
materialization:
  type: table
depends:
  - create_external_tables
@bruin */

SELECT
    UPPER(TRIM(Entidad_federativa)) AS estado,
    UPPER(TRIM(Tipo_de_energ__a_limpia)) AS tipo_energia,
    CAST(Establecimientos AS INT64) AS cantidad_plantas,
    CAST(Capacidad_instalada__MW_ AS FLOAT64) AS capacidad_instalada_mw,
    CAST(Generaci__n__GWh_a_ AS FLOAT64) AS generacion_gwh
FROM `biomass-energy-491402.biomass_analytics_dataset.ext_semarnat`
WHERE UPPER(TRIM(Tipo_de_energ__a_limpia)) = 'BIOMASA'
  AND UPPER(TRIM(Entidad_federativa)) != 'TOTAL';
