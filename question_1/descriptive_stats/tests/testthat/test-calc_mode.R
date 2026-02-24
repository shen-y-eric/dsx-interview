test_that("calc_mode finds a single mode", {
  expect_equal(calc_mode(c(1, 2, 2, 3)), 2)
  expect_equal(calc_mode(c(5, 5, 5, 1, 2)), 5)
})

test_that("calc_mode returns multiple tied modes in ascending order", {
  expect_equal(calc_mode(c(1, 1, 2, 2, 3)), c(1, 2))
  expect_equal(calc_mode(c(3, 3, 1, 1, 2, 2)), c(1, 2, 3))
})

test_that("calc_mode handles the assessment example", {
  data <- c(1, 2, 2, 3, 4, 5, 5, 5, 6, 10)
  expect_equal(calc_mode(data), 5)
})

test_that("calc_mode warns and returns NA when no mode exists", {
  expect_warning(result <- calc_mode(c(1, 2, 3)), "no mode")
  expect_identical(result, NA_real_)
})

test_that("calc_mode warns and returns NA for single unique value repeated once", {
  # A single value has frequency 1 — no repeated value, so no mode
  expect_warning(result <- calc_mode(4), "no mode")
  expect_identical(result, NA_real_)
})

test_that("calc_mode removes NA values before computing", {
  expect_equal(calc_mode(c(1, 2, 2, NA, 3)), 2)
})

test_that("calc_mode returns NA with warning for all-NA input", {
  expect_warning(result <- calc_mode(c(NA_real_, NA_real_)), "all values are NA")
  expect_identical(result, NA_real_)
})

test_that("calc_mode works with negative numbers", {
  expect_equal(calc_mode(c(-1, -1, 2, 3)), -1)
})

test_that("calc_mode errors on non-numeric input", {
  expect_error(calc_mode("a"), "numeric vector")
})

test_that("calc_mode errors on empty vector", {
  expect_error(calc_mode(numeric(0)), "non-empty")
})
