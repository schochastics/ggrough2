validate_rough_options <- function(
  roughness = 1.5,
  bowing = 1,
  fill_style = "hachure",
  bg_fill_style = "solid",
  seed = NULL,
  preserve_text = TRUE
) {
  if (!is.numeric(roughness) || length(roughness) != 1 || roughness < 0 || roughness > 10) {
    stop("`roughness` must be a single numeric value between 0 and 10.", call. = FALSE)
  }
  if (!is.numeric(bowing) || length(bowing) != 1 || bowing < 0 || bowing > 10) {
    stop("`bowing` must be a single numeric value between 0 and 10.", call. = FALSE)
  }
  fill_style <- match.arg(
    fill_style,
    choices = c("hachure", "solid", "zigzag", "cross-hatch", "dots", "dashed", "zigzag-line")
  )
  bg_fill_style <- match.arg(
    bg_fill_style,
    choices = c("hachure", "solid", "zigzag", "cross-hatch", "dots", "dashed", "zigzag-line")
  )
  if (!is.null(seed)) {
    if (!is.numeric(seed) || length(seed) != 1 || seed != round(seed)) {
      stop("`seed` must be NULL or a single integer value.", call. = FALSE)
    }
    seed <- as.integer(seed)
  }
  if (!is.logical(preserve_text) || length(preserve_text) != 1 || is.na(preserve_text)) {
    stop("`preserve_text` must be TRUE or FALSE.", call. = FALSE)
  }

  list(
    roughness    = roughness,
    bowing       = bowing,
    fillStyle    = fill_style,
    bgFillStyle  = bg_fill_style,
    seed         = seed,
    preserveText = preserve_text
  )
}
