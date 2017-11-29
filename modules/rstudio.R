
rstudio <- tibble(
  name = list("bash ninja", "pivot tables", "grable", "toolbars", "reactlog",
    "drill-down", "drill-through", "react + shiny", "d3 + shiny",
    "flex and shinydashboard theme", "revamp shinydashboard"),
  description = as.list(letters[1:11]),
  links = as.list(letters[1:11]),
  priority = as.list(letters[1:11]),
  selected = rep(NA, 11)
)
  
rstudioModUI <- function(id) {
  ns <- NS(id)
  tagList(
    "List of work-inspired projects I'd like to do",
    checkboxGroupInput(ns("projects"), "Select the ones in progress", 
      unique(rstudio$name), unique(rstudio$selected)),
    DT::dataTableOutput(ns("table"))
  )
}

rstudioMod <- function(input, output, session) {}