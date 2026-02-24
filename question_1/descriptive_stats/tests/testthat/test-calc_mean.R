test_that("calc_mean computes the arithmetic mean", {
  expect_equal(calc_mean(c(1, 2, 3, 4, 5)), 3)
  expect_equal(calc_mean(c(10, 20, 30)), 20)
  expect_equal(calc_mean(c(-2, 0, 2)), 0)
})

test_that("calc_mean removes NA values before computing", {
  expect_equal(calc_mean(c(1, NA, 3)), 2)
  expect_equal(calc_mean(c(NA, 5, NA, 15, NA)), 10)
})

test_that("calc_mean works with a single value", {
  expect_equal(calc_mean(7), 7)
})

test_that("calc_mean works with integer input", {
  expect_equal(calc_mean(c(1L, 2L, 3L)), 2)
})

test_that("calc_mean handles the assessment example", {
  data <- c(1, 2, 2, 3, 4, 5, 5, 5, 6, 10)
  expect_equal(calc_mean(data), 4.3)
})

test_that("calc_mean returns NA with warning for all-NA input", {
  expect_warning(result <- calc_mean(c(NA_real_, NA_real_)), "all values are NA")
  expect_identical(result, NA_real_)
})

test_that("calc_mean errors on non-numeric input", {
  expect_error(calc_mean("a"), "numeric vector")
  expect_error(calc_mean(list(1, 2)), "numeric vector")
  expect_error(calc_mean(TRUE), "numeric vector")
})

test_that("calc_mean errors on empty vector", {
  expect_error(calc_mean(numeric(0)), "non-empty")
})

test_that("calc_mean errors on NULL", {
  expect_error(calc_mean(NULL), "numeric vector")
})
