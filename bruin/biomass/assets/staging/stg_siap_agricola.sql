/* @bruin
name: biomass_analytics_dataset.stg_siap_agricola
type: bq.sql
materialization:
  type: table
depends:
  - create_external_tables
@bruin */

SELECT
    CAST(Anio AS INT64) AS anio,
    UPPER(TRIM(Nomestado)) AS estado, -- Estandarizamos a MAYÚSCULAS y sin espacios extra
    UPPER(TRIM(Nommunicipio)) AS municipio,
    UPPER(TRIM(Nomcultivo)) AS cultivo,
    CAST(Volumenproduccion AS FLOAT64) AS toneladas_produccion,
    CAST(Cosechada AS FLOAT64) AS hectareas_cosechadas
FROM `biomass-energy-491402.biomass_analytics_dataset.ext_siap`
WHERE Volumenproduccion IS NOT NULL;
