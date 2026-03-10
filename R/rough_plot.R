#' Render a ggplot as a hand-drawn sketch
#'
#' @param plot A ggplot object.
#' @param width,height Plot size in inches.
#' @param roughness Rough.js roughness parameter.
#' @param bowing Rough.js bowing parameter.
#' @param fill_style Rough.js fill style.
#' @param seed Optional seed for deterministic randomness.
#' @param preserve_text Keep text unchanged.
#'
#' @return An htmlwidget.
#' @export
rough_plot <- function(
  plot,
  width = 7,
  height = 5,
  roughness = 1.5,
  bowing = 1,
  fill_style = "hachure",
  seed = NULL,
  preserve_text = TRUE
) {
  if (!inherits(plot, "ggplot")) stop("`plot` must be a ggplot object.", call. = FALSE)
  if (!is.numeric(width) || width <= 0)  stop("`width` must be a positive number (inches).", call. = FALSE)
  if (!is.numeric(height) || height <= 0) stop("`height` must be a positive number (inches).", call. = FALSE)

  svg <- svglite::stringSVG(
    code = print(plot),
    width = width,
    height = height,
    standalone = TRUE
  )

  x <- list(
    svg = paste(svg, collapse = "\n"),
    options = validate_rough_options(
      roughness = roughness,
      bowing = bowing,
      fill_style = fill_style,
      seed = seed,
      preserve_text = preserve_text
    )
  )

  htmlwidgets::createWidget(
    name = "ggrough2",
    x = x,
    width = NULL,
    height = NULL,
    package = "ggrough2"
  )
}

#' @export
print.ggrough2 <- function(x, ...) {
  htmlwidgets::print.htmlwidget(x, ...)
}
