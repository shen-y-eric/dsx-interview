#' Calculate median
#'
#' Computes the median of a numeric vector. `NA` values are removed before
#' calculation.
#'
#' @param x A numeric vector.
#'
#' @return A single numeric value. Returns `NA_real_` with a warning when all
#'   elements of `x` are `NA`.
#'
#' @examples
#' calc_median(c(1, 2, 3, 4, 5))
#' calc_median(c(1, 2, 3, 4))
#'
#' @export
calc_median <- function(x) {
  x_clean <- validate_numeric(x, "calc_median")
  if (identical(x_clean, NA_real_)) return(NA_real_)

  stats::median(x_clean)
}
