validate_rough_options <- function(
  roughness = 1.5,
  bowing = 1,
  fill_style = "hachure",
  seed = NULL,
  preserve_text = TRUE
) {
  list(
    roughness = roughness,
    bowing = bowing,
    fillStyle = fill_style,
    seed = seed,
    preserveText = preserve_text
  )
}
