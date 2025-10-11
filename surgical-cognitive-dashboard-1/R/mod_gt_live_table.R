suppressPackageStartupMessages({
  library(shiny)
  library(dplyr)
  library(tidyr)
  library(purrr)
  library(gt)
})

gt_live_table_ui <- function(id, title = "Real-time Feature Monitor") {
  ns <- NS(id)
  tagList(
    h3(title, class = "mt-2 mb-2"),
    gt::gt_output(ns("tbl"))
  )
}

gt_live_table_server <- function(id, features_reactive, trends_reactive = NULL, params_reactive = NULL, personal_reactive = NULL, refs_path = "data/reference_ranges.csv") {
  moduleServer(id, function(input, output, session) {

    refs <- reactive({
      params <- if (is.null(params_reactive)) NULL else params_reactive()
      load_reference_ranges(params = params, path = refs_path)
    })

    features_now <- reactive({
      # Expect features_reactive() to return a tibble with cols:
      # Feature, Value, Unit, and optional Trend list-col or we can join from trends_reactive()
      df <- features_reactive()
      
      # Simple validation
      req(df)
      if (!is.data.frame(df) || nrow(df) == 0) {
        return(tibble::tibble(
          Feature = character(),
          Value = numeric(),
          Unit = character(),
          Trend = list()
        ))
      }

      if (!"Trend" %in% names(df)) {
        if (!is.null(trends_reactive)) {
          tr <- try(trends_reactive(), silent = TRUE)
          if (!inherits(tr, "try-error") && is.data.frame(tr) && 
              "Feature" %in% names(tr) && "Trend" %in% names(tr)) {
            df <- df %>% left_join(tr, by = "Feature")
          } else {
            df$Trend <- replicate(nrow(df), numeric(0), simplify = FALSE)
          }
        } else {
          df$Trend <- replicate(nrow(df), numeric(0), simplify = FALSE)
        }
      }
      df
    })

    output$tbl <- gt::render_gt({
      df <- features_now()
      
      # Show a loading message if no data yet
      if (nrow(df) == 0) {
        return(
          gt(tibble::tibble(Status = "⏳ Loading features...")) %>%
            tab_options(
              table.font.size = px(14),
              table.width = pct(100)
            )
        )
      }
      
      build_features_gt(
        df,
        refs = refs(),
        personal = if (is.null(personal_reactive)) NULL else personal_reactive()
      )
    })
  })
}

