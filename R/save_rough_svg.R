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

# For a true save_rough_svg(), you would later add a headless browser step with chromote or webshot2 that reads the transformed DOM and writes out the resulting <svg>.
