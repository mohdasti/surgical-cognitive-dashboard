library(shiny)
library(plotly)

ui <- fluidPage(
  tags$head(
    tags$style(HTML("
      /* KILL OPACITY - same CSS from main app */
      body, .container-fluid, * { opacity: 1 !important; }
      .recalculating { opacity: 1 !important; }
      .recalculating::after { display: none !important; }
      .shiny-busy { opacity: 1 !important; }
    "))
  ),
  
  h2("Minimal Opacity Test"),
  p("This page should NEVER go opaque."),
  textOutput("status"),
  plotlyOutput("test_plot")
)

server <- function(input, output, session) {
  data <- reactiveVal(data.frame(x = 1:10, y = rnorm(10)))
  
  observe({
    invalidateLater(1000)
    new_data <- data.frame(x = 1:10, y = rnorm(10))
    data(new_data)
  })
  
  output$status <- renderText({
    paste("Data updated at:", Sys.time())
  })
  
  output$test_plot <- renderPlotly({
    plot_ly(data(), x = ~x, y = ~y, type = 'scatter', mode = 'lines')
  })
}

shinyApp(ui, server)


