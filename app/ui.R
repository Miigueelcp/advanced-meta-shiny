# ==============================================================================
# INTERFAZ DE USUARIO (UI)
# ==============================================================================

ui <- dashboardPage(
  dashboardHeader(title = "Meta-Analysis App"),
  
  dashboardSidebar(
    sidebarMenu(
      menuItem("Carga de Datos", tabName = "data", icon = icon("upload")),
      menuItem("Tamaño del Efecto", tabName = "es", icon = icon("calculator")),
      menuItem("Meta-Análisis", tabName = "meta", icon = icon("cog")),
      menuItem("Forest & Drapery Plot", tabName = "forest", icon = icon("chart-bar")),
      menuItem("Outliers e Influencia", tabName = "outliers", icon = icon("exclamation-triangle")),
      menuItem("Análisis de Subgrupos", tabName = "subgroups", icon = icon("layer-group")),
      menuItem("Meta-Regresión", tabName = "metareg", icon = icon("chart-line"))
    )
  ),
  
  dashboardBody(
    tabItems(
      # Pestaña 1: Carga de Datos
      tabItem(tabName = "data",
              fluidRow(
                box(title = "Subir Archivo", width = 4, status = "primary", 
                    solidHeader = TRUE,
                    fileInput("file", "Selecciona tu archivo (CSV o Excel)",
                              accept = c(".csv", ".xlsx", ".xls")),
                    checkboxInput("header", "El archivo tiene encabezado", TRUE),
                    radioButtons("sep", "Separador (solo para CSV)",
                                 choices = c(Coma = ",", PuntoYComa = ";", 
                                             Tab = "\t"), selected = ";")
                ),
                box(title = "Vista Previa", width = 8, status = "info", 
                    solidHeader = TRUE, DTOutput("tabla_datos"))
              )
      ), 
      
      # Pestaña 2. Cálculo del Tamaño del Efecto
      tabItem(tabName = "es",
              fluidRow(
                # Columna de configuración
                box(title = "Configuración del Tamaño del Efecto", width = 4, 
                    status = "primary", solidHeader = TRUE,
                    selectInput("tipo_dato", "1. Tipo de Datos:",
                                choices = c("Medias" = "means", 
                                            "Tablas 2x2 (Binarios)" = "binary", 
                                            "Correlaciones" = "cor",
                                            "Efectos Pre-calculados" = "generic")),
                    
                    # Este menú cambiará según el tipo de dato de arriba
                    uiOutput("ui_medida"), 
                    
                    hr(),
                    h4("2. Asignación de Columnas"),
                    
                    # Aquí aparecerán los selectores para elegir
                    # las columnas del Excel/CSV
                    
                    uiOutput("ui_mapeo_columnas"), 
                    
                    actionButton("btn_calcular", "Calcular Tamaños de Efecto", 
                                 icon = icon("calculator"),
                                 class = "btn-success")
                ),
                # Columna de resultados
                box(title = "Resultados de yi y vi", width = 8, 
                    status = "success", solidHeader = TRUE,
                    DTOutput("tabla_efectos"))
              )
      ), 
      
      # Pestaña 3: Realización del Meta-análisis
      tabItem(tabName = "meta",
              fluidRow(
                box(title = "Configuración del Modelo", width = 4, status = "primary",
                    solidHeader = TRUE, 
                    uiOutput("ui_select_estudio_meta"),
                    
                    hr(),
                    h4("Paradigma de estimación:"),
                    
                    # Elegimos si aplicar un modelo de
                    # efecotos fijos o aleatorios
                    
                    checkboxInput("use_common", "Modelo de Efectos Fijos (Common)"
                                  , value = FALSE), 
                    checkboxInput("use_random", "Modelo de Efectos Aleatorios (Random)"
                                  , value = TRUE),
                    
                    hr(),
                    h4("Parámetros Globales:"),
                    selectInput("method_tau", "Estimador de Tau2:", 
                                choices = c("REML", "DL", "PM", "ML", "EB")),
                    checkboxInput("use_hk", "Ajuste Hartung-Knapp", value = TRUE),
                    checkboxInput("use_prediction", "Calcular Intervalo de Predicción", value = TRUE),
                    
                    
                    conditionalPanel(
                      condition = "input.tipo_dato == 'binary'",
                      hr(),
                      h4("Opciones para Binarios:"),
                      selectInput("method_bin", "Método de agrupación:",
                                  choices = c("Mantel-Haenszel" = "MH", 
                                              "Inverse Variance" = "Inverse", 
                                              "Peto" = "Peto"))
                    ),
                    
                    
                    conditionalPanel(
                      condition = "input.tipo_dato == 'cor'",
                      hr(),
                      h4("Opciones para Correlaciones:"),
                      helpText("Se aplicará automáticamente la transformación Z de Fisher para el cálculo.")
                    ),
                    
                    hr(),
                    actionButton("btn_meta", "Ejecutar Meta-Análisis",
                                 icon = icon("play"), class = "btn-success")
                ),
                
                # Se muestra el resumen estadístico del modelo de
                # meta-análisis
                box(title = "Resumen del Modelo", width = 8, status = "success", 
                    solidHeader = TRUE,
                    verbatimTextOutput("resumen_meta"))
              )
              
      ),
      
      # Pestaña 4: Forest Plot
      tabItem(tabName = "forest",
              fluidRow(
                box(title = "Personalización del Gráfico", width = 4, status = "primary", solidHeader = TRUE,
                    selectInput("forest_layout", "Diseño (Layout):", 
                                # Opciones para el diseño del gráfico
                                choices = c("JAMA" = "JAMA", "RevMan5" = "RevMan5")),
                    
                    checkboxInput("sort_te", "Ordenar por Tamaño de Efecto", value = TRUE),
                    
                    uiOutput("ui_extra_cols"), # Para elegir columnas adicionales 
                    
                    hr(),
                    h4("Opciones de Drapery Plot"),
                    helpText("El Drapery Plot muestra el valor p como una función continua."),
                    checkboxInput("show_drapery", "Incluir Drapery Plot debajo", value = FALSE)
                ),
                
                # Columna de visualización
                box(title = "Gráficos", width = 8, status = "info", solidHeader = TRUE,
                    tabsetPanel(
                      tabPanel("Forest Plot", 
                               # Gráfico principal del Forest Plot
                               plotOutput("plot_forest", height = "700px"),
                               
                               
                               # Solo se muestra si el checkbox 'show_drapery' está marcado
                               conditionalPanel(
                                 condition = "input.show_drapery == true",
                                 hr(), # Una línea horizontal para separar
                                 h4("Vista Combinada: Drapery Plot debajo"),
                                 plotOutput("plot_forest_drapery_comp", height = "600px")
                               )
                      ),
                      tabPanel("Drapery Plot", 
                               # Vista individual del Drapery Plot a pantalla completa
                               plotOutput("plot_drapery", height = "600px"))
                    )
                )
              )
      ),
      
      # Pestaña 5: Outliers
      tabItem(tabName = "outliers",
              fluidRow(
                column(width = 12,
                       tabBox(title = "Herramientas de Diagnóstico", width = 12,
                              
                              # Análisis de Sensibilidad (Leave-one-out)
                              tabPanel("Análisis Leave-one-out", 
                                       plotOutput("plot_inf", height = "800px")),
                              
                              # Influencia y Baujat
                              tabPanel("Influencia y Baujat", 
                                       fluidRow(
                                         box(title = "Diagnósticos de Influencia", width = 8, 
                                             plotOutput("plot_influence_diag", height = "600px")),
                                         box(title = "Gráfico de Baujat", width = 4, 
                                             plotOutput("plot_baujat", height = "600px"))
                                       )),
                              
                              # Gráfico GOSH
                              tabPanel("Gráfico GOSH", 
                                       helpText("Aviso: El cálculo de GOSH puede tardar varios minutos dependiendo del número de estudios."),
                                       actionButton("btn_gosh", "Calcular Gráfico GOSH", class = "btn-warning"),
                                       br(), br(),
                                       plotOutput("plot_gosh", height = "600px"))
                       )
                )
              )
      ),
      
      # Pestaña 6: Análisis de Subgrupos
      tabItem(tabName = "subgroups",
              fluidRow(
                box(title = "Configuración de Subgrupos", width = 4, status = "primary", solidHeader = TRUE,
                    uiOutput("ui_select_subgroup"), # Selector dinámico de columnas categóricas
                    checkboxInput("tau_common", "Usar estimación común de tau^2 entre subgrupos", value = FALSE),
                    hr(),
                    actionButton("btn_subgroup", "Correr Análisis de Subgrupos", 
                                 icon = icon("play"), class = "btn-success")
                ),
                box(title = "Resultados del Análisis", width = 8, status = "success", solidHeader = TRUE,
                    tabsetPanel(
                      tabPanel("Resumen Estadístico", verbatimTextOutput("resumen_subgroup")),
                      tabPanel("Forest Plot por Subgrupos", plotOutput("plot_forest_subgroup", height = "800px"))
                    )
                )
              )
      ),
      
      # Pestaña 7: Meta-Regresión
      tabItem(tabName = "metareg",
              fluidRow(
                box(title = "Configuración de Regresión", width = 4, status = "primary", solidHeader = TRUE,
                    uiOutput("ui_select_preds"), # Selector múltiple de variables
                    checkboxInput("use_int", "Incluir Interacciones (A * B)", value = FALSE),
                    selectInput("reg_method", "Método de estimación:", 
                                choices = c("REML", "ML", "DL", "EB"), selected = "REML"),
                    hr(),
                    actionButton("btn_run_reg", "Correr Regresión", class = "btn-success"),
                    actionButton("btn_permut", "Prueba de Permutación", class = "btn-warning", icon = icon("random"))
                ),
                
                tabBox(title = "Análisis de Regresión", width = 8,
                       tabPanel("Resultados", 
                                verbatimTextOutput("resumen_reg")),
                       
                       tabPanel("Multicolinealidad", 
                                plotOutput("plot_cor_matrix", height = "500px"),
                                helpText("Visualización de la relación entre predictores (PerformanceAnalytics).")),
                       
                       tabPanel("Bubble Plot", 
                                plotOutput("plot_bubble", height = "500px"),
                                helpText("Nota: El gráfico de burbujas solo se genera para el primer predictor numérico.")),
                       
                       tabPanel("Permutaciones", 
                                verbatimTextOutput("resumen_permut"),
                                helpText("Este proceso puede tardar. Se utiliza para validar la robustez de los p-valores."))
                )
              )
      )
      
    )
  )
)
