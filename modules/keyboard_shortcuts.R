
read_asset_html <- function(name, what, ...) {
  doc <- read_html(glue("assets/{name}.html"))
  do.call(glue("html_{what}"), list(x = doc, header = TRUE))[[1]]
}

ks <- list(
  inbox = read_asset_html("ks_inbox", "table"),
  rstudio = read_csv("assets/ks_rstudio.csv")
)

keyboarShortcutsModUI <- function(id, product, selected = NA) {
  ns <- NS(id)
  
  intro <- if (product == "rstudio") {
    tagList(
      span("From RStudio, click `Option + Shift + K` to access the shortcuts cheatsheet. Or click "),
      tags$a("here", href = "https://support.rstudio.com/hc/en-us/articles/200711853-Keyboard-Shortcuts")
    )
  } else if (product == "inbox") {
    span("From Inbox, click `Shift ?` to access the shortcuts cheatsheet")
  } else ""
  
  data <- ks[[product]]
  
  # select all by default
  if (is.na(selected)) selected <- unique(data[["where"]])
  
  tagList(
    intro,
    checkboxGroupInput(ns("where"), "Filter by area", inline = TRUE,
      unique(data[["where"]]), selected),
    tableOutput(ns("table"))
  )
}

keyboarShortcutsMod <- function(input, output, session, product) {
  
  output$table <- renderTable({
    ks[[product]] %>% 
      filter(where %in% input$where) %>% 
      select(description, key, where)
  }, hover = TRUE, striped = TRUE, spacing = "xs")
}
