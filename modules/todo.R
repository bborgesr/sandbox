
todoModUI <- function(id) {
  ns <- NS(id)
  tagList(
    "Use Joe's", tags$a("Shiny app", href = "https://github.com/jcheng5/shiny-todo")
  )
}

todoMod <- function(input, output, session) {}