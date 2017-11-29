
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

mentalModelsModUI <- function(id) {
  ns <- NS(id)
  DT::dataTableOutput(ns("table"))
}

mentalModelsMod <- function(input, output, session, fam) {
  output$table <- DT::renderDataTable({
    dat <- mental_models %>% filter(family %in% fam())
    DT::datatable(dat, options = list("pageLength" = 100))
  })
}