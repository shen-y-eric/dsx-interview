#' Validate and clean a numeric vector
#'
#' Checks that input is a non-empty numeric vector, removes `NA` values, and
#' warns if all values are `NA`.
#'
#' @param x Input to validate.
#' @param fn_name Character string of the calling function name, used in
#'   error/warning messages.
#'
#' @return A numeric vector with `NA` values removed, or `NA_real_` if the
#'   input contained only `NA` values (with a warning).
#'
#' @keywords internal
validate_numeric <- function(x, fn_name) {
  if (!is.numeric(x)) {
    stop(
      sprintf("%s() requires a numeric vector, got %s.", fn_name, class(x)[1]),
      call. = FALSE
    )
  }

  if (length(x) == 0L) {
    stop(
      sprintf("%s() requires a non-empty vector.", fn_name),
      call. = FALSE
    )
  }

  x_clean <- x[!is.na(x)]

  if (length(x_clean) == 0L) {
    warning(
      sprintf("%s(): all values are NA, returning NA.", fn_name),
      call. = FALSE
    )
    return(NA_real_)
  }

  x_clean
}
