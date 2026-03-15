#' Render a ggplot as a hand-drawn sketch
#'
#' @param plot A ggplot object.
#' @param width,height Plot size in inches.
#' @param roughness Rough.js roughness parameter.
#' @param bowing Rough.js bowing parameter.
#' @param fill_style Rough.js fill style for data elements (geoms).
#' @param bg_fill_style Rough.js fill style for background elements (panel/plot
#'   backgrounds). Defaults to `"solid"`. Use the same value as `fill_style` to
#'   apply a uniform style to everything.
#' @param seed Optional seed for deterministic randomness.
#' @param preserve_text Keep text unchanged.
#' @param font Font family name to use for text labels, or `NULL` to leave the
#'   plot's original fonts unchanged. Defaults to `"IndieFlower"`, the bundled
#'   hand-drawn font. Any system font name (e.g. `"Arial"`) works directly.
#'   For Google Fonts, first call [add_google_font()].
#' @param options A list of additional Rough.js drawing options, typically
#'   created with [rough_options()]. Controls parameters such as
#'   `fill_weight`, `hachure_angle`, `hachure_gap`, `simplification`, etc.
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
  bg_fill_style = "solid",
  seed = NULL,
  preserve_text = TRUE,
  font = "IndieFlower",
  options = rough_options()
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

  font_data <- resolve_font(font)

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
      bg_fill_style = bg_fill_style,
      seed = seed,
      preserve_text = preserve_text,
      options = options
    )
  )

  htmlwidgets::createWidget(
    name = "ggrough2",
    x = x,
    width = width * 96,
    height = height * 96,
    package = "ggrough2"
  )
}

resolve_font <- function(family) {
  if (is.null(family)) {
    return(NULL)
  }

  if (!is.character(family) || length(family) != 1) {
    stop("`font` must be a single font family name or NULL.", call. = FALSE)
  }

  # Bundled IndieFlower
  if (identical(family, "IndieFlower") || identical(family, "Indie Flower")) {
    path <- system.file("font/IndieFlower-Regular.ttf", package = "ggrough2")
    return(encode_font(path, "IndieFlower"))
  }

  cache_dir <- tools::R_user_dir("ggrough2", "cache")
  safe <- gsub("[^A-Za-z0-9_-]", "_", family)
  cached <- list.files(
    cache_dir,
    pattern = paste0("^", safe, "\\.(ttf|otf|woff2?)$"),
    full.names = TRUE,
    ignore.case = TRUE
  )
  if (length(cached)) {
    return(encode_font(cached[1], family))
  }

  if (!requireNamespace("systemfonts", quietly = TRUE)) {
    stop(
      "Package 'systemfonts' is required for font name lookup. ",
      "Install with: install.packages('systemfonts')",
      call. = FALSE
    )
  }
  info <- systemfonts::font_info(family = family, italic = FALSE, bold = FALSE)
  path <- info$path[1]

  if (!is.na(path) && nzchar(path) && file.exists(path)) {
    return(encode_font(path, family))
  }

  list(name = family, data_uri = NULL)
}

encode_font <- function(path, name) {
  ext <- tolower(tools::file_ext(path))
  mime <- switch(
    ext,
    ttf = "font/truetype",
    otf = "font/otf",
    woff = "font/woff",
    woff2 = "font/woff2",
    "font/truetype"
  )
  raw_bytes <- readBin(path, "raw", file.info(path)$size)
  b64 <- base64enc::base64encode(raw_bytes)
  list(name = name, data_uri = paste0("data:", mime, ";base64,", b64))
}

#' @export
print.ggrough2 <- function(x, ...) {
  NextMethod()
}
