source("00_setup.R")
source("R/streaming_inference.R")
source("R/diagnostics_module.R")

# Minimal logging functions for standalone app
start_run <- function() {
  id <- format(Sys.time(), "%Y%m%d-%H%M%S")
  path <- file.path("data/logs", paste0("run-", id, ".csv"))
  list(id=id, path=path)
}
log_event <- function(run, t, final_state, lapse_p, high_prob, reasons) {
  line <- data.frame(ts=Sys.time(), t=t, state=final_state, lapse_p=lapse_p,
                     high_prob=high_prob, reasons=paste(reasons, collapse="; "))
  if (!dir.exists("data/logs")) dir.create("data/logs", recursive = TRUE)
  write.csv(line, run$path, append=file.exists(run$path), row.names=FALSE)
}
end_run <- function(run) invisible(run)

ui <- shiny::navbarPage(
  "Surgical Cognitive Dashboard",
  header = tags$head(tags$base(target="_parent")),
  tabPanel("Dashboard",
    fluidRow(
      column(3,
        checkboxInput("silent", "Silent mode (no alerts, just log)", FALSE),
        checkboxInput("enable_logging", "Enable event logging", FALSE),
        sliderInput("theta_lapse", "Lapse threshold", 0, 1, CFG$thresholds$alert_prob_lapse, 0.01),
        sliderInput("theta_high",  "High-load threshold", 0, 1, CFG$thresholds$alert_prob_highload, 0.01)
      ),
      column(9,
        uiOutput("hud"),
        DT::dataTableOutput("alertlog")
      )
    )
  ),
  tabPanel("ML Model Diagnostics", uiOutput("diagnostics"))
)

server <- function(input, output, session) {
  engine <- CogEngine$new(CFG)
  stream <- data.table::fread("data/processed/sim_stream.csv.gz")
  idx <- reactiveVal(1L)
  logdf <- reactiveVal(tibble::tibble(t=integer(), type=character(), reasons=character(),
                                      lapse_p=double(), high_prob=double()))
  
  # Logging setup
  run_logger <- reactiveVal(NULL)

  # thresholds live adjustment
  observe({
    CFG$thresholds$alert_prob_lapse <- input$theta_lapse
    CFG$thresholds$alert_prob_highload <- input$theta_high
  })

  output$hud <- renderUI({
    div(style="padding:12px;border:1px solid #eee;border-radius:12px",
        h4("Real-time Cognitive State Monitor"),
        verbatimTextOutput("hudtext"))
  })

  output$diagnostics <- renderUI({ diagnosticsUI("diag") })
  diagnosticsServer("diag")

  latency_series <- tibble::tibble(idx=numeric(), lat_ms=numeric())
  output$alertlog <- DT::renderDataTable({ logdf() })

  observe({
    invalidateLater(200, session) # 5 Hz
    i <- idx(); if (i>nrow(stream)) return()
    row <- as.list(stream[i,])

    engine$update(row)
    t0 <- proc.time()[["elapsed"]]; out <- engine$predict()
    lat <- (proc.time()[["elapsed"]] - t0)*1000

    latency_series <- dplyr::bind_rows(latency_series, tibble::tibble(idx=nrow(latency_series)+1, lat_ms=lat)) |> tail(500)
    if (!is.null(out)) {
      output$hudtext <- renderText({
        sprintf("t=%s | state=%s | lapse_p=%.3f | high=%.3f | reasons=%s",
                row$t, out$final_state, out$lapse_p, out$state_probs["High Load"],
                paste(out$reasons, collapse=", "))
      })
      
      # Log event if logging is enabled
      if (isTRUE(input$enable_logging)) {
        if (is.null(run_logger())) {
          # Start new run when logging is first enabled
          run_logger(start_run())
        }
        log_event(run_logger(), t=row$t, final_state=out$final_state, 
                 lapse_p=out$lapse_p, high_prob=out$state_probs["High Load"], 
                 reasons=out$reasons)
      }
      
      if (!isTRUE(input$silent) && (out$alert$lapse || out$alert$highload)) {
        logdf(bind_rows(logdf(), tibble::tibble(
          t=row$t,
          type=ifelse(out$alert$lapse, "LAPSE", ifelse(out$alert$highload,"HIGH","INFO")),
          reasons=paste(out$reasons, collapse="; "),
          lapse_p=out$lapse_p,
          high_prob=out$state_probs["High Load"]
        )))
      }
    }
    idx(i+1L)
  })
}

shinyApp(ui, server)
