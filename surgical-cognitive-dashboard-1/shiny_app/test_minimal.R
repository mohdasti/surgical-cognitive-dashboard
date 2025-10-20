# Minimal test app to isolate reactive issue
library(shiny)

ui <- fluidPage(
  titlePanel("Minimal Reactive Test"),
  
  mainPanel(
    h3("Static Test: This should always show"),
    p("REACTIVE TEST:", textOutput("test_output", inline = TRUE)),
    p("Counter:", textOutput("counter_output", inline = TRUE))
  )
)

server <- function(input, output, session) {
  
  # Simple counter
  counter <- reactiveVal(0)
  
  # Update counter every second
  observe({
    invalidateLater(1000, session)
    counter(counter() + 1)
  })
  
  # Test outputs
  output$test_output <- renderText({
    format(Sys.time(), "%H:%M:%S")
  })
  
  output$counter_output <- renderText({
    counter()
  })
}

shinyApp(ui = ui, server = server)