""" @bruin
name: biomass_ingestion
type: python
image: python:3.11
@bruin """

import requests
from google.cloud import storage
import urllib3
import pandas as pd
import io

# Ocultamos las alertas de seguridad SSL. 
# Nota técnica: Las páginas del gobierno (.gob.mx) suelen tener certificados de seguridad 
# obsoletos, lo que hace que Python bloquee la descarga por defecto.
urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)

def upload_to_gcs(bucket_name, destination_blob_name, content):
    """
    Sube un archivo directamente a Google Cloud Storage desde la memoria RAM,
    sin necesidad de guardarlo primero en la computadora local.
    """
    storage_client = storage.Client()
    bucket = storage_client.bucket(bucket_name)
    blob = bucket.blob(destination_blob_name)
    
    # Subimos el contenido binario descargado
    blob.upload_from_string(content)
    print(f"Éxito: Archivo cargado en gs://{bucket_name}/{destination_blob_name}")

def main():
    bucket_name = "data-lake-biomass-491402"
    
    # Diccionario con el nombre final que tendrán los archivos en tu Data Lake y sus URLs y las reglas de extracción para cada fuente:
    fuentes = {
        "raw_siap_agricola_2024": {
            "url": "https://nube.agricultura.gob.mx/index.php?view=10AE434F-A2158368-A120BC5A-EDF4AFAA&ANIO=2024",
            "type": "csv"
        },
        "raw_siap_diccionario": {
            "url": "https://nube.agricultura.gob.mx/index.php?view=5D24F995-E734D711-1EA6F8D2-9D1387D7",
            "type": "excel",
            "engine": "openpyxl", # Motor para .xlsx
            "sheet": 0,           # Primera pestaña
            "skiprows": 13        # Saltamos los títulos del gobierno
        },
        "raw_semarnat_capacidad": {
            "url": "https://apps1.semarnat.gob.mx:8443/dgeia/compendio_2020/archivos/02_energia/d2_energia03_05.xls",
            "type": "excel",
            "engine": "xlrd",     # Motor para .xls antiguo
            "sheet": "Indicador", # Pestaña específica con los datos
            "skiprows": 2         # Saltamos los títulos del reporte
        }
    }

    for nombre_archivo, info in fuentes.items():
        print(f"Descargando {nombre_archivo}...")
        
        # CORRECCIÓN: Extraemos específicamente el texto de la URL del diccionario 'info'
        url_real = info["url"]

        # Hacemos la petición HTTP (GET). verify=False ignora el certificado SSL expirado.
        response = requests.get(url_real, verify=False)
        
        # El código 200 significa "OK/Éxito" en el protocolo HTTP
        if response.status_code == 200:
            # Mandamos el contenido binario (response.content) directo a la nube
            ruta_destino = f"raw/{nombre_archivo}.csv" # Todos terminarán siendo .csv
            
            if info["type"] == "csv":
                # Si ya es CSV original, subimos los bytes directos
                upload_to_gcs(bucket_name, ruta_destino, response.content)
            elif info["type"] == "excel":
                print(f"  Transformando formato Excel a CSV en memoria...")
                # Cargamos los bytes descargados en memoria RAM
                excel_data = io.BytesIO(response.content)
                
                # Pandas lee el Excel estructurándolo en filas y columnas
                df = pd.read_excel(
                    excel_data, 
                    engine=info["engine"], 
                    sheet_name=info["sheet"], 
                    skiprows=info["skiprows"]
                ).ffill() # <- ESTO RELLENARÁ LOS ESTADOS VACÍOS
                
                # Convertimos la estructura a un texto plano separado por comas (UTF-8)
                csv_string = df.to_csv(index=False, encoding='utf-8')
                
                # Subimos el texto plano a Google Cloud
                upload_to_gcs(bucket_name, ruta_destino, csv_string)

        else:
            print(f"Error {response.status_code} al intentar descargar {nombre_archivo}")

if __name__ == "__main__":
    main()
