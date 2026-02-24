#' Calculate mode
#'
#' Computes the statistical mode of a numeric vector. `NA` values are removed
#' before calculation.
#'
#' When multiple values share the highest frequency (ties), all tied modes are
#' returned in ascending order. When every value is unique (no repeated values),
#' `NA_real_` is returned with a warning.
#'
#' @param x A numeric vector.
#'
#' @return A numeric vector of mode(s). Returns `NA_real_` with a warning when
#'   no mode exists (all values unique) or when all elements of `x` are `NA`.
#'
#' @examples
#' calc_mode(c(1, 2, 2, 3, 4))
#' calc_mode(c(1, 1, 2, 2, 3))
#' calc_mode(c(1, 2, 3))
#'
#' @export
calc_mode <- function(x) {
  x_clean <- validate_numeric(x, "calc_mode")
  if (identical(x_clean, NA_real_)) return(NA_real_)

  freq <- table(x_clean)
  max_freq <- max(freq)

  if (max_freq == 1L) {
    warning("calc_mode(): no mode found, all values are unique.", call. = FALSE)
    return(NA_real_)
  }

  modes <- as.numeric(names(freq[freq == max_freq]))
  sort(modes)
}
