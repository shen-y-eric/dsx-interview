test_that("calc_median computes the median for odd-length vectors", {
  expect_equal(calc_median(c(1, 3, 5)), 3)
  expect_equal(calc_median(c(1, 2, 3, 4, 5)), 3)
})

test_that("calc_median computes the median for even-length vectors", {
  expect_equal(calc_median(c(1, 2, 3, 4)), 2.5)
  expect_equal(calc_median(c(10, 20)), 15)
})

test_that("calc_median removes NA values before computing", {
  expect_equal(calc_median(c(1, NA, 5)), 3)
  expect_equal(calc_median(c(NA, 2, NA, 4)), 3)
})

test_that("calc_median works with a single value", {
  expect_equal(calc_median(42), 42)
})

test_that("calc_median handles the assessment example", {
  data <- c(1, 2, 2, 3, 4, 5, 5, 5, 6, 10)
  expect_equal(calc_median(data), 4.5)
})

test_that("calc_median handles negative values", {
  expect_equal(calc_median(c(-5, -3, -1, 1, 3)), -1)
})

test_that("calc_median returns NA with warning for all-NA input", {
  expect_warning(result <- calc_median(c(NA_real_, NA_real_)), "all values are NA")
  expect_identical(result, NA_real_)
})

test_that("calc_median errors on non-numeric input", {
  expect_error(calc_median("a"), "numeric vector")
  expect_error(calc_median(list(1, 2)), "numeric vector")
})

test_that("calc_median errors on empty vector", {
  expect_error(calc_median(numeric(0)), "non-empty")
})
