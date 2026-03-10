validate_rough_options <- function(
  roughness = 1.5,
  bowing = 1,
  fill_style = "hachure",
  bg_fill_style = "solid",
  seed = NULL,
  preserve_text = TRUE
) {
  if (
    !is.numeric(roughness) ||
      length(roughness) != 1 ||
      roughness < 0 ||
      roughness > 10
  ) {
    stop(
      "`roughness` must be a single numeric value between 0 and 10.",
      call. = FALSE
    )
  }
  if (!is.numeric(bowing) || length(bowing) != 1 || bowing < 0 || bowing > 10) {
    stop(
      "`bowing` must be a single numeric value between 0 and 10.",
      call. = FALSE
    )
  }
  fill_style <- match.arg(
    fill_style,
    choices = c(
      "hachure",
      "solid",
      "zigzag",
      "cross-hatch",
      "dots",
      "dashed",
      "zigzag-line"
    )
  )
  bg_fill_style <- match.arg(
    bg_fill_style,
    choices = c(
      "hachure",
      "solid",
      "zigzag",
      "cross-hatch",
      "dots",
      "dashed",
      "zigzag-line"
    )
  )
  if (!is.null(seed)) {
    if (!is.numeric(seed) || length(seed) != 1 || seed != round(seed)) {
      stop("`seed` must be NULL or a single integer value.", call. = FALSE)
    }
    seed <- as.integer(seed)
  }
  if (
    !is.logical(preserve_text) ||
      length(preserve_text) != 1 ||
      is.na(preserve_text)
  ) {
    stop("`preserve_text` must be TRUE or FALSE.", call. = FALSE)
  }

  list(
    roughness = roughness,
    bowing = bowing,
    fillStyle = fill_style,
    bgFillStyle = bg_fill_style,
    seed = seed,
    preserveText = preserve_text
  )
}

#' @importFrom knitr knit_print
#' @export
knit_print.ggrough2 <- function(x, options = NULL, ...) {
  if (!isTRUE(getOption("knitr.in.progress"))) {
    # Interactive session - show widget normally
    return(NextMethod())
  }

  # During knitting - save as PNG and include
  if (requireNamespace("webshot2", quietly = TRUE)) {
    tmp_html <- tempfile(fileext = ".html")
    tmp_png <- tempfile(fileext = ".png")

    # Save widget to HTML then capture as PNG
    htmlwidgets::saveWidget(x, file = tmp_html, selfcontained = TRUE)
    url <- paste0("file:///", normalizePath(tmp_html, winslash = "/"))

    # Extract numeric pixel dimensions - already stored in pixels by rough_plot()
    # Add padding to viewport to avoid clipping
    vwidth <- as.integer(x$width %||% 672L) + 100L
    vheight <- as.integer(x$height %||% 480L) + 100L

    # Use do.call to prevent any accidental parameter passing
    # Don't use selector - capture full widget area
    do.call(
      webshot2::webshot,
      list(
        url = url,
        file = tmp_png,
        delay = 2,
        vwidth = vwidth,
        vheight = vheight
      )
    )

    # Return the image path wrapped in knitr's image output structure
    knitr::asis_output(
      paste0("![](", knitr::opts_knit$get("base.url"), tmp_png, ")")
    )
  } else {
    warning(
      "webshot2 required for knitting. Install with: install.packages('webshot2')"
    )
    NextMethod()
  }
}

# Null-coalescing operator
`%||%` <- function(a, b) if (is.null(a)) b else a
