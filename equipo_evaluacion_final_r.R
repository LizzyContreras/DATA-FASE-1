 Informe_Final LIZZY ESPERANZA CONTRERAS BAQUEDANO / HECTOR JAVIER POSADAS AGUILERA
# -----------------------------------------------------
# 1. CARGA DE LIBRERÍAS Y DATOS
# -----------------------------------------------------
library(tidyverse)
library(gridExtra)

ruta_csv <- file.choose()

df <- read_csv(ruta_csv, show_col_types = FALSE)

# Revisar datos faltantes y duplicados
faltantes <- colSums(is.na(df))
cat("\nValores faltantes por columna:\n")
print(faltantes)

duplicados <- sum(duplicated(df))
cat("\nFilas duplicadas exactas:", duplicados, "\n")


if (duplicados > 0) {
  print(df[duplicated(df), ])
}

columnas_requeridas <- c(
  "Category", "Region", "Product Name", "Customer Name",
  "Sales", "Profit", "Delivery_Days"
)
columnas_faltantes <- setdiff(columnas_requeridas, names(df))

if (length(columnas_faltantes) > 0) {
  stop(
    "Faltan estas columnas en el CSV: ",
    paste(columnas_faltantes, collapse = ", ")
  )
}

cat("\n--- Datos cargados con éxito desde: ", ruta_csv, " ---\n", sep = "")

# -----------------------------------------------------
# 2. ANÁLISIS DE DATOS
# -----------------------------------------------------

cat("\n===========================================\n")
cat("2.1 VENTAS POR CATEGORÍA\n")
cat("===========================================\n")
ventas_cat <- df %>%
  group_by(Category) %>%
  summarise(Ventas_Totales = sum(Sales, na.rm = TRUE), .groups = "drop") %>%
  arrange(desc(Ventas_Totales))
print(ventas_cat)

cat("\n===========================================\n")
cat("2.2 GANANCIA POR REGIÓN\n")
cat("===========================================\n")
ganancia_reg <- df %>%
  group_by(Region) %>%
  summarise(Ganancia_Total = sum(Profit, na.rm = TRUE), .groups = "drop") %>%
  arrange(desc(Ganancia_Total))
print(ganancia_reg)

cat("\n===========================================\n")
cat("2.3 TOP 5 PRODUCTOS CON MAYORES VENTAS\n")
cat("===========================================\n")
top_prod <- df %>%
  group_by(`Product Name`) %>%
  summarise(Ventas_Totales = sum(Sales, na.rm = TRUE), .groups = "drop") %>%
  arrange(desc(Ventas_Totales)) %>%
  slice_head(n = 5)
print(top_prod)

cat("\n===========================================\n")
cat("2.4 TOP 5 CLIENTES CON MAYOR MONTO DE COMPRA\n")
cat("===========================================\n")
top_cli <- df %>%
  group_by(`Customer Name`) %>%
  summarise(Compra_Acumulada = sum(Sales, na.rm = TRUE), .groups = "drop") %>%
  arrange(desc(Compra_Acumulada)) %>%
  slice_head(n = 5)
print(top_cli)

cat("\n===========================================\n")
cat("2.5 MÉTRICAS COMPLEMENTARIAS (Días de Entrega)\n")
cat("===========================================\n")
metricas <- df %>%
  summarise(
    Promedio_Entrega = mean(Delivery_Days, na.rm = TRUE),
    Minimo_Entrega = min(Delivery_Days, na.rm = TRUE),
    Maximo_Entrega = max(Delivery_Days, na.rm = TRUE)
  )
print(metricas)

# -----------------------------------------------------
# 3. VISUALIZACIÓN DE DATOS (ggplot2)
# -----------------------------------------------------

# Gráfico 1 - Ventas por Categoría
g1 <- ggplot(df %>%
               group_by(Category) %>%
               summarise(Ventas_Totales = sum(Sales, na.rm = TRUE), .groups = "drop"),
             aes(x = reorder(Category, -Ventas_Totales), y = Ventas_Totales, fill = Category)) +
  geom_col(show.legend = FALSE) +
  geom_text(aes(label = round(Ventas_Totales, 1)), vjust = -0.3, size = 3.5) +
  scale_fill_brewer(palette = "Set2") +
  labs(title = "Gráfico 1: Ventas Totales por Categoría",
       x = "Categoría",
       y = "Ventas Totales ($)") +
  theme_minimal() +
  theme(plot.title = element_text(face = "bold", size = 12, hjust = 0.5))

# Gráfico 2 - Ganancia por Región
g2 <- ggplot(df %>%
               group_by(Region) %>%
               summarise(Ganancia_Total = sum(Profit, na.rm = TRUE), .groups = "drop"),
             aes(x = reorder(Region, -Ganancia_Total), y = Ganancia_Total, fill = Region)) +
  geom_col(show.legend = FALSE) +
  geom_text(aes(label = round(Ganancia_Total, 1)), vjust = -0.3, size = 3.5) +
  scale_fill_brewer(palette = "Pastel1") +
  labs(title = "Gráfico 2: Ganancia Total por Región",
       x = "Región",
       y = "Ganancia Total ($)") +
  theme_minimal() +
  theme(plot.title = element_text(face = "bold", size = 12, hjust = 0.5))

# Gráfico 3 - Relación Ventas vs. Ganancias
g3 <- ggplot(df, aes(x = Sales, y = Profit, color = Category)) +
  geom_point(alpha = 0.7, size = 2) +
  geom_smooth(method = "lm", se = FALSE, color = "black", linetype = "dashed", linewidth = 0.7) +
  scale_color_brewer(palette = "Dark2") +
  labs(title = "Gráfico 3: Relación Ventas vs. Ganancias",
       x = "Ventas ($)",
       y = "Ganancia ($)",
       color = "Categoría") +
  theme_minimal() +
  theme(plot.title = element_text(face = "bold", size = 12, hjust = 0.5),
        legend.position = "bottom")

# Organizar y mostrar los tres gráficos en una sola visualización
grid.arrange(g1, g2, g3, ncol = 1)
