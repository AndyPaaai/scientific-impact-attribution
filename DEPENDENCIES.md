# R Environment and Package Dependencies

This document specifies the software environment and R packages required to execute [`src/code.R`](src/code.R) and reproduce all statistical analyses, manuscript tables, supplementary tables (S1–S7), and figures (Figures 1–4).

---

## 1. R Version

- **Version used for analysis:** `R version 4.4.2 (2024-10-31 ucrt)`
- **Minimum supported version:** `R >= 4.2.0`
- **Platform tested:** Windows (`x86_64-w64-mingw32/x64`, 64-bit); fully portable across Windows, macOS, and Linux.

---

## 2. Required CRAN Packages

The analytical script [`src/code.R`](src/code.R) depends exclusively on **two CRAN packages** in addition to standard base R packages:

| Package | Version Used | Minimum Version | Purpose in Pipeline |
| :--- | :--- | :--- | :--- |
| `readxl` | `1.4.3` | `>= 1.4.0` | Reads the `"Data"` worksheet from the two Ioannidis (2026, V9) Excel workbooks and the `"List of economies"` worksheet from the World Bank FY2026 classification workbook (`CLASS_2025_07_02.xlsx`) with explicit column typing to minimize memory overhead. |
| `ggplot2` | `3.5.1` | `>= 3.5.0` | Generates the four publication figures (`Figure_1_country_changes`, `Figure_2_concentration`, `Figure_3_income_groups`, and `Figure_4_income_transitions`). |

---

## 3. Base R Packages Used

All data cleaning, ISO-3 country-code standardization, contingency aggregation, concentration index calculation (Herfindahl–Hirschman Index and Gini coefficient), multi-panel layout composition, and file exports rely on standard base R packages bundled with R (`4.4.2`):

| Base Package | Purpose |
| :--- | :--- |
| `base` | Data structures, string normalization, set operations, and control flow. |
| `stats` | Group-level calculations and named vector utilities (`setNames`, `ave`). |
| `utils` | UTF-8 CSV input/output (`read.csv`, `write.csv`) and ranking selection (`head`, `tail`). |
| `grid` | Viewport layout composition (`grid.layout`, `viewport`, `grid.draw`) for combining Panels A and B of Figure 2 without external layout packages. |
| `grDevices` | High-resolution PNG (`180 dpi`) and editable vector SVG graphics device output (`png`, `svg`, `dev.off`). |

---

## 4. Manual Installation Instructions

To prevent unexpected session restarts or package conflicts during execution, [`src/code.R`](src/code.R) **does not run `install.packages()` automatically**. Instead, it checks at startup whether `readxl` and `ggplot2` are installed and stops with an informative message if either package is missing.

### Standard Installation (macOS, Linux, and Windows)

Open an R session and run:

```r
install.packages(c("readxl", "ggplot2"))
```

### Windows Binary Installation (Recommended on Windows)

On Windows, installing precompiled CRAN binaries avoids source compilation problems and R session restarts:

```r
install.packages(c("readxl", "ggplot2"), type = "binary")
```

### Verifying Your Environment

You can verify that your R installation meets all requirements by running the following command in R:

```r
cat("R version:", R.version.string, "\n")
for (pkg in c("readxl", "ggplot2")) {
  if (requireNamespace(pkg, quietly = TRUE)) {
    cat(pkg, "version:", as.character(packageVersion(pkg)), "\n")
  } else {
    cat(pkg, ": NOT INSTALLED\n")
  }
}
```
