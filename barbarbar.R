#  Links of interest:
#  In addition to the ones saved to Inbox, in Evernote, etc, these should also be easily available/rememberable somewhere in here:
#  (just hyperlink to everything!)
#  
#  MISC
#    * https://github.com/bborgesr/sandbox   # overdue items (tabs explainer, pool updates for shiny website) and conf talk thinking
#    * https://github.com/agrou/nutrient_pt  # look over Andreia's code and give her my thoughts
#    * http://rmarkdown.rstudio.com/flexdashboard/using.html          #  need to read this
#    * http://rmarkdown.rstudio.com/authoring_shiny_prerendered.html  #  need to read this
#    * http://adventofcode.com/   # a series of small programming puzzles for a variety of skill levels. interesting?
#    * https://support.rstudio.com/hc/en-us/articles/231874748-Scaling-and-Performance-Tuning-in-RStudio-Connect
#    * https://github.com/rstudio/shiny/issues/1855#issuecomment-330928043
#    * https://support.rstudio.com/hc/en-us/articles/200486138-Using-Different-Versions-of-R
#    * https://cran.r-project.org/doc/manuals/r-release/R-admin.html#Multiple-versions
#    
#  RSTUDIO::CONF
#    * https://www.rstudio.com/conference/           # main website
#    * https://beta.rstudioconnect.com/content/3105/ # schedule
#    
#  TIME MANAGEMENT
#    * https://www.rescuetime.com/dashboard
#    * https://achiever.rstudio.com/users/77
#    * https://app.asana.com/-/login
#    * https://www.etoro.com/portfolio
#    * http://economist.com/
#    
#  COMM   
#    * https://www.facebook.com/messages
#    * https://hangouts.google.com/
#    * https://web.whatsapp.com/
#    
#  VARIOUS GITHUB REPOS AND MY GIST ACCOUNT


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
