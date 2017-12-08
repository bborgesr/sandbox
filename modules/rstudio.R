
# for "html tables a la rstudio::conf(2018)", see:
# https://beta.rstudioconnect.com/content/3105/

rstudio <- tibble(
  name = list("bash ninja", "html tables a la rstudio::conf(2018)",
    "flesh out google sheets as a backend for shiny app data",
    "look into shiny.collections",
    "pivot tables", "grable", "toolbars", "reactlog",
    "drill-down", "drill-through", "react + shiny", "d3 + shiny",
    "flex and shinydashboard theme", "revamp shinydashboard"),
  description = as.list(letters[1:length(name)]),
  links = as.list(letters[1:length(name)]),
  priority = as.list(letters[1:length(name)]),
  selected = rep(NA, length(name))
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