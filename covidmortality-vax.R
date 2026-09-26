#!/usr/bin/env Rscript
# =============================================================================
# covidmortality-vax.R
#
# Descriptive, exploratory visualization of daily COVID-19 cases, daily
# deaths, and cumulative vaccination counts for a single country/region.
#
# STUDY DESIGN / SCOPE
#   This is an ECOLOGICAL (aggregate, population-level) time-series
#   exploration. It describes visual co-movement between daily new cases
#   and daily new deaths, and overlays cumulative vaccination counts for
#   context only. Because the data are aggregated and unadjusted for
#   confounders (age structure, variants, testing capacity, reporting
#   artifacts, non-pharmaceutical interventions, etc.), NO causal claim
#   and NO vaccine-effectiveness estimate can be drawn from this script.
#
# REQUIRED PACKAGES (install once before running, e.g.
#   install.packages(c("dplyr", "tidyr", "TTR")) ):
#     dplyr, tidyr, TTR
#   (stats and utils ship with base R; no packages are auto-installed.)
#
# USAGE:
#   Rscript covidmortality-vax.R [path/to/data.csv]
#   Defaults to "filename.csv" in the working directory. No hard-coded
#   user-specific paths.
#
# EXPECTED CSV COLUMNS (as in the bundled filename.csv):
#   date    ISO date (YYYY-MM-DD)
#   ncases  daily new confirmed cases
#   ndeaths daily new deaths
#   tvax    cumulative total vaccine doses administered (sparse; NA on
#           days without an update)
# =============================================================================

## ---- Package loading -------------------------------------------------------
# Fail fast with an install hint if a required package is missing, instead
# of auto-installing the latest versions at runtime (which is not
# reproducible).
require_pkg <- function(pkg) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    stop(sprintf(
      paste0("Package '%s' is required but not installed. ",
             "Install it with:\n  install.packages(\"%s\")"),
      pkg, pkg
    ), call. = FALSE)
  }
  suppressPackageStartupMessages(library(pkg, character.only = TRUE))
  invisible(TRUE)
}
invisible(lapply(c("dplyr", "tidyr", "TTR"), require_pkg))

## ---- Configuration ----------------------------------------------------------
# Window for the simple moving average used to smooth the noisy daily
# counts. 7 days matches the weekly (weekday/weekend) reporting cycle in
# most national COVID-19 reporting streams. Documented, adjustable choice.
SMA_WINDOW <- 7L

# Maximum lag (in days) examined by the cross-correlation function when
# selecting the case-to-death delay.
MAX_LAG <- 30L

## ---- Data loading -----------------------------------------------------------
args     <- commandArgs(trailingOnly = TRUE)
csv_path <- if (length(args) >= 1L) args[[1L]] else "filename.csv"
if (!file.exists(csv_path)) {
  stop(sprintf("Input file not found: '%s'. Pass a CSV path as the first argument.",
               csv_path), call. = FALSE)
}

# TODO(owner): document data provenance -- exact source extract, download
# date, country covered, and any preprocessing applied before this CSV was
# produced. The README cites Our World in Data, but the precise extract
# and filtering steps are not recorded anywhere in this repository.
raw <- utils::read.csv(csv_path, header = TRUE, stringsAsFactors = FALSE)

required_cols <- c("date", "ncases", "ndeaths", "tvax")
missing_cols  <- setdiff(required_cols, names(raw))
if (length(missing_cols) > 0L) {
  stop(sprintf("Input CSV is missing required column(s): %s",
               paste(missing_cols, collapse = ", ")), call. = FALSE)
}

dat <- raw %>%
  dplyr::mutate(
    date    = as.Date(date),  # parse the date column explicitly
    ncases  = as.numeric(ncases),
    ndeaths = as.numeric(ndeaths),
    tvax    = as.numeric(tvax)
  ) %>%
  dplyr::arrange(date)

# NOTE: negative daily counts present in the source data (e.g. -4787 cases
# on 2021-04-09 in the bundled file) are upstream data corrections, not
# measurement errors; they are retained as reported.

## ---- NA handling and smoothing ----------------------------------------------
# We DROP rows with missing cases/deaths rather than zero-filling, because
# (a) zero-filling fabricates counts on days the source simply did not
# report, and (b) stats::ccf() requires a complete series -- injected zeros
# would bias the cross-correlation estimates used for lag selection below.
dat <- dat %>%
  tidyr::drop_na(ncases, ndeaths)

dat <- dat %>%
  dplyr::mutate(
    cases_sma  = TTR::SMA(ncases,  n = SMA_WINDOW),
    deaths_sma = TTR::SMA(ndeaths, n = SMA_WINDOW)
  )

## ---- Lag selection via cross-correlation -------------------------------------
# Empirically select the delay between cases and deaths instead of
# hard-coding arbitrary lags (7/9/12) as the previous draft did.
# stats::ccf(x, y) at positive lag k computes Cor(x_{t+k}, y_t), i.e. a
# positive lag means cases LEAD deaths by k days.
smooth <- dat %>% tidyr::drop_na(cases_sma, deaths_sma)
if (nrow(smooth) < (2L * MAX_LAG)) {
  stop("Not enough complete observations to compute the cross-correlation; ",
       "check the input data.", call. = FALSE)
}

ccf_res <- stats::ccf(
  x       = smooth$cases_sma,
  y       = smooth$deaths_sma,
  lag.max = MAX_LAG,
  type    = "correlation",
  plot    = FALSE
)

ccf_table <- data.frame(
  lag_days    = as.numeric(ccf_res$lag),
  correlation = as.numeric(ccf_res$acf)
)
ccf_table <- ccf_table[order(ccf_table$lag_days), ]
cat("Cross-correlation between SMA-smoothed cases and deaths\n")
cat(sprintf("(positive lag k = cases lead deaths by k days; SMA window = %d)\n\n",
            SMA_WINDOW))
print(ccf_table, row.names = FALSE)

# Only non-negative lags are meaningful here (deaths follow cases).
pos      <- ccf_table[ccf_table$lag_days >= 0, ]
best_lag <- pos$lag_days[which.max(pos$correlation)]
cat(sprintf(
  paste0("\nSelected lag: %d days (max correlation %.3f). ",
         "This is a descriptive summary only -- no causal interpretation.\n"),
  best_lag, max(pos$correlation)))

## ---- Aligned series ----------------------------------------------------------
# dplyr::lag(x, n = k) has explicit, correct semantics for plain vectors
# (lagged[t] = x[t - k]), so cases_lagged aligns cases at t - best_lag
# with deaths at t. Base stats::lag() does NOT do this for vectors (it
# only shifts the time index of ts objects) and was misused previously.
# NAs introduced at the leading edge by lagging are expected and are left
# as NA (they are simply not plotted), never length-patched with pmax().
dat <- dat %>%
  dplyr::mutate(cases_lagged = dplyr::lag(cases_sma, n = best_lag))

## ---- Plot --------------------------------------------------------------------
# Full data-driven axis ranges; no arbitrary truncation of y-axes.
ylim_cases  <- range(dat$cases_lagged, na.rm = TRUE)
ylim_deaths <- range(dat$deaths_sma,   na.rm = TRUE)
vax_complete <- dat[!is.na(dat$tvax), ]

op <- par(mar = c(5, 4, 4, 4) + 0.1)

plot(dat$date, dat$cases_lagged, type = "l", col = "steelblue", lwd = 2,
     ylim = ylim_cases, xlab = "Date",
     ylab = sprintf("Daily cases (%d-day SMA, lagged %d d)", SMA_WINDOW, best_lag),
     main = "Daily COVID-19 cases, deaths, and cumulative vaccination\n(descriptive, ecological data)")

par(new = TRUE)
plot(dat$date, dat$deaths_sma, type = "l", col = "firebrick", lwd = 2,
     ylim = ylim_deaths, axes = FALSE, xlab = NA, ylab = NA)
axis(side = 4, las = 1)
mtext(sprintf("Daily deaths (%d-day SMA)", SMA_WINDOW),
      side = 4, line = 3, col = "firebrick")

if (nrow(vax_complete) > 0L) {
  par(new = TRUE)
  plot(vax_complete$date, vax_complete$tvax, type = "l", col = "darkgreen",
       lwd = 1.5, axes = FALSE, xlab = NA, ylab = NA)
  mtext("Cumulative vaccine doses administered", side = 3, line = 2,
        col = "darkgreen")
} else {
  warning("No non-missing 'tvax' values found; vaccination overlay skipped.")
}

legend("topleft", bty = "n", lwd = 2, cex = 0.8,
       col = c("steelblue", "firebrick", "darkgreen"),
       legend = c("Cases (SMA, lagged)", "Deaths (SMA)", "Cumulative doses"))

par(op)

cat(paste0("\nDone. Reminder: these are aggregate, ecological data; this ",
           "script makes no causal or vaccine-effectiveness claim.\n"))
