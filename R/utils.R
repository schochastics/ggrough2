#' Rough.js drawing options
#'
#' Constructs a list of optional Rough.js parameters to pass to
#' [rough_plot()]. All arguments default to `NULL`, meaning the Rough.js
#' library default is used.
#'
#' @param fill_weight Width of hachure lines (numeric). For `"dots"` fill
#'   style, this is the dot diameter. Defaults to half the stroke width.
#' @param hachure_angle Angle of hachure lines in degrees (numeric).
#'   Default: -41.
#' @param hachure_gap Average gap in pixels between hachure lines (numeric).
#'   Default: 4× stroke width.
#' @param curve_step_count Number of points used to approximate curves
#'   (ellipses, arcs). Default: 9.
#' @param curve_fitting How closely rendered dimensions match specified
#'   dimensions for curves (0–1). Default: 0.95.
#' @param stroke_line_dash Dashed stroke pattern — a numeric vector of
#'   dash/gap lengths (e.g. `c(5, 10)`). Does not affect fill hachure.
#' @param stroke_line_dash_offset Phase offset for dashed strokes (numeric).
#' @param fill_line_dash Like `stroke_line_dash` but affects fill patterns.
#' @param fill_line_dash_offset Like `stroke_line_dash_offset` but for fills.
#' @param disable_multi_stroke Logical. If `TRUE`, only a single stroke pass
#'   is used (less sketchy). Default: `FALSE`.
#' @param disable_multi_stroke_fill Logical. If `TRUE`, single stroke for
#'   hachure fill lines. Default: `FALSE`.
#' @param simplification Simplify SVG paths by this factor (0–1). 0 = no
#'   simplification. Useful for giving complex paths a sketchy feel.
#' @param dash_offset Nominal dash length (px) for `"dashed"` fill style.
#'   Defaults to `hachure_gap`.
#' @param dash_gap Nominal gap between dashes (px) for `"dashed"` fill style.
#'   Defaults to `hachure_gap`.
#' @param zigzag_offset Nominal width of zigzag triangles (px) for
#'   `"zigzag-line"` fill style. Defaults to `hachure_gap`.
#' @param preserve_vertices Logical. If `TRUE`, endpoint positions of lines
#'   and curves are not randomised. Default: `FALSE`.
#'
#' @return A named list suitable for the `options` argument of [rough_plot()].
#' @export
rough_options <- function(
  fill_weight = NULL,
  hachure_angle = NULL,
  hachure_gap = NULL,
  curve_step_count = NULL,
  curve_fitting = NULL,
  stroke_line_dash = NULL,
  stroke_line_dash_offset = NULL,
  fill_line_dash = NULL,
  fill_line_dash_offset = NULL,
  disable_multi_stroke = NULL,
  disable_multi_stroke_fill = NULL,
  simplification = NULL,
  dash_offset = NULL,
  dash_gap = NULL,
  zigzag_offset = NULL,
  preserve_vertices = NULL
) {
  opts <- list(
    fillWeight            = fill_weight,
    hachureAngle          = hachure_angle,
    hachureGap            = hachure_gap,
    curveStepCount        = curve_step_count,
    curveFitting          = curve_fitting,
    strokeLineDash        = stroke_line_dash,
    strokeLineDashOffset  = stroke_line_dash_offset,
    fillLineDash          = fill_line_dash,
    fillLineDashOffset    = fill_line_dash_offset,
    disableMultiStroke    = disable_multi_stroke,
    disableMultiStrokeFill = disable_multi_stroke_fill,
    simplification        = simplification,
    dashOffset            = dash_offset,
    dashGap               = dash_gap,
    zigzagOffset          = zigzag_offset,
    preserveVertices      = preserve_vertices
  )
  # Drop NULLs so JS can detect "not set"
  Filter(Negate(is.null), opts)
}

validate_rough_options <- function(
  roughness = 1.5,
  bowing = 1,
  fill_style = "hachure",
  bg_fill_style = "solid",
  seed = NULL,
  preserve_text = TRUE,
  options = list()
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

  base <- list(
    roughness = roughness,
    bowing = bowing,
    fillStyle = fill_style,
    bgFillStyle = bg_fill_style,
    seed = seed,
    preserveText = preserve_text
  )
  c(base, options)
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
