#' Save a roughened plot as HTML
#'
#' @param plot A ggplot object.
#' @param file Output HTML file.
#' @param ... Passed to rough_plot().
#'
#' @export
save_rough_html <- function(plot, file, ...) {
  w <- rough_plot(plot, ...)
  htmlwidgets::saveWidget(w, file = file, selfcontained = TRUE)
  invisible(file)
}
