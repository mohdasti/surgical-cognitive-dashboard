diagnosticsUI <- function(id) {
  ns <- NS(id)
  tabsetPanel(type="pills", id=ns("tabs"),
    tabPanel("Overview", fluidRow(
      column(6, gt::gt_output(ns("model_card"))),
      column(6, plotOutput(ns("feat_list"), height=280), verbatimTextOutput(ns("hyperparams")))
    )),
    tabPanel("Cross-Validation", fluidRow(
      column(6, plotOutput(ns("cm_agg"), height=320)),
      column(6, plotOutput(ns("pr_lapse"), height=320))),
      fluidRow(column(12, plotly::plotlyOutput(ns("per_class"), height=320)),
               column(12, DT::dataTableOutput(ns("loso_table"))))),
    tabPanel("Calibration", fluidRow(
      column(6, plotOutput(ns("reliability"), height=320)),
      column(6, gt::gt_output(ns("calib_stats")))),
      fluidRow(column(12, plotOutput(ns("prob_hist"), height=200)))),
    tabPanel("Threshold Sandbox",
      fluidRow(
        column(4, sliderInput(ns("theta_l"), "Lapse θ", 0,1,0.5,0.01),
                   sliderInput(ns("theta_h"), "High-load θ", 0,1,0.7,0.01)),
        column(8, plotOutput(ns("metrics_vs_th"), height=300),
                   plotOutput(ns("cm_at_th"), height=300))
      )
    ),
    tabPanel("Feature Importance", fluidRow(
      column(6, plotOutput(ns("xgb_imp"), height=320)),
      column(6, plotOutput(ns("shap_plot"), height=320)))),
    tabPanel("Partial Dependence",
      fluidRow(column(4, selectInput(ns("pd_feature"), "Feature", choices=NULL)),
               column(8, plotOutput(ns("pd_plot"), height=320))))
  )
}

diagnosticsServer <- function(id) {
  moduleServer(id, function(input, output, session) {
    ns <- session$ns
    eval <- readRDS("data/diagnostics/loso_eval.rds")
    mdl <- readRDS("data/diagnostics/model_artifacts.rds")

    output$model_card <- gt::render_gt({
      gt::gt(data.frame(
        Field=c("Model","Objective","Classes","Features"),
        Value=c("XGBoost + Platt + Isolation Forest","multi:softprob (XGB)",
                paste(CFG$labels, collapse=", "), length(mdl$feat_names))
      ))
    })
    output$feat_list <- renderPlot({
      tibble::tibble(feature = mdl$feat_names) |>
        ggplot2::ggplot(ggplot2::aes(y=reorder(feature, feature), x=1)) +
        ggplot2::geom_point() + ggplot2::labs(x=NULL, y=NULL, title="Features in use") +
        ggplot2::theme_minimal()
    })
    output$hyperparams <- renderText({ paste(capture.output(str(mdl$params)), collapse="\n") })
    output$cm_agg <- renderPlot({ eval$cm_plot })
    output$pr_lapse <- renderPlot({ eval$pr_lapse_plot })

    # Placeholder per-class bar (recompute quickly from confusion if needed)
    output$per_class <- plotly::renderPlotly({
      # Simple proxy: counts from confusion
      p <- eval$loso_df
      plotly::plot_ly(p, x=~holdout, y=~pr_auc, type='bar', name='PR-AUC (Lapse)') |>
        plotly::layout(title="LOSO PR-AUC by Holdout")
    })
    output$loso_table <- DT::renderDataTable({ eval$loso_df })

    # Calibration + histogram come from Prompt 12 (precompute)
    calib <- readRDS("data/diagnostics/calibration.rds")
    output$reliability <- renderPlot({ calib$calib_plot })
    output$calib_stats <- gt::render_gt({ calib$calib_stats_gt })
    output$prob_hist <- renderPlot({ calib$prob_hist_plot })

    # Threshold sandbox
    thresh <- readRDS("data/diagnostics/threshold_sandbox.rds")
    # Make data available in global scope for the function
    threshold_sandbox_data <<- thresh$data
    observeEvent(list(input$theta_l, input$theta_h), {
      res <- thresh$threshold_fun(input$theta_l, input$theta_h)
      output$metrics_vs_th <- renderPlot({ res$metrics_vs_threshold })
      output$cm_at_th      <- renderPlot({ res$cm_plot })
    }, ignoreInit=TRUE)

    # Feature importance & SHAP
    output$xgb_imp   <- renderPlot({ mdl$xgb_importance_plot })
    output$shap_plot <- renderPlot({ mdl$shap_global_plot })

    # PD
    observe({ updateSelectInput(session, "pd_feature", choices = mdl$feat_names, selected = mdl$feat_names[1]) })
    output$pd_plot <- renderPlot({ req(input$pd_feature); mdl$pd_plots[[input$pd_feature]] })
  })
}
