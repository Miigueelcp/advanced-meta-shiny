# ==============================================================================
# LÓGICA DEL SERVIDOR (SERVER)
# ==============================================================================


server <- function(input, output, session){
  
  # 1. Gestión de Datos --------------------------------------------------------
  
  # Objeto reactivo para almacenar los datos subidos
  datos <- reactive({
    
    file <- input$file
    ext <- tools::file_ext(file$datapath)
    
    # Se espera que el usuario cargue el archivo correspondiente
    req(file) 
    
    # Selección de formato según extensión
    if(ext == "csv"){
      read.csv(file$datapath, header = input$header, sep = input$sep)
    } else {
      readxl::read_excel(file$datapath)
    }
  })
  
  # Renderizado de la tabla en la interfaz
  output$tabla_datos <- renderDT({
    req(datos())
    datatable(datos(), options = list(pageLength = 10, scrollX = TRUE))
  })
  
  
  # 2. Configuración del Tamaño del Efecto -------------------------------------
  
  
  # UI dinámica para elegir la métrica según el tipo de dato
  output$ui_medida <- renderUI({
    
    # Se espera que el usuario eliga el tipo de dato
    req(input$tipo_dato)
    
    # Se implementa una condición en función del tamaño del efecto
    
    if(input$tipo_dato == "means"){
      selectInput("medida", "Medida",
                  choices = c("Diferencia de Medias (MD)" = "MD",
                              "Diferencia de Medias Estandarizada (SMD/ g)" = "SMD"))
    } else if(input$tipo_dato == "binary"){
      selectInput("medida","Medida",
                  choices = c("Odds Ratio (OR)" = "OR",
                              "Risk Ratio (RR)" = "RR", 
                              "Risk Difference (RD)" = "RD"))
    } else if(input$tipo_dato == "cor") {
      selectInput("medida", "Medida:", 
                  choices = c("Correlación de Fisher (ZCOR)" = "ZCOR"))
    } else {
      # Caso para "generic" (Efectos pre-calculados)
      selectInput("medida", "Métrica de los datos subidos:", 
                  choices = c("Efecto Genérico (Log/Lineal)" = "GEN"))
    }
  })
  
  # UI dinámica para el mapeo de columnas según el tipo de dato
  output$ui_mapeo_columnas <- renderUI({
    
    req(datos())
    cols <- colnames(datos())
    
    # Se asignan nombres a las columnas según el tipo de dato
    if(input$tipo_dato =="means"){
      tagList(
        selectInput("m1i", "Media Grupo 1:", cols),
        selectInput("sd1i", "Desv. Est. Grupo 1:", cols),
        selectInput("n1i", "N Grupo 1:", cols),
        selectInput("m2i", "Media Grupo 2:", cols),
        selectInput("sd2i", "Desv. Est. Grupo 2:", cols),
        selectInput("n2i", "N Grupo 2:", cols)
      )
      
    } else if(input$tipo_dato == "binary") {
      tagList(
        selectInput("ai", "Eventos Grupo 1 (ai):", cols),
        selectInput("bi", "No-eventos Grupo 1 (bi):", cols),
        selectInput("ci", "Eventos Grupo 2 (ci):", cols),
        selectInput("di", "No-eventos Grupo 2 (di):", cols)
      )
    } else if(input$tipo_dato == "cor") {
      tagList(
        selectInput("ri", "Coef. Correlación (ri):", cols),
        selectInput("ni", "Tamaño Muestral (ni):", cols)
      )
    } else if(input$tipo_dato == "generic") {
      
      tagList(
        selectInput("yi_col", "Selecciona la columna del Efecto (yi / TE):", cols),
        selectInput("sei_col", "Selecciona la columna del Error Estándar (sei / seTE):", cols),
        helpText("Nota: Si tienes la Varianza, asegúrate de transformarla a Error Estándar (raíz cuadrada) antes de usar esta opción.")
      )
    }
  })
  
  
  # Cálculo de Tamaños de Efecto
  datos_calculados <- eventReactive(input$btn_calcular, {
    
    req(datos(), input$medida) 
    df <- datos()
    medida_elegida <- input$medida
    

    if (input$tipo_dato == "generic") {
      
      # caso genérico. no se realizan cálculos; solo se extraen las variables
      # seleccionadas por el usuario. Se crea un DataFrame con la misma
      # estructura que escalc (yi y vi)
      req(input$yi_col, input$sei_col)
      
      res <- data.frame(
        yi = as.numeric(df[[input$yi_col]]),
        sei = as.numeric(df[[input$sei_col]]),
        vi = (as.numeric(df[[input$sei_col]]))^2
      )
      
      # Se añaden los nombres de los estudios si están disponiubles para 
      # la tabla
      if (!is.null(input$col_estudio_meta)) {
        res <- cbind(Estudio = df[[input$col_estudio_meta]], res)
      }
      
    } else if (input$tipo_dato == "means") {
      res <- escalc(measure = medida_elegida, 
                    m1i = df[[input$m1i]], sd1i = df[[input$sd1i]], n1i = df[[input$n1i]],
                    m2i = df[[input$m2i]], sd2i = df[[input$sd2i]], n2i = df[[input$n2i]])
      
    } else if (input$tipo_dato == "binary") {
      res <- escalc(measure = medida_elegida, 
                    ai = df[[input$ai]], bi = df[[input$bi]], 
                    ci = df[[input$ci]], di = df[[input$di]])
      
    } else if (input$tipo_dato == "cor") {
      res <- escalc(measure = medida_elegida, 
                    ri = df[[input$ri]], ni = df[[input$ni]])
    }
    
    return(res)
  })
  
  # Se muestran los resultados
  output$tabla_efectos <- renderDT({
    
    req(datos_calculados()) 
    df_final <- as.data.frame(datos_calculados())
    
    # Se genera la visualización
    datatable(df_final, 
              options = list(pageLength = 10, scrollX = TRUE),
              rownames = FALSE)
  })
  
  
  # 3. Meta-Análisis -----------------------------------------------------------

  
  # Se crea el selector de estudios
  output$ui_select_estudio_meta <- renderUI({
    req(datos())
    selectInput("col_estudio_meta", "Selecciona columna de Estudios:", 
                choices = colnames(datos()))
  })
  
  # Inicialización del modelo meta
  modelo_meta <- eventReactive(input$btn_meta,{
    
    req(datos(), input$tipo_dato, input$col_estudio_meta)
    
    # Validación de entradas según tipo de dato
    if (input$tipo_dato == "means") {
      req(input$m1i, input$sd1i, input$n1i, input$m2i, input$sd2i, input$n2i)
    } else if (input$tipo_dato == "binary") {
      req(input$ai, input$bi, input$ci, input$di)
    } else if (input$tipo_dato == "cor") {
      req(input$ri, input$ni)
    } else if (input$tipo_dato == "generic") {
      req(input$yi_col, input$sei_col)
    }
    

    df <- datos()
    
    # Argumentos base comunes para las funciones de meta
    arg_base <- list(
      studlab = df[[input$col_estudio_meta]],
      data =df,
      common = input$use_common,
      random = input$use_random, 
      method.tau = input$method_tau,
      method.random.ci = if(input$use_hk) "HK" else "z",
      prediction = input$use_prediction
    )
    
    # Si el usuario deactiva tanto use_common como use_random el meta-análisis
    # no tendrá valores para promediar y generará un error.
    validate(
      need(input$use_common == TRUE || input$use_random == TRUE, 
           "Por favor, selecciona al menos un modelo de estimación (Fijos o Aleatorios).")
    )
    
    # Ejecución de funciones según el tipo de dato
    if (input$tipo_dato == "generic") {

      m <- do.call(metagen, c(list(
        TE = df[[input$yi_col]],
        seTE = df[[input$sei_col]],
        sm = "Efecto" 
      ), arg_base))
      
    } else if (input$tipo_dato == "means") {
      
      m <- do.call(metacont, c(list(
        n.e = df[[input$n1i]], mean.e = df[[input$m1i]], sd.e = df[[input$sd1i]],
        n.c = df[[input$n2i]], mean.c = df[[input$m2i]], sd.c = df[[input$sd2i]],
        sm = input$medida, method.smd = "Hedges"
      ), arg_base))
      
    } else if (input$tipo_dato == "binary") {
      
      m <- do.call(metabin, c(list(
        event.e = df[[input$ai]], n.e = df[[input$ai]] + df[[input$bi]],
        event.c = df[[input$ci]], n.c = df[[input$ci]] + df[[input$di]],
        sm = input$medida, method = input$method_bin
      ), arg_base))
      
    } else {

      m <- do.call(metacor, c(list(
        cor = df[[input$ri]], n = df[[input$ni]]
      ), arg_base))
    }
    
    return(m)
  })
  
  # Se muestran los resultados
  output$resumen_meta <- renderPrint({
    
    req(modelo_meta())
    summary(modelo_meta())   
  })
  
  
  
  # 5. Visualización: Forest & Drapery Plots -----------------------------------

  
  # Se comienza con el forest plot
  output$plot_forest <- renderPlot({
    
    req(modelo_meta()) 
    
    variable_orden <- NULL
    if (isTRUE(input$sort_te)) {
      variable_orden <- modelo_meta()$TE
    }
    
    # Configuración de Predicción
    # Si el input no existe aún, por defecto se establece en FALSE
    prediccion <- isTRUE(input$use_prediction)
    
    # En RevMan5 los parámetros de heterogeneidad se calculan automáticamente;
    # por tanto, en esta función no se pasa el argumento correspondiente
    print_tau2_option <- if (input$forest_layout == "RevMan5") {
      NULL
    } else {
      TRUE
    }
    
    # Se genera el gráfico
    forest(modelo_meta(),
           layout = input$forest_layout,
           sortvar = variable_orden,
           prediction = prediccion,
           col.diamond = "royalblue",
           print.tau2 = print_tau2_option)
  })
  
  
  # Visualización del Drapery Plot
  output$plot_drapery <- renderPlot({
    req(modelo_meta())
    drapery(modelo_meta(), 
            labels = "studlab", 
            type = "pval", 
            legend = FALSE)
  })
  
  # Se renderiza el Dapery Plot debajo del Forest Plot si se activa la opción
  # de mostrarlo debajo
  output$plot_forest_drapery_comp <- renderPlot({
    
    req(modelo_meta(), input$show_drapery)
    
    # Generación del Drapery plot optimizado para su visualización inferior
    drapery(modelo_meta(), 
            labels = "studlab", 
            type = "pval", 
            cex.labels = 0.7, 
            legend = FALSE)
  })
  

  # 5. Análisis de la sensibilidad y outliers ----------------------------------
  
  
  # Adaptación del modelo para metafor (rma)
  modelo_rma <- reactive({
    
    req(modelo_meta())
    m <- modelo_meta()
    
    metafor::rma(yi = m$TE, 
                 sei = m$seTE, 
                 method = m$method.tau, 
                 test = if(m$method.random.ci == "HK") "knha" else "z")
  })
  
  
  # Análisis de la sensibilidad
  output$plot_inf <- renderPlot({
    
    req(modelo_meta())
    
    inf_analysis <- metainf(modelo_meta())
    
    # Gráfico
    forest(inf_analysis, 
           col.diamond = "red", 
           main = "Análisis de Sensibilidad")
  })
  
  # Diagnósticos de Influencia
  output$plot_influence_diag <- renderPlot({
    
    req(modelo_rma())
    
    inf_m <- influence(modelo_rma())
    
    plot(inf_m)
  })
  
  # Gráfico de Baujat
  output$plot_baujat <- renderPlot({
    
    req(modelo_meta())
    
    baujat(modelo_meta(), main = "Gráfico de Baujat")
  })
  
  # Gráfico de GOSH
  gosh_res <- eventReactive(input$btn_gosh, {
    
    req(modelo_rma())
    
    withProgress(message = 'Calculando combinaciones GOSH...', value = 0, {
      
      gosh(modelo_rma())
    })
  })
  
  # Visualización del gráfico GOSH
  output$plot_gosh <- renderPlot({
    
    req(gosh_res())
    
    plot(gosh_res(), alpha = 0.1, col = "royalblue", 
         main = "Análisis de subconjuntos combinatorios (GOSH)")
  })
  
  
  
  # 6. Análisis de Subgrupos ---------------------------------------------------
  
  
  # Se crea un selector dinámico de la variable de subgrupo
  output$ui_select_subgroup <- renderUI({
    
    req(datos())
    df <- datos()
    
    # Se filtran las columnas no numéricas para subgrupos (o aquellas con
    # pocos niveles)
    cols_cat <- colnames(df)[sapply(df, function(x) !is.numeric(x) || length(unique(x)) < 10)]
    
    selectInput("subgroup_var", "Selecciona Variable de Subgrupo:", choices = cols_cat)
  })
  
  
  # Aplicación del análisis de subgrupos
  modelo_subgroup <- eventReactive(input$btn_subgroup, {
    
    req(modelo_meta(), input$subgroup_var)
    
    # Se aplica update() sobre el modelo original. Esto incorpora la variable
    # de subgurpo y define si tau2 es común o no
    res <- update(modelo_meta(), 
                  subgroup = datos()[[input$subgroup_var]], 
                  tau.common = input$tau_common)
    return(res)
  })
  
  # Resultados estadísticos
  output$resumen_subgroup <- renderPrint({
    
    req(modelo_subgroup())
    summary(modelo_subgroup())
  })
  
  # Visualización de forest group para subgrupos
  output$plot_forest_subgroup <- renderPlot({
    
    req(modelo_subgroup())
    
    forest(modelo_subgroup(),
           test.subgroup = TRUE,
           col.diamond = "forestgreen",
           prediction = input$use_prediction) 
  })
  
  
  
  # 7. Meta-Regresión ----------------------------------------------------------
  
  
  # Selección de predictores
  output$ui_select_preds <- renderUI({
    
    req(datos())
    
    selectInput("preds", "Selecciona Predictores (X):", 
                choices = colnames(datos()), multiple = TRUE)
  })
  
  # Construcción de la fórmula de meta-regresión
  reg_obj <- eventReactive(input$btn_run_reg, {
    
    req(modelo_meta(), input$preds)
    
    simbolo <- if(input$use_int) " * " else " + "
    formula_str <- paste("~", paste(input$preds, collapse = simbolo))
    
    # Uso de metareg 
    res <- metareg(modelo_meta(), as.formula(formula_str), method.tau = input$reg_method)
    
    return(res)
  })
  
  # Se muestran los resultados de la meta-regresión
  output$resumen_reg <- renderPrint({
    
    req(reg_obj())
    
    summary(reg_obj())
  })
  
  
  # Bubble plot 
  output$plot_bubble <- renderPlot({
    
    req(reg_obj())
    
    bubble(reg_obj(), studlab = TRUE, main = "Bubble Plot")
  })
  
  # Multicolinealidad
  output$plot_cor_matrix <- renderPlot({
    
    req(datos(), input$preds)
    
    # Selección de las columnas numéricas de los predictores elegidos
    df_preds <- datos()[, input$preds, drop = FALSE]
    df_num <- df_preds[sapply(df_preds, is.numeric)]
    
    validate(
      need(ncol(df_num) >= 2, "Selecciona al menos 2 variables numéricas para ver la correlación.")
    )
    
    PerformanceAnalytics::chart.Correlation(df_num, histogram = TRUE, pch = 19)
  })
  
  
  # Prueba de Permutación
  res_permut <- eventReactive(input$btn_permut, {
    
    req(reg_obj())
    
    withProgress(message = 'Calculando permutaciones (Iterando 1000 veces)...', value = 0, {
      
      permutest(reg_obj())
    })
  })
  
  # Se muestran los resultados de la prueba de permutación
  output$resumen_permut <- renderPrint({
    
    req(res_permut())
    
    res_permut()
  })
  
}
