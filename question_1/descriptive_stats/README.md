# descriptiveStats

An R package providing common descriptive statistics functions for numeric
vectors. All functions handle `NA` values and invalid inputs gracefully with
informative messages.

## Functions

| Function          | Description                                |
|-------------------|--------------------------------------------|
| `calc_mean(x)`    | Arithmetic mean                            |
| `calc_median(x)`  | Median                                     |
| `calc_mode(x)`    | Mode (handles ties and no-mode cases)      |
| `calc_q1(x)`      | First quartile (25th percentile)           |
| `calc_q3(x)`      | Third quartile (75th percentile)           |
| `calc_iqr(x)`     | Interquartile range (Q3 - Q1)              |

## Installation

From the repository root:

```r
devtools::install("question_1/descriptive_stats")
library(descriptiveStats)
```

## Example

```r
data <- c(1, 2, 2, 3, 4, 5, 5, 5, 6, 10)

calc_mean(data)    # 4.3
calc_median(data)  # 4.5
calc_mode(data)    # 5
calc_q1(data)      # 2.25
calc_q3(data)      # 5.0
calc_iqr(data)     # 2.75
```

## Edge-case handling

| Scenario              | Behavior                                          |
|-----------------------|---------------------------------------------------|
| Non-numeric input     | Throws an error naming the expected type           |
| Empty vector          | Throws an error requesting non-empty input         |
| `NA` values present   | Removed before calculation                         |
| All-`NA` input        | Returns `NA_real_` with a warning                  |
| Mode: all unique      | Returns `NA_real_` with a warning                  |
| Mode: ties            | Returns all tied values in ascending order          |

## Quartile algorithm

`calc_q1()` and `calc_q3()` use R's default quantile algorithm (`type = 7`),
which is the same method used by `stats::quantile()` and `stats::IQR()`. This
is the linear interpolation method described in Hyndman and Fan (1996).

For the sample vector `c(1, 2, 2, 3, 4, 5, 5, 5, 6, 10)`, this package returns:

- `calc_mean()` = `4.3`
- `calc_q1()` = `2.25`
- `calc_q3()` = `5.0`
- `calc_iqr()` = `2.75`

These values follow base R behavior (`stats::quantile(..., type = 7)` and
`Q3 - Q1`).

Interview note: the assessment handout shows a different expected output for
this example; I implemented and tested the functions against standard R
definitions for reproducibility and consistency.

## Package structure

```
descriptive_stats/
├── DESCRIPTION          # Package metadata
├── NAMESPACE            # Exports and imports (roxygen2-generated)
├── LICENSE              # MIT license file
├── .Rbuildignore        # Files excluded from R CMD build
├── R/
│   ├── descriptiveStats-package.R   # Package-level documentation
│   ├── validate.R                   # Internal input validation
│   ├── calc_mean.R
│   ├── calc_median.R
│   ├── calc_mode.R
│   ├── calc_q1.R
│   ├── calc_q3.R
│   └── calc_iqr.R
├── tests/
│   ├── testthat.R
│   └── testthat/
│       ├── test-calc_mean.R
│       ├── test-calc_median.R
│       ├── test-calc_mode.R
│       ├── test-calc_q1.R
│       ├── test-calc_q3.R
│       └── test-calc_iqr.R
└── README.md
```

## Running tests

```r
devtools::test("question_1/descriptive_stats")
```

## Building documentation

To regenerate the `man/` directory and `NAMESPACE` from roxygen2 comments:

```r
devtools::document("question_1/descriptive_stats")
```
