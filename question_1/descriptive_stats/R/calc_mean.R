#' Calculate arithmetic mean
#'
#' Computes the arithmetic mean of a numeric vector. `NA` values are removed
#' before calculation.
#'
#' @param x A numeric vector.
#'
#' @return A single numeric value. Returns `NA_real_` with a warning when all
#'   elements of `x` are `NA`.
#'
#' @examples
#' calc_mean(c(1, 2, 3, 4, 5))
#' calc_mean(c(10, NA, 30))
#'
#' @export
calc_mean <- function(x) {
  x_clean <- validate_numeric(x, "calc_mean")
  if (identical(x_clean, NA_real_)) return(NA_real_)

  mean(x_clean)
}
