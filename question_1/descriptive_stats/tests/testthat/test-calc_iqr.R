test_that("calc_iqr computes IQR as Q3 - Q1", {
  # For c(1,2,3,4,5,6,7,8): Q3=6.25, Q1=2.75, IQR=3.5
  expect_equal(calc_iqr(c(1, 2, 3, 4, 5, 6, 7, 8)), 3.5)
})

test_that("calc_iqr removes NA values before computing", {
  expect_equal(calc_iqr(c(1, NA, 2, 3, 4, 5, 6, 7, 8)), 3.5)
})

test_that("calc_iqr handles the assessment example", {
  data <- c(1, 2, 2, 3, 4, 5, 5, 5, 6, 10)
  # Q3 = 5.0, Q1 = 2.25, IQR = 2.75
  expect_equal(calc_iqr(data), 2.75)
})

test_that("calc_iqr returns 0 for identical values", {
  expect_equal(calc_iqr(c(5, 5, 5, 5)), 0)
})

test_that("calc_iqr works with two values", {
  expect_equal(calc_iqr(c(0, 10)), 5)
})

test_that("calc_iqr returns NA with warning for all-NA input", {
  # Should produce exactly one warning, not two
  expect_warning(result <- calc_iqr(c(NA_real_, NA_real_)), "all values are NA")
  expect_identical(result, NA_real_)
})

test_that("calc_iqr errors on non-numeric input", {
  expect_error(calc_iqr("a"), "numeric vector")
})

test_that("calc_iqr errors on empty vector", {
  expect_error(calc_iqr(numeric(0)), "non-empty")
})
