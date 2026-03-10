#' Render a ggplot as a hand-drawn sketch
#'
#' @param plot A ggplot object.
#' @param width,height Plot size in inches.
#' @param roughness Rough.js roughness parameter.
#' @param bowing Rough.js bowing parameter.
#' @param fill_style Rough.js fill style.
#' @param seed Optional seed for deterministic randomness.
#' @param preserve_text Keep text unchanged.
#' @param font Path to a font file (.ttf, .otf, .woff, .woff2) to use for text
#'   labels. Defaults to the bundled Indie Flower handwritten font. Set to
#'   `NULL` to leave the plot's original fonts unchanged.
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
  preserve_text = TRUE,
  font = system.file("font/IndieFlower-Regular.ttf", package = "ggrough2")
) {
  if (!inherits(plot, "ggplot")) {
    stop("`plot` must be a ggplot object.", call. = FALSE)
  }
  if (!is.numeric(width) || width <= 0) {
    stop("`width` must be a positive number (inches).", call. = FALSE)
  }
  if (!is.numeric(height) || height <= 0) {
    stop("`height` must be a positive number (inches).", call. = FALSE)
  }

  font_data <- make_font_data(font)

  svg <- svglite::stringSVG(
    code = print(plot),
    width = width,
    height = height,
    standalone = TRUE
  )

  x <- list(
    svg = paste(svg, collapse = "\n"),
    font = font_data,
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

make_font_data <- function(font) {
  if (is.null(font) || !nzchar(font)) {
    return(NULL)
  }

  if (!is.character(font) || length(font) != 1) {
    stop("`font` must be a single file path or NULL.", call. = FALSE)
  }
  if (!file.exists(font)) {
    stop("`font` file not found: ", font, call. = FALSE)
  }

  ext <- tolower(tools::file_ext(font))
  mime <- switch(
    ext,
    ttf = "font/truetype",
    otf = "font/otf",
    woff = "font/woff",
    woff2 = "font/woff2",
    stop("`font` must be a .ttf, .otf, .woff, or .woff2 file.", call. = FALSE)
  )

  raw_bytes <- readBin(font, "raw", file.info(font)$size)
  b64 <- base64enc::base64encode(raw_bytes)

  list(
    name = tools::file_path_sans_ext(basename(font)),
    data_uri = paste0("data:", mime, ";base64,", b64)
  )
}

#' @export
print.ggrough2 <- function(x, ...) {
  NextMethod()
}
