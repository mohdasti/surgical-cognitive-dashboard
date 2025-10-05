# Simplified Shiny app for deployment
library(shiny)
library(yaml)
library(tidyverse)
library(data.table)
library(DT)

# Load configuration
CFG <- yaml::read_yaml("config/config.yml")

# Simple UI
ui <- fluidPage(
  titlePanel("Surgical Cognitive Dashboard"),
  sidebarLayout(
    sidebarPanel(
      h4("Controls"),
      checkboxInput("silent", "Silent mode", FALSE),
      sliderInput("theta_lapse", "Lapse threshold", 0, 1, 0.7, 0.01),
      sliderInput("theta_high", "High-load threshold", 0, 1, 0.8, 0.01),
      br(),
      h4("Status"),
      verbatimTextOutput("status")
    ),
    mainPanel(
      h3("Real-time Cognitive State Monitor"),
      div(id = "hud", 
        style = "padding: 20px; border: 2px solid #ddd; border-radius: 10px; margin: 10px 0;",
        h4("Current State: ", textOutput("current_state", inline = TRUE)),
        p("Last Update: ", textOutput("last_update", inline = TRUE))
      ),
      h4("Alert Log"),
      DT::dataTableOutput("alertlog")
    )
  )
)

# Simple server
server <- function(input, output, session) {
  # Reactive values
  current_state <- reactiveVal("Normal")
  alert_log <- reactiveVal(data.frame(
    timestamp = character(0),
    event = character(0),
    probability = numeric(0),
    stringsAsFactors = FALSE
  ))
  
  # Simulate data stream
  observe({
    invalidateLater(1000) # Update every second
    
    # Generate random state
    states <- c("Normal", "High Load", "Attentional Lapse", "Low Load")
    new_state <- sample(states, 1, prob = c(0.6, 0.2, 0.1, 0.1))
    current_state(new_state)
    
    # Check for alerts
    if (!input$silent) {
      if (new_state == "Attentional Lapse" && runif(1) > 0.7) {
        new_alert <- data.frame(
          timestamp = format(Sys.time(), "%H:%M:%S"),
          event = "⚠️ ATTENTIONAL LAPSE DETECTED",
          probability = round(runif(1, 0.7, 0.95), 3),
          stringsAsFactors = FALSE
        )
        alert_log(rbind(alert_log(), new_alert))
      }
      
      if (new_state == "High Load" && runif(1) > 0.8) {
        new_alert <- data.frame(
          timestamp = format(Sys.time(), "%H:%M:%S"),
          event = "🔴 HIGH COGNITIVE LOAD",
          probability = round(runif(1, 0.8, 0.95), 3),
          stringsAsFactors = FALSE
        )
        alert_log(rbind(alert_log(), new_alert))
      }
    }
  })
  
  # Outputs
  output$current_state <- renderText(current_state())
  output$last_update <- renderText(format(Sys.time(), "%H:%M:%S"))
  
  output$status <- renderText({
    paste("App running successfully\n",
          "Thresholds: Lapse=", input$theta_lapse, 
          ", High=", input$theta_high)
  })
  
  output$alertlog <- DT::renderDataTable({
    DT::datatable(alert_log(), 
      options = list(pageLength = 10, dom = 't'),
      rownames = FALSE
    )
  })
}

# Run the app
shinyApp(ui = ui, server = server)
