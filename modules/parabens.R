
parabensModUI <- function(id) {
  ns <- NS(id)
  tagList(
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
}

parabensMod <- function(input, output, session) {}