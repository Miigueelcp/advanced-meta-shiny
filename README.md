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




