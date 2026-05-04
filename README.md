# Advances Meta-Analysis & Meta-Regression Shiny App

## Resumen / Overview

Esta plataforma interactiva, desarrollada en **R-Shiny**, ofrece una resolución integral para la síntesis de evidencia científica. Diseñada bajo un marco de trabajo profesional, permite transitar desde la preparación y cálculo de los tamaños del efecto hasta el diagnóstico avanzado de modelos de meta-regresión.

> **Nota:** La interfaz del usuario y la documentación interna del código están desarrolladas en **español**.

## Stack Tecnológico (Core Packages)
La robustez de los cálculos se apoya en las siguientes librerías de R:
* **Motores estadísticos:** `metafor` y `meta` (Meta-análisis y meta-regresión).
* **Conversión de Efectos:** `esc` (Cálculo de tamaños del efecto).
* **Modelado Avanzado**: `MuMIn` (Selección de modelos) y `PerformanceAnalytics` (Análisis de sensibilidad).
* **Interfaz y Carga de Datos:** `shinydashboard`, `DT`, `tidyverse` y `readxl`.

## Funcionalidades Principales

La aplicación ofrece un flujo de trabajo completo, desde el tratamiento de datos brutos hasta el diagnóstico avanzado de modelos complejos:

### 1. Gestión de Datos y Cálculo del Efecto
* **Automatización:** Cálculo de tamaños del efecto a partir de datos brutos o entrada directa de estimaciones previas.
* **Metricas soportadas:** ** * **Datos Continuos:** Diferencia de Medias (MD) y Diferencia de Medias Estandarizada (SMD/g).
  * **Datos Binarios:** Odds Ratio (OR) y Razón de Riesgos (RR).
  * **Asociación:** Correlaciones mediante transformación $z$ de Fisher (ZCOR). 

### 2. Motor de Meta-Análisis
* **Modelado Flexible:** Comparación simultánea de modelos de efectos fijos y aleatorios.
* **Parametros Globales:** Estimadores de $\tau^2$, ajuste de Hartung-Knapp e intervalos de predicción.

### 3. Visualización de Gráficos
* **Forest Plots:** Estilos configurables (JAMA, RevMan5) con capacidad de ordenación según el tamaño del efecto.
* **Drapery Plots:** Visualización de la significación estadística en función del nivel de confianza.

### 4. Identificación de Sesgos y Heterogeneidad
* **Detección de Outliers:** Gráficos de Baujat, análisis de influencia (*Leave-one-out*) y gráficos de diagnóstico.
* **Análisis GOSH:** Exploración exhaustiva de la heterogeneidad mediante *Graphic Display of Heterogeneity*.

### 5. Análisis de Subgrupos
Se puede realizar un análisis estratificado por subgrupos, con la opción de asumir una estimación común de $\tau^2$ entre ellos. Además, se dispone de un forest plot para visualizar los resultados por subgrupos.

### 6. Meta-Regresión
**Modelado:** Inclusión de múltiples covariables y términos de interacción, junto la posibilidad de seleccionar distintos métodos de estimación.
* **Validación Robusta:** Evaluación de la multicolinealidad, **bubble plots** para representar la relación entre moderadores y el efecto combinado en el meta-análisis y **pruebas de permutación** para asegurar la fiabilidad en contextos con un número reducido de estudios ($k$).

## Cómo ejecutar la aplicación

No es necesario que el usuario descargue ni instale el código manualmente. Puede ejecutar la plataforma directamente desde la consola de **RStudio** utilizando el siguiente comando: 

```r
if (!require("shiny")) install.packages("shiny")
shiny::runGitHub("tu-usuario/tu-repositorio", subdir = "app")
