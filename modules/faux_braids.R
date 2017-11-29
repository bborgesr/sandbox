
braidsModUI <- function(id) {
  ns <- NS(id)
  tagList(
    helpText("Faux braiding haristyles! Yay!"),
    hr(),
    tags$iframe(src = "https://www.youtube.com/embed/tWKZ6wg_bcg",
      frameborder = "0", allowfullscreen = NA, width = "560", height = "315"),
    tags$iframe(src = "https://www.youtube.com/embed/iZdNH12TWWs",
      frameborder = "0", allowfullscreen = NA, width = "560", height = "315"),
    tags$iframe(src = "https://www.youtube.com/embed/QqJKL5Ey7K8",
      frameborder = "0", allowfullscreen = NA, width = "560", height = "315")
  )
}

braidsMod <- function(input, output, session) {}