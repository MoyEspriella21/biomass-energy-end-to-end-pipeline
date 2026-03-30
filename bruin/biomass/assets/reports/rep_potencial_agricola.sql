/* @bruin
name: biomass_analytics_dataset.rep_potencial_agricola
type: bq.sql

depends:
  - biomass_analytics_dataset.stg_siap_agricola

materialization:
  type: table
@bruin */

WITH filtrado_y_parametros AS (
    -- Paso A: Filtramos solo los cultivos de interés y asignamos sus parámetros termodinámicos
    SELECT
        estado,
        cultivo,
        toneladas_produccion,
        -- Asignación del RCR (Índice de Residuo)
        CASE 
            WHEN cultivo IN ('CAÑA DE AZUCAR', 'CAÑA DE AZÚCAR') THEN 0.30
            WHEN cultivo IN ('MAIZ GRANO', 'MAÍZ GRANO') THEN 1.00
            ELSE 0.0 
        END AS rcr,
        -- Asignación del PCI (Poder Calorífico Inferior en GJ/ton)
        CASE 
            WHEN cultivo IN ('CAÑA DE AZUCAR', 'CAÑA DE AZÚCAR') THEN 7.055
            WHEN cultivo IN ('MAIZ GRANO', 'MAÍZ GRANO') THEN 14.69639
            ELSE 0.0 
        END AS pci_gj_ton,
        -- Eficiencia eléctrica de la planta (25%)
        0.25 AS eficiencia
    FROM `biomass-energy-491402.biomass_analytics_dataset.stg_siap_agricola`
    WHERE cultivo IN ('CAÑA DE AZUCAR', 'CAÑA DE AZÚCAR', 'MAIZ GRANO', 'MAÍZ GRANO')
),

calculo_energia AS (
    -- Paso B: Aplicamos las fórmulas matemáticas por cada fila (municipio/cultivo)
    SELECT
        estado,
        cultivo,
        (toneladas_produccion * rcr) AS masa_residuo_ton,
        -- Fórmula: (((M * PCI * Eficiencia) / 3.6) / 1000)
        ((((toneladas_produccion * rcr) * pci_gj_ton * eficiencia) / 3.6) / 1000) AS generacion_potencial_gwh
    FROM filtrado_y_parametros
)

-- Paso C: Agregación final. Sumamos toda la energía agrupándola por Estado
SELECT
    estado,
    -- Redondeamos a 2 decimales para mayor limpieza visual
    ROUND(SUM(generacion_potencial_gwh), 2) AS total_potencial_gwh,
    ROUND(SUM(CASE WHEN cultivo IN ('CAÑA DE AZUCAR', 'CAÑA DE AZÚCAR') THEN generacion_potencial_gwh ELSE 0 END), 2) AS potencial_gwh_cana,
    ROUND(SUM(CASE WHEN cultivo IN ('MAIZ GRANO', 'MAÍZ GRANO') THEN generacion_potencial_gwh ELSE 0 END), 2) AS potencial_gwh_maiz
FROM calculo_energia
GROUP BY estado;
