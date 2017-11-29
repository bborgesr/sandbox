library(dplyr)
library(readr)
library(rvest)
library(glue)
library(shiny)
library(shinydashboard)
library(pool)

file_sources = paste0("modules/", list.files(path = "./modules", pattern = "*.R"))
sapply(file_sources, source)

ui <- dashboardPage(skin = "yellow",
  dashboardHeader(title = "Bar Bar Bar"),
  dashboardSidebar(
    sidebarMenu(id = "tabs",
      menuItem("Home", tabName = "home", icon = icon("home")),
      menuItem("TODO", tabName = "todo", icon = icon("list-ul")),
      menuItem("Reading", tabName = "reading", icon = icon("book")),
      menuItem("Work projects bucketlist", tabName = "rstudio", icon = icon("snowflake-o")),
      menuItem("Reference", icon = icon("folder"), startExpanded = TRUE,
        menuSubItem("Keyboard shortcuts - RStudio", tabName = "ks_rstudio", icon = icon("keyboard-o")),
        menuSubItem("Keyboard shortcuts - Inbox", tabName = "ks_inbox", icon = icon("keyboard-o")),
        menuSubItem("Faux Braiding videos", tabName = "braids", icon = icon("youtube")),
        menuSubItem("Mental models table", tabName = "mental_models", icon = icon("database")),
        menuSubItem("timevis demos", tabName = "timevis", icon = icon("code")),
        menuSubItem("Parabéns", tabName = "parabens", icon = icon("glass"))
      )
    ),
    conditionalPanel("input.tabs == 'mental_models'", {
      selectInput("family", "Filter by family", unique(mental_models$family), 
        unique(mental_models$family), multiple = TRUE)
    })
  ),
  dashboardBody(
    includeCSS("assets/style.css"),
    tabItems(
      tabItem("home", homeModUI("home_module")),
      tabItem("todo", todoModUI("todo_module")),
      tabItem("reading", readingModUI("reading_module")),
      tabItem("rstudio", rstudioModUI("rstudio_module")),
      tabItem("ks_rstudio", keyboarShortcutsModUI("ks_rstudio_module", product = "rstudio", selected = "source")),
      tabItem("ks_inbox", keyboarShortcutsModUI("ks_inbox_module", product = "inbox")),
      tabItem("braids", braidsModUI("braids_module")),
      tabItem("mental_models", helpText("Mental models datatable"), mentalModelsModUI("mental_models_module")),
      tabItem("timevis", timevisModUI("timevis_modules")),
      tabItem("parabens", parabensModUI("parabens_module"))
    )
  )
)

server <- function(input, output, session) {
  
  callModule(keyboarShortcutsMod, "ks_rstudio_module", product = "rstudio")
  callModule(keyboarShortcutsMod, "ks_inbox_module", product = "inbox")
  callModule(mentalModelsMod, "mental_models_module", fam = reactive(input$family))
}

shinyApp(ui, server)
