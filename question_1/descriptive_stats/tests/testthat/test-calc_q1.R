test_that("calc_q1 computes the first quartile", {
  # For c(1,2,3,4,5,6,7,8), type 7: h = 7*0.25 + 1 = 2.75
  # Q1 = x[2] + 0.75*(x[3] - x[2]) = 2 + 0.75*1 = 2.75
  expect_equal(calc_q1(c(1, 2, 3, 4, 5, 6, 7, 8)), 2.75)
})

test_that("calc_q1 removes NA values before computing", {
  expect_equal(calc_q1(c(1, NA, 2, 3, 4, 5, 6, 7, 8)), 2.75)
})

test_that("calc_q1 works with a single value", {
  expect_equal(calc_q1(5), 5)
})

test_that("calc_q1 handles the assessment example", {
  data <- c(1, 2, 2, 3, 4, 5, 5, 5, 6, 10)
  # type 7: h = 9*0.25 + 1 = 3.25
  # Q1 = x[3] + 0.25*(x[4] - x[3]) = 2 + 0.25*(3-2) = 2.25
  expect_equal(calc_q1(data), 2.25)
})

test_that("calc_q1 returns NA with warning for all-NA input", {
  expect_warning(result <- calc_q1(c(NA_real_, NA_real_)), "all values are NA")
  expect_identical(result, NA_real_)
})

test_that("calc_q1 errors on non-numeric input", {
  expect_error(calc_q1("a"), "numeric vector")
})

test_that("calc_q1 errors on empty vector", {
  expect_error(calc_q1(numeric(0)), "non-empty")
})
