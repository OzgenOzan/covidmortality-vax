# covidmortality-vax

This repository contains an exploratory, **descriptive** visualization of the time-series co-movement between daily COVID-19 cases, daily deaths, and cumulative vaccine doses administered for a single country/region. It does **not** estimate vaccine effectiveness and does **not** support any causal claim.

The underlying data were gathered from Our World in Data's covid-19-data repository[^1]. The bundled example file `filename.csv` contains the columns `date`, `ncases` (daily new cases), `ndeaths` (daily new deaths), and `tvax` (cumulative total vaccine doses administered; updated only on some days).

## Methods

The analysis is implemented in [`covidmortality-vax.R`](covidmortality-vax.R). Run it with:

```sh
Rscript covidmortality-vax.R filename.csv
```

The script:

1. Reads a CSV whose path is taken from the command line (default `filename.csv`); no user-specific paths are hard-coded.
2. Parses dates and validates the required columns, then **drops** rows with missing case/death counts. Drop-NA is used instead of zero-filling so that no fabricated counts enter the analysis and the cross-correlation step receives a complete series.
3. Smooths daily cases and deaths with a **7-day simple moving average** (`TTR::SMA()`); the 7-day window was chosen to absorb the weekly weekday/weekend reporting cycle.
4. Computes the **cross-correlation function** (`stats::ccf()`) between smoothed cases and smoothed deaths over lags 0–30 days, prints the full CCF table, and selects the lag with the highest correlation to align the two series (using `dplyr::lag()`).
5. Produces a single chart of the lag-aligned smoothed cases, smoothed deaths, and cumulative vaccination counts, with data-driven axis ranges.

Required R packages: `dplyr`, `tidyr`, `TTR`. The script loads them through a helper that stops with an install hint if a package is missing; nothing is auto-installed at runtime. `stats` and `utils` ship with R.

## Limitations

- **Ecological design:** all inputs are population-level aggregates. Associations visible in the plots may not hold at the individual level (ecological fallacy), and nothing here measures vaccine effectiveness.
- **No confounder adjustment:** age structure, variants, testing and reporting practices, health-care capacity, and non-pharmaceutical interventions are not controlled for; apparent temporal shifts cannot be attributed to vaccination or to any other single factor.
- **Lag sensitivity:** the case-to-death delay varies over time (variants, care pathways, reporting changes). The CCF-selected lag is a single descriptive summary of the sample period, not a stable structural parameter.
- **Reporting artifacts:** negative daily counts in the source data are upstream corrections and are retained as reported; sparse vaccination updates leave gaps in the cumulative series.
- **No statistical inference:** no uncertainty intervals or hypothesis tests are reported; the outputs are descriptive graphics and a correlation table only.

[^1]: https://github.com/owid/covid-19-data
