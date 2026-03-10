#' Export a roughened plot as an SVG or PNG file
#'
#' Renders the plot in a headless browser so the Rough.js sketch is fully drawn
#' before the image is captured. Requires the \pkg{webshot2} package and a
#' local Chrome/Chromium installation.
#'
#' @param plot A ggplot object.
#' @param file Output file path. Extension must be `.svg` or `.png`.
#' @param ... Additional arguments passed to [rough_plot()].
#' @param delay Seconds to wait after page load before capturing. Increase if
#'   the output is blank or partially rendered.
#' @param vwidth,vheight Browser viewport dimensions in pixels.
#'
#' @return `file`, invisibly.
#' @export
save_rough_image <- function(plot, file, ..., delay = 2, vwidth = 992, vheight = 744) {
  ext <- tolower(tools::file_ext(file))
  if (!ext %in% c("svg", "png")) {
    stop('`file` must have a ".svg" or ".png" extension.', call. = FALSE)
  }
  if (!requireNamespace("webshot2", quietly = TRUE)) {
    stop(
      'Package "webshot2" is required for image export.\n',
      'Install it with: install.packages("webshot2")',
      call. = FALSE
    )
  }

  tmp <- tempfile(fileext = ".html")
  on.exit(unlink(tmp), add = TRUE)
  save_rough_html(plot, tmp, ...)

  url <- paste0("file:///", normalizePath(tmp, winslash = "/"))

  if (ext == "png") {
    webshot2::webshot(
      url, file = file,
      delay   = delay,
      vwidth  = vwidth,
      vheight = vheight,
      selector = ".ggrough2"
    )
  } else {
    b <- chromote::ChromoteSession$new()
    on.exit(b$close(), add = TRUE)

    b$Emulation$setDeviceMetricsOverride(
      width             = vwidth,
      height            = vheight,
      deviceScaleFactor = 1,
      mobile            = FALSE,
      wait_             = TRUE
    )
    b$Page$navigate(url, wait_ = TRUE)
    Sys.sleep(delay)

    result <- b$Runtime$evaluate(
      '(function() {
        var svg = document.querySelector(".ggrough2 svg");
        return svg ? svg.outerHTML : "";
      })()',
      wait_ = TRUE
    )
    svg_str <- result$result$value
    if (!nzchar(svg_str)) {
      stop(
        "No rendered SVG found. The sketch may not have finished — try increasing `delay`.",
        call. = FALSE
      )
    }
    writeLines(svg_str, con = file)
  }

  invisible(file)
}
