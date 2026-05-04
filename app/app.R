# ==============================================================================
# ARCHIVO PRINCIPAL 
# ==============================================================================


# 1. Carga de Paquetes

# Paquetes de Interfaz y Sistema
library(shiny)
library(shinydashboard)
library(rsconnect) 

# Paquetes de Manejo de Datos y Tablas
library(tidyverse)
library(readxl) 
library(DT)

# Paquetes Específicos de Meta-Análisis
library(meta)
library(metafor)
library(esc)

# Paquetes de Análisis Avanzado y Selección de Modelos
library(MuMIn)
library(PerformanceAnalytics)


# 2. Carga de la interfaz de usuario
source("ui.R")


# 3. Carga de la lógica del servidor
source("server.R")


# 4. Lanzamiento de la aplicación interactiva
shinyApp(ui,server)
