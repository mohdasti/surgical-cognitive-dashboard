library(shiny)

ui <- fluidPage(
  tags$head(
    tags$style(HTML("
      /* KILL ALL OPACITY SOURCES */
      body, .container-fluid, * { opacity: 1 !important; }
      .recalculating { opacity: 1 !important; }
      .shiny-busy { opacity: 1 !important; }
    "))
  ),
  
  h1("Minimal Opacity Test"),
  p("If this text is opaque/faded, the issue is external to our code."),
  p("If this is CLEAR, then our modules are causing it."),
  
  h3(textOutput("counter")),
  p("Counter updates every 200ms to simulate 5Hz")
)

server <- function(input, output, session) {
  count <- reactiveVal(0)
  
  observe({
    invalidateLater(200, session)
    count(count() + 1)
  })
  
  output$counter <- renderText({
    paste("Count:", count())
  })
}

shinyApp(ui, server)

