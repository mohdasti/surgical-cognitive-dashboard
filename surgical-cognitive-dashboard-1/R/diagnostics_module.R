# Source MD theme if available
if (file.exists("R/theme_md.R")) {
  source("R/theme_md.R")
} else if (file.exists("../R/theme_md.R")) {
  source("../R/theme_md.R")
}

diagnosticsUI <- function(id) {
  ns <- NS(id)
  tagList(
    h2("🤖 ML Model Diagnostics"),
    tabsetPanel(
      tabPanel("📊 Overview",
        fluidRow(
          column(6,
            h4("Model Card"),
            gt::gt_output(ns("model_card")),
            h4("Feature List"),
            plotOutput(ns("feature_list"), height = 300)
          ),
          column(6,
            h4("Hyperparameters"),
            verbatimTextOutput(ns("hyperparams")),
            h4("Model Performance Summary"),
            gt::gt_output(ns("performance_summary"))
          )
        )
      ),
      
      tabPanel("🔄 Cross-Validation",
        fluidRow(
          column(6,
            h4("Aggregated Confusion Matrix"),
            plotOutput(ns("cm_aggregated"), height = 400)
          ),
          column(6,
            h4("Precision-Recall for Lapse Detection"),
            plotOutput(ns("pr_lapse"), height = 400)
          )
        ),
        fluidRow(
          column(12,
            h4("Per-Class Performance"),
            plotly::plotlyOutput(ns("per_class_performance"), height = 400)
          )
        ),
        fluidRow(
          column(12,
            h4("LOSO Cross-Validation Results"),
            DT::dataTableOutput(ns("loso_table"))
          )
        )
      ),
      
      tabPanel("🎯 Calibration",
        fluidRow(
          column(6,
            h4("Reliability Plot"),
            plotOutput(ns("reliability_plot"), height = 400)
          ),
          column(6,
            h4("Calibration Statistics"),
            gt::gt_output(ns("calibration_stats"))
          )
        ),
        fluidRow(
          column(12,
            h4("Probability Histogram"),
            plotOutput(ns("probability_histogram"), height = 300)
          )
        )
      ),
      
      tabPanel("⚙️ Threshold Sandbox",
        fluidRow(
          column(4,
            h4("Threshold Controls"),
            sliderInput(ns("theta_lapse"), "Lapse Threshold (θ)", 
                       0, 1, 0.3, 0.01),
            sliderInput(ns("theta_highload"), "High-Load Threshold (θ)", 
                       0, 1, 0.6, 0.01),
            hr(),
            h5("Current Metrics:"),
            verbatimTextOutput(ns("current_metrics"))
          ),
          column(8,
            h4("Precision/Recall vs Threshold"),
            plotOutput(ns("metrics_vs_threshold"), height = 300),
            h4("Confusion Matrix at Current Threshold"),
            plotOutput(ns("confusion_at_threshold"), height = 300)
          )
        )
      ),
      
      tabPanel("🔍 Feature Importance",
        fluidRow(
          column(6,
            h4("XGBoost Feature Importance"),
            plotOutput(ns("xgb_importance"), height = 400)
          ),
          column(6,
            h4("SHAP Global Importance"),
            plotOutput(ns("shap_global"), height = 400)
          )
        )
      ),
      
      tabPanel("📈 Partial Dependence",
        fluidRow(
          column(3,
            h4("Feature Selection"),
            selectInput(ns("pd_feature"), "Choose Feature:",
                       choices = NULL),
            hr(),
            h5("Feature Description:"),
            verbatimTextOutput(ns("feature_description"))
          ),
          column(9,
            h4("Partial Dependence Plot"),
            plotOutput(ns("pd_plot"), height = 400)
          )
        )
      )
    )
  )
}

diagnosticsServer <- function(id, calibration_data = NULL, loso_eval = NULL, 
                              model_artifacts = NULL, threshold_sandbox = NULL) {
  moduleServer(id, function(input, output, session) {
    ns <- session$ns
    
    # Load data if not provided
    if (is.null(calibration_data)) {
      calibration_data <- readRDS("data/diagnostics/calibration.rds")
    }
    if (is.null(loso_eval)) {
      loso_eval <- readRDS("data/diagnostics/loso_eval.rds")
    }
    if (is.null(model_artifacts)) {
      model_artifacts <- readRDS("data/diagnostics/model_artifacts.rds")
    }
    if (is.null(threshold_sandbox)) {
      threshold_sandbox <- readRDS("data/diagnostics/threshold_sandbox.rds")
    }
    
    # Model Card
    output$model_card <- gt::render_gt({
      gt::gt(data.frame(
        Field = c("Model Type", "Objective", "Classes", "Features", "Training Samples"),
        Value = c("XGBoost + Platt Scaling + Isolation Forest",
                 "multi:softprob (XGBoost)",
                 paste(CFG$labels, collapse = ", "),
                 length(model_artifacts$feat_names),
                 "Simulated (1000+ samples)")
      )) %>%
        gt::tab_header(title = "Model Information")
    })
    
    # Feature List
    output$feature_list <- renderPlot({
      if (!is.null(model_artifacts$feat_names)) {
        tibble::tibble(feature = model_artifacts$feat_names) %>%
          ggplot2::ggplot(ggplot2::aes(y = reorder(feature, feature), x = 1)) +
          ggplot2::geom_point(size = 3, color = "#3498db") +
          ggplot2::labs(x = NULL, y = NULL, title = "Features in Use") +
          ggplot2::theme_minimal() + theme_md() +
          ggplot2::theme(axis.text.x = element_blank(),
                        panel.grid.major.x = element_blank())
      }
    })
    
    # Hyperparameters
    output$hyperparams <- renderText({
      if (!is.null(model_artifacts$params)) {
        paste(capture.output(str(model_artifacts$params)), collapse = "\n")
      } else {
        "Hyperparameters not available"
      }
    })
    
    # Performance Summary
    output$performance_summary <- gt::render_gt({
      if (!is.null(loso_eval$loso_df)) {
        avg_pr_auc <- mean(loso_eval$loso_df$pr_auc, na.rm = TRUE)
        sd_pr_auc <- sd(loso_eval$loso_df$pr_auc, na.rm = TRUE)
        
        gt::gt(data.frame(
          Metric = c("Average PR-AUC", "Std Dev PR-AUC", "Best Surgeon", "Worst Surgeon"),
          Value = c(
            sprintf("%.3f", avg_pr_auc),
            sprintf("%.3f", sd_pr_auc),
            loso_eval$loso_df$holdout[which.max(loso_eval$loso_df$pr_auc)],
            loso_eval$loso_df$holdout[which.min(loso_eval$loso_df$pr_auc)]
          )
        )) %>%
          gt::tab_header(title = "Cross-Validation Summary")
      }
    })
    
    # Confusion Matrix
    output$cm_aggregated <- renderPlot({
      if (!is.null(loso_eval$cm_plot)) {
        loso_eval$cm_plot
      }
    })
    
    # PR Curve for Lapse
    output$pr_lapse <- renderPlot({
      if (!is.null(loso_eval$pr_lapse_plot)) {
        loso_eval$pr_lapse_plot
      }
    })
    
    # Per-class Performance
    output$per_class_performance <- plotly::renderPlotly({
      if (!is.null(loso_eval$loso_df)) {
        plotly::plot_ly(loso_eval$loso_df, 
                       x = ~holdout, 
                       y = ~pr_auc,
                       type = 'bar',
                       marker = list(color = '#3498db'),
                       name = 'PR-AUC') %>%
          plotly::layout(title = "LOSO PR-AUC by Holdout Surgeon",
                        xaxis = list(title = "Holdout Surgeon"),
                        yaxis = list(title = "PR-AUC"))
      }
    })
    
    # LOSO Table
    output$loso_table <- DT::renderDataTable({
      if (!is.null(loso_eval$loso_df)) {
        DT::datatable(loso_eval$loso_df, 
                     options = list(pageLength = 10, dom = 't'))
      }
    })
    
    # Calibration Plots
    output$reliability_plot <- renderPlot({
      if (!is.null(calibration_data$calib_plot)) {
        calibration_data$calib_plot
      }
    })
    
    output$calibration_stats <- gt::render_gt({
      if (!is.null(calibration_data$calib_stats_gt)) {
        calibration_data$calib_stats_gt
      }
    })
    
    output$probability_histogram <- renderPlot({
      if (!is.null(calibration_data$prob_hist_plot)) {
        calibration_data$prob_hist_plot
      }
    })
    
    # Threshold Sandbox
    if (!is.null(threshold_sandbox)) {
      # Make data available globally for the threshold function
      threshold_sandbox_data <<- threshold_sandbox$data
      
      observeEvent(list(input$theta_lapse, input$theta_highload), {
        res <- threshold_sandbox$threshold_fun(input$theta_lapse, input$theta_highload)
        output$metrics_vs_threshold <- renderPlot({ res$metrics_vs_threshold })
        output$confusion_at_threshold <- renderPlot({ res$cm_plot })
        
        # Update current metrics
        output$current_metrics <- renderText({
          sprintf("Lapse Threshold: %.2f\nHigh-Load Threshold: %.2f\n\nMetrics updated in real-time",
                 input$theta_lapse, input$theta_highload)
        })
      }, ignoreInit = TRUE)
    }
    
    # Feature Importance
    output$xgb_importance <- renderPlot({
      if (!is.null(model_artifacts$xgb_importance_plot)) {
        model_artifacts$xgb_importance_plot
      }
    })
    
    output$shap_global <- renderPlot({
      if (!is.null(model_artifacts$shap_global_plot)) {
        model_artifacts$shap_global_plot
      }
    })
    
    # Partial Dependence
    observe({
      if (!is.null(model_artifacts$feat_names)) {
        updateSelectInput(session, "pd_feature", 
                         choices = model_artifacts$feat_names,
                         selected = model_artifacts$feat_names[1])
      }
    })
    
    output$pd_plot <- renderPlot({
      req(input$pd_feature)
      if (!is.null(model_artifacts$pd_plots) && 
          input$pd_feature %in% names(model_artifacts$pd_plots)) {
        model_artifacts$pd_plots[[input$pd_feature]]
      }
    })
    
    output$feature_description <- renderText({
      req(input$pd_feature)
      feature_descriptions <- list(
        "tonic_pupil_30s" = "Average pupil diameter over 30 seconds. Indicates baseline arousal level.",
        "phasic_pupil_change_5s" = "Change in pupil diameter from baseline over 5 seconds. Indicates phasic arousal response.",
        "grip_force_var_15s" = "Variability in grip force over 15 seconds. High variability may indicate fatigue or stress.",
        "tremor_mean_10s" = "Average tremor amplitude over 10 seconds. Higher values may indicate motor control issues.",
        "blink_rate_60s" = "Number of blinks per minute. Changes may indicate cognitive load or fatigue.",
        "tool_switch_rate_120s" = "Number of tool switches per 2 minutes. Frequent switching may indicate uncertainty.",
        "noise_mean_60s" = "Average ambient noise level over 1 minute. High noise may increase cognitive load.",
        "noise_spike_count_60s" = "Number of noise spikes over 1 minute. Sudden noise changes can be distracting."
      )
      
      if (input$pd_feature %in% names(feature_descriptions)) {
        feature_descriptions[[input$pd_feature]]
      } else {
        "Feature description not available."
      }
    })
  })
}