#' Calculate first quartile (Q1)
#'
#' Computes the 25th percentile of a numeric vector using R's default quantile
#' algorithm (`type = 7`). `NA` values are removed before calculation.
#'
#' @param x A numeric vector.
#'
#' @return A single numeric value. Returns `NA_real_` with a warning when all
#'   elements of `x` are `NA`.
#'
#' @seealso [calc_q3()], [calc_iqr()], [stats::quantile()]
#'
#' @examples
#' calc_q1(c(1, 2, 3, 4, 5, 6, 7, 8))
#' calc_q1(c(2, 4, 6, 8, 10, 12))
#'
#' @export
calc_q1 <- function(x) {
  x_clean <- validate_numeric(x, "calc_q1")
  if (identical(x_clean, NA_real_)) return(NA_real_)

  unname(stats::quantile(x_clean, probs = 0.25))
}
