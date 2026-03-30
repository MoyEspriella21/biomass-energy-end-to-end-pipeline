/* @bruin
name: create_external_tables
type: bq.sql
depends:
  - biomass_ingestion
@bruin */

CREATE OR REPLACE EXTERNAL TABLE `biomass-energy-491402.biomass_analytics_dataset.ext_siap`
OPTIONS (
  format = 'CSV',
  uris = ['gs://data-lake-biomass-491402/raw/raw_siap_agricola_2024.csv'],
  skip_leading_rows = 1,  -- <- Se salta esa
  encoding = 'ISO_8859_1' 
);

CREATE OR REPLACE EXTERNAL TABLE `biomass-energy-491402.biomass_analytics_dataset.ext_semarnat`
OPTIONS (
  format = 'CSV',
  uris = ['gs://data-lake-biomass-491402/raw/raw_semarnat_capacidad.csv'],
  skip_leading_rows = 1,
  encoding = 'UTF8'
);
