#equipo_evaluacion_final_python/
Informe_Final.pdf  LIZZY ESPERANZA CONTRERAS BAQUEDANO / HECTOR JAVIER POSADAS AGUILERA
 Informe_Final.pdf


import pandas as pd
import numpy as np

print("=== FASE I: EXPLORACIÓN, LIMPIEZA Y TRANSFORMACIÓN EN PYTHON ===")

# =========================================================
# 1. Exploración y Diagnóstico de Calidad de Datos
# =========================================================
url = 'https://raw.githubusercontent.com/drodriguez01/data-science-masterclass/refs/heads/main/datasets/superstore_caso_estudio.csv'
df = pd.read_csv(url)

print(f"\nDimensiones iniciales del dataset: {df.shape}")
print("\nTipos de datos iniciales e información general:")
df.info()

print("\nNulos iniciales detectados por columna:")
print(df.isnull().sum())

print(f"\nFilas duplicadas iniciales: {df.duplicated().sum()}")

# =========================================================
# 2. Limpieza y Transformación de Datos
# =========================================================

# 2.1 Eliminación de duplicados
df = df.drop_duplicates()

# 2.2 Tratamiento de inconsistencias de texto y espacios
text_cols = ['Category', 'Sub-Category', 'Segment', 'Region', 'Country', 'City']
for col in text_cols:
    if col in df.columns:
        df[col] = df[col].astype("string").str.strip().str.title()

# 2.3 Tratamiento de valores faltantes
if 'Postal Code' in df.columns:
    columnas_ubicacion = [
        columna for columna in ['City', 'State']
        if columna in df.columns
    ]

    if columnas_ubicacion:
        moda_postal = df.groupby(columnas_ubicacion)['Postal Code'].transform(
            lambda grupo: grupo.mode().iloc[0]
            if not grupo.mode().empty else pd.NA
        )
        df['Postal Code'] = df['Postal Code'].fillna(moda_postal)

# 2.4 Conversión numérica (limpieza de símbolos de moneda, comas o caracteres extraños)
def clean_numeric(val):
    if pd.isna(val):
        return np.nan

    val_str = str(val).replace('$', '').replace(',', '').strip()
    try:
        return float(val_str)
    except ValueError:
        return np.nan

for col in ['Sales', 'Profit', 'Discount']:
    if col in df.columns:
        df[col] = df[col].apply(clean_numeric)

if 'Quantity' in df.columns:
    df['Quantity'] = df['Quantity'].apply(clean_numeric).astype('Int64')

# 2.5 Conversión de Fechas y corrección 
df['Order Date'] = pd.to_datetime(df['Order Date'], errors='coerce')
df['Ship Date'] = pd.to_datetime(df['Ship Date'], errors='coerce')

# Identificar registros donde Ship Date < Order Date
inversion_mask = df['Ship Date'] < df['Order Date']
if inversion_mask.any():
    print(f"\nRevisar {inversion_mask.sum()} registros con Ship Date anterior a Order Date.")
    temp = df.loc[inversion_mask, 'Order Date']
df.loc[inversion_mask, 'Order Date'] = df.loc[inversion_mask, 'Ship Date']
df.loc[inversion_mask, 'Ship Date'] = temp
# =========================================================
# 3. Validación de Reglas de Negocio y Outliers
# =========================================================

# Ajustar cantidades inválidas 
df.loc[df['Quantity'] <= 0, 'Quantity'] = 1

# Corregir escalas de descuentos mayores al 100% 
df.loc[df['Discount'] > 1.0, 'Discount'] = df['Discount'] / 100.0
df.loc[df['Discount'] < 0, 'Discount'] = 0.0

# Crear variable Delivery_Days
df['Delivery_Days'] = (df['Ship Date'] - df['Order Date']).dt.days
df.loc[inversion_mask, 'Delivery_Days'] = pd.NA

# Detección de outliers 
Q1 = df['Sales'].quantile(0.25)
Q3 = df['Sales'].quantile(0.75)
IQR = Q3 - Q1
limite_inferior = Q1 - 1.5 * IQR
limite_superior = Q3 + 1.5 * IQR
outliers = df[(df['Sales'] < limite_inferior) | (df['Sales'] > limite_superior)]
print(f"\nOutliers identificados en Sales (por método IQR): {len(outliers)} registros.")
print("Justificación: Se conservan estos outliers dado que representan ventas mayoristas reales de la empresa.")

# =========================================================
# 4. Exportación del Dataset Limpio
# =========================================================
output_filename = 'superstore_limpio.csv'
df.to_csv(output_filename, index=False)

print(f"\n=== PROCESO COMPLETADO ===")
print(f"Dataset limpio exportado correctamente a: '{output_filename}' con dimensiones: {df.shape}")
print(df.head())
