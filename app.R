library(dplyr)
library(readr)
library(rvest)
library(glue)
library(shiny)
library(shinydashboard)

read_asset_html <- function(name, what, ...) {
  doc <- read_html(glue("assets/{name}.html"))
  do.call(glue("html_{what}"), list(x = doc, header = TRUE))[[1]]
}

ks <- list(
  inbox = read_asset_html("ks_inbox", "table")
)

mental_models <- read_csv("assets/mental_models.csv") %>% 
  select(-X1, -X5, -X6, -X7) %>%
  rename(family = X2, model = `Mental Model`, description = Description)

familify <- function(data, row, prev_family, isNamed) {
  if (row == nrow(data)) return(data)
  if (isNamed) {
    family <- data[[row, "family"]]
    familify(data, row + 1, family, FALSE)
  } else {
    data[[row, "family"]] <- prev_family
    if (row <= nrow(data) - 1) {
      nxt_family <- data[[row + 1, "family"]]
      if (is.na(nxt_family)) familify(data, row + 1, prev_family, FALSE)
      else familify(data, row + 1, NA, TRUE)
    } else {
      next
    }
  }
}

mental_models <- familify(mental_models, row = 1, prev_family = NA, isNamed = TRUE)

ui <- dashboardPage(skin = "yellow",
  dashboardHeader(title = "Bar Bar Bar"),
  dashboardSidebar(
    sidebarMenu(id = "tabs",
      menuItem("Home", tabName = "home", icon = icon("home")),
      menuItem("Reference", icon = icon("book"), startExpanded = TRUE,
        menuSubItem("Keyboard shortcuts - Inbox", 
          tabName = "ks_inbox", selected = TRUE),
        menuSubItem("Faux Braiding videos", 
          tabName = "faux_braids"),
        menuSubItem("Mental models table", 
          tabName = "mental_models"),
        menuSubItem("parabens", tabName = "parabens")
      )
    ),
    conditionalPanel("input.tabs == 'mental_models'", {
      selectInput("family", "Filter by family", unique(mental_models$family), 
        unique(mental_models$family), multiple = TRUE)
    })
  ),
  dashboardBody(
    tabItems(
      tabItem("home", "Welcome home, Bárbara"),
      tabItem("ks_inbox", 
        helpText("From Inbox, click `Shift ?` to access shortcuts cheatsheet"),
        hr(),
        checkboxGroupInput("where", "Filter by area", inline = TRUE,
          unique(ks$inbox$where), selected = unique(ks$inbox$where)),
        tableOutput("reference_table")
      ),
      tabItem("faux_braids", 
        helpText("Faux braiding haristyles! Yay!"),
        hr(),
        tags$iframe(
          src = "https://www.youtube.com/embed/tWKZ6wg_bcg",
          frameborder = "0", allowfullscreen = NA, width = "560", height = "315"
        ),
        tags$iframe(
          src = "https://www.youtube.com/embed/iZdNH12TWWs",
          frameborder = "0", allowfullscreen = NA, width = "560", height = "315"
        ),
        tags$iframe(
          src = "https://www.youtube.com/embed/QqJKL5Ey7K8",
          frameborder = "0", allowfullscreen = NA, width = "560", height = "315"
        )
      ), tabItem("mental_models", 
        helpText("Mental mondels datatable"),
        DT::dataTableOutput("mental_models")
      ),
      tabItem("parabens", 
        helpText("Para festas de aniversásrio"),
        hr(),
        p("Parabéns a você"),
        p("Nesta data querida"),
        p("Muitas felicidades"),
        p("Muitos anos de vida"),
        br(),
        p("Hoje é dia de festa"),
        p("Cantam as nossas almas"),
        p("Para o(a) menino(a) ..."),
        p("Uma salva de palmas!"),
        br(),
        p("Ele(a) hoje faz anos"),
        p("Porque Deus assim quis"),
        p("O que nós desejamos"),
        p("É que seja feliz!"),
        br(),
        p("Tenha tudo de bom"),
        p("Do que a vida contém"),
        p("Tenha muita saúde"),
        p("E amigos também")
      )
    )
  )
)

server <- function(input, output, session) {
  output$reference_table <- renderTable({
    ks$inbox %>% 
      filter(where %in% input$where) %>% 
      select(description, key, where)
  }, hover = TRUE, striped = TRUE, spacing = "xs")
  
  output$mental_models <- DT::renderDataTable({
    mental_models %>% filter(family %in% input$family)
  })
}

shinyApp(ui, server)
