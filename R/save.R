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
save_rough_image <- function(
  plot,
  file,
  ...,
  delay = 2,
  vwidth = 992,
  vheight = 744
) {
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
      url,
      file = file,
      delay = delay,
      vwidth = vwidth,
      vheight = vheight,
      selector = ".ggrough2 > div"
    )
  } else {
    b <- chromote::ChromoteSession$new()
    on.exit(b$close(), add = TRUE)

    b$Emulation$setDeviceMetricsOverride(
      width = vwidth,
      height = vheight,
      deviceScaleFactor = 1,
      mobile = FALSE,
      wait_ = TRUE
    )
    b$Page$navigate(url, wait_ = TRUE)
    Sys.sleep(delay)

    result <- b$Runtime$evaluate(
      '(function() {
        var el = document.querySelector(".ggrough2");
        if (!el) return "";
        var svgs = Array.from(el.querySelectorAll("svg"));
        if (svgs.length === 0) return "";
        if (svgs.length === 1) return svgs[0].outerHTML;
        // Two-pass layout: merge fg SVG content into bg SVG so both layers
        // are captured in a single SVG file.
        var out = svgs[0].cloneNode(true);
        var g = document.createElementNS("http://www.w3.org/2000/svg", "g");
        Array.from(svgs[1].childNodes).forEach(function(n) {
          g.appendChild(n.cloneNode(true));
        });
        out.appendChild(g);
        return out.outerHTML;
      })()',
      wait_ = TRUE
    )
    svg_str <- result$result$value
    if (!nzchar(svg_str)) {
      stop(
        "No rendered SVG found. The sketch may not have finished - try increasing `delay`.",
        call. = FALSE
      )
    }
    writeLines(svg_str, con = file)
  }

  invisible(file)
}
