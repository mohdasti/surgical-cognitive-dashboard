library(shiny)
library(plotly)
library(DT)

ui <- fluidPage(
  titlePanel("🧠 Surgical Cognitive Dashboard - Minimal"),
  sidebarLayout(
    sidebarPanel(
      h4("Control Panel"),
      checkboxInput("silent", "Silent mode", FALSE),
      sliderInput("theta_lapse", "Lapse threshold", 0, 1, 0.3, 0.01)
    ),
    mainPanel(
      h4("Status"),
      verbatimTextOutput("status"),
      h4("Real-time Data"),
      plotlyOutput("pupil_plot", height = "300px"),
      h4("Alert Log"),
      DT::dataTableOutput("alertlog")
    )
  )
)

server <- function(input, output, session) {
  # Simple reactive values
  idx <- reactiveVal(1L)
  logdf <- reactiveVal(data.frame(
    t = integer(),
    type = character(),
    lapse_p = double()
  ))
  
  realtime_data <- reactiveVal(data.frame(
    timestamp = numeric(),
    pupil_diameter = numeric(),
    lapse_prob = numeric()
  ))
  
  # Status output
  output$status <- renderText({
    current_data <- realtime_data()
    if (nrow(current_data) == 0) {
      "Initializing..."
    } else {
      latest <- tail(current_data, 1)
      sprintf("Time: %.1f | Pupil: %.2f mm | Lapse Prob: %.3f", 
              latest$timestamp, latest$pupil_diameter, latest$lapse_prob)
    }
  })
  
  # Simple pupil plot
  output$pupil_plot <- renderPlotly({
    current_data <- realtime_data()
    if (nrow(current_data) == 0) {
      return(plotly_empty())
    }
    
    plot_ly(current_data, x = ~timestamp, y = ~pupil_diameter,
            type = 'scatter', mode = 'lines+markers') %>%
      layout(title = "Pupil Diameter", xaxis = list(title = "Time"))
  })
  
  # Alert log
  output$alertlog <- DT::renderDataTable({
    logdf()
  })
  
  # Simple simulation loop
  observe({
    invalidateLater(500, session) # 2 Hz update rate
    
    i <- idx()
    if (i > 1000) return() # Stop after 1000 iterations
    
    # Simulate some data
    t <- i * 0.5
    pupil_diameter <- 4.5 + 0.5 * sin(t/10) + rnorm(1, 0, 0.1)
    lapse_prob <- max(0, min(1, 0.1 + 0.3 * sin(t/20) + rnorm(1, 0, 0.05)))
    
    # Update real-time data
    new_row <- data.frame(
      timestamp = t,
      pupil_diameter = pupil_diameter,
      lapse_prob = lapse_prob
    )
    
    current_data <- realtime_data()
    updated_data <- rbind(current_data, new_row)
    if (nrow(updated_data) > 200) {
      updated_data <- tail(updated_data, 200)
    }
    realtime_data(updated_data)
    
    # Add to alert log if lapse probability is high
    if (lapse_prob > input$theta_lapse && !input$silent) {
      new_alert <- data.frame(
        t = t,
        type = "LAPSE",
        lapse_p = lapse_prob
      )
      
      current_log <- logdf()
      updated_log <- rbind(current_log, new_alert)
      logdf(updated_log)
    }
    
    idx(i + 1L)
  })
}

shinyApp(ui, server)
