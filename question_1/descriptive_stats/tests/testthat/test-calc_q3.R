test_that("calc_q3 computes the third quartile", {
  # For c(1,2,3,4,5,6,7,8), type 7: h = 7*0.75 + 1 = 6.25
  # Q3 = x[6] + 0.25*(x[7] - x[6]) = 6 + 0.25*1 = 6.25
  expect_equal(calc_q3(c(1, 2, 3, 4, 5, 6, 7, 8)), 6.25)
})

test_that("calc_q3 removes NA values before computing", {
  expect_equal(calc_q3(c(1, NA, 2, 3, 4, 5, 6, 7, 8)), 6.25)
})

test_that("calc_q3 works with a single value", {
  expect_equal(calc_q3(5), 5)
})

test_that("calc_q3 handles the assessment example", {
  data <- c(1, 2, 2, 3, 4, 5, 5, 5, 6, 10)
  # type 7: h = 9*0.75 + 1 = 7.75
  # Q3 = x[7] + 0.75*(x[8] - x[7]) = 5 + 0.75*(5-5) = 5.0
  expect_equal(calc_q3(data), 5.0)
})

test_that("calc_q3 returns NA with warning for all-NA input", {
  expect_warning(result <- calc_q3(c(NA_real_, NA_real_)), "all values are NA")
  expect_identical(result, NA_real_)
})

test_that("calc_q3 errors on non-numeric input", {
  expect_error(calc_q3("a"), "numeric vector")
})

test_that("calc_q3 errors on empty vector", {
  expect_error(calc_q3(numeric(0)), "non-empty")
})
