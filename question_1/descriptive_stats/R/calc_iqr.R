#' Calculate interquartile range (IQR)
#'
#' Computes the interquartile range as Q3 - Q1 using R's default quantile
#' algorithm (`type = 7`). `NA` values are removed before calculation.
#'
#' This function validates and cleans the input once, then computes both
#' quartiles directly, avoiding duplicate warnings for all-`NA` input.
#'
#' @param x A numeric vector.
#'
#' @return A single numeric value. Returns `NA_real_` with a warning when all
#'   elements of `x` are `NA`.
#'
#' @seealso [calc_q1()], [calc_q3()], [stats::IQR()]
#'
#' @examples
#' calc_iqr(c(1, 2, 3, 4, 5, 6, 7, 8))
#' calc_iqr(c(2, 4, 6, 8, 10, 12))
#'
#' @export
calc_iqr <- function(x) {
  x_clean <- validate_numeric(x, "calc_iqr")
  if (identical(x_clean, NA_real_)) return(NA_real_)

  q1 <- unname(stats::quantile(x_clean, probs = 0.25))
  q3 <- unname(stats::quantile(x_clean, probs = 0.75))

  q3 - q1
}
