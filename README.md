# Whose Scientific Impact? Cross-National Affiliations and the Geography of Highly Cited Researchers

Reproducibility repository containing the analytical R code and derived supplementary datasets for the study:

> **Whose Scientific Impact? Cross-National Affiliations and the Geography of Highly Cited Researchers**  
> *(Manuscript title: Whose scientific impact? How country attribution rules shape the geography of highly cited researchers)*

---

## 1. Project Overview

International bibliometric evaluations of national scientific performance frequently assign highly cited researchers to a single country. However, researchers with multinational publication histories can be represented differently depending on the attribution criterion applied.

This study evaluates the sensitivity of the geographical representation of highly cited researchers to two researcher-level country-attribution rules using Version 9 (August 2026 update) of the science-wide database of standardized citation indicators (Ioannidis, 2026):

- **Scenario A (Most recent institutional affiliation):** Each researcher is assigned to the country associated with their most recently recorded institutional affiliation in Scopus (`cntry`).
- **Scenario B (Predominant career publication country):** Each researcher is assigned to the country accounting for the largest share of eligible publications across their career record (`top_cntry_career`).

Analyses are conducted independently for two database-defined cohorts:
1. **Career-long citation impact cohort** ($N = 243,949$ raw author records; $n = 243,697$ paired analytical sample).
2. **Single-year citation impact cohort (calendar year 2025 citations)** ($N = 249,310$ raw author records; $n = 249,140$ paired analytical sample).

For each cohort, the analytical workflow quantifies researcher-level attribution discordance, national researcher counts and ranking shifts ($\Delta = B - A$), geographical concentration (Herfindahl–Hirschman Index, Gini coefficient, and top-10 country share), reattribution and $4 \times 4$ transitions across World Bank FY2026 income groups, and heterogeneity across scientific fields, subfields, publication-start cohorts, and scientific cosmopolitanism profiles.

---

## 2. Data Sources

To keep this repository lightweight and respect original distribution channels, **the three raw Excel workbooks are not stored in this GitHub repository**. Researchers should download the original read-only files directly from their official sources below.

### A. Ioannidis Science-Wide Author Databases (Version 9, August 2026)

- **Title:** *August 2026 data-update for "Updated science-wide author databases of standardized citation indicators"*
- **Author:** John P. A. Ioannidis
- **Version:** Version 9 (Published 2026)
- **Repository:** Elsevier Data Repository / Mendeley Data
- **Official DOI:** https://doi.org/10.17632/btchxktzyw.9

From the Version 9 archive, download the two author-level Excel workbooks:

| Cohort | Exact Expected Filename | Worksheet Used |
| :--- | :--- | :--- |
| **Career-long citation impact** | `Table_1_Authors_career_2025_pubs_since_1788_wopp_extracted_202608.xlsx` | `Data` |
| **Single-year citation impact (2025)** | `Table_1_Authors_singleyr_2025_pubs_since_1788_wopp_extracted_202608.xlsx` | `Data` |

> **Note on filename prefixes:** Depending on how the Elsevier archive is unpacked, these two files may appear either with their canonical names above or with two-digit numeric prefixes (`02-Table_1_Authors_career_...xlsx` and `03-Table_1_Authors_singleyr_...xlsx`). The script [`src/code.R`](src/code.R) automatically recognizes both naming conventions. Each workbook contains a `Key` metadata sheet and a `Data` author-level sheet; all calculations read from `Data`.

### B. World Bank Country Income Classification (Fiscal Year 2026)

- **Exact Filename Required:** `CLASS_2025_07_02.xlsx` (worksheet: `List of economies`)
- **Classification Vintage:** World Bank Fiscal Year 2026 (FY2026; effective July 1, 2025 – June 30, 2026, based on 2024 GNI per capita via the World Bank Atlas method)
- **Official World Bank Information Page:** https://datahelpdesk.worldbank.org/knowledgebase/articles/906519-world-bank-country-and-lending-groups
- **Official World Bank Reproducibility Catalog Reference (identifying `CLASS_2025_07_02.xlsx`):** https://reproducibility.worldbank.org/catalog/624

> **Important Reproducibility Requirement:** Do **not** replace `CLASS_2025_07_02.xlsx` with a more recent World Bank fiscal-year classification workbook. Because countries periodically change income brackets across fiscal years, preserving the exact FY2026 classification (`CLASS_2025_07_02.xlsx`) is essential to reproduce the income-group counts, percentages, and transition matrices reported in the manuscript.

---

## 3. Repository Structure

```text
scientific-impact-attribution/
├── README.md
├── .gitignore
├── DEPENDENCIES.md
├── src/
│   └── code.R
└── supplementary material/
    ├── Table_S1_country_changes.csv
    ├── Table_S2_income_transitions.csv
    ├── Table_S3_income_discordance.csv
    ├── Table_S4_field_discordance.csv
    ├── Table_S5_subfield_discordance.csv
    ├── Table_S6_publication_cohorts.csv
    └── Table_S7_cosmo_discordance.csv
```

- [`README.md`](README.md): Study overview, data acquisition guide, execution instructions, methodological notes, and reproducibility checklist.
- [`.gitignore`](.gitignore): Excludes raw Excel databases, local outputs, temporary manuscripts, and session files from version control.
- [`DEPENDENCIES.md`](DEPENDENCIES.md): R version (`4.4.2`), required CRAN packages (`readxl`, `ggplot2`), package versions, and manual installation instructions.
- [`src/code.R`](src/code.R): Complete, self-contained R script that imports the three original workbooks, performs all data cleaning and statistical analyses, exports manuscript and supplementary tables, verifies consistency against `supplementary material/`, and renders Figures 1–4 in PNG and SVG formats.
- [`supplementary material/`](supplementary%20material/): The seven supplementary datasets (Tables S1–S7) supporting the manuscript.

---

## 4. Requirements and Installation

- **R:** Version `>= 4.2.0` (developed and validated with **R 4.4.2**).
- **CRAN Packages:** `readxl` (`1.4.3`) and `ggplot2` (`3.5.1`).
- **Base R Packages:** `base`, `stats`, `utils`, `grid`, `grDevices`.

Install the two required CRAN packages manually in R before running the analysis (see [`DEPENDENCIES.md`](DEPENDENCIES.md) for details):

```r
install.packages(c("readxl", "ggplot2"))
```

*(On Windows, `install.packages(c("readxl", "ggplot2"), type = "binary")` is recommended.)*

[`src/code.R`](src/code.R) does not execute automatic package installations (`install.packages()`); it verifies package availability at startup and stops cleanly if a dependency is missing.

---

## 5. Data Preparation and Path Configuration

After downloading the three `.xlsx` files (`Table_1_Authors_career_2025_pubs_since_1788_wopp_extracted_202608.xlsx`, `Table_1_Authors_singleyr_2025_pubs_since_1788_wopp_extracted_202608.xlsx`, and `CLASS_2025_07_02.xlsx`), you can provide their locations and configure an output directory in any of three ways **without modifying any analysis functions**:

### Option 1: Place Input Files in the Repository Root (Zero Configuration)

Place the three `.xlsx` files directly in the root of `scientific-impact-attribution/` (or inside a local `inputs/` subfolder). By default, generated tables and figures will be written to `./output/results_R/` and `./output/figures_R/`.

### Option 2: Pass Input and Output Directories via Command-Line Arguments

You can store the three `.xlsx` files in any folder on your computer and specify an external output directory when running `Rscript`:

```bash
# Pass <input_dir> and <output_dir>:
Rscript src/code.R "/path/to/downloaded_xlsx_folder" "/path/to/external_output_folder"

# Or pass the three exact workbook paths followed by <output_dir>:
Rscript src/code.R \
  "/path/to/Table_1_Authors_career_2025_pubs_since_1788_wopp_extracted_202608.xlsx" \
  "/path/to/Table_1_Authors_singleyr_2025_pubs_since_1788_wopp_extracted_202608.xlsx" \
  "/path/to/CLASS_2025_07_02.xlsx" \
  "/path/to/external_output_folder"
```

### Option 3: Edit `user_config` at the Top of `src/code.R` (or Use Environment Variables)

In Section 1 of [`src/code.R`](src/code.R#L43-L49), set `user_config$input_dir` (or individual file paths `career_xlsx`, `singleyr_xlsx`, `wb_income_xlsx`) and `user_config$output_dir`. Alternatively, set environment variables `SIA_INPUT_DIR`, `SIA_OUTPUT_DIR`, `SIA_CAREER_XLSX`, `SIA_SINGLEYR_XLSX`, and `SIA_WB_XLSX`.

---

## 6. Reproducing the Analyses

From the root directory of the repository, run:

```bash
Rscript src/code.R
```

### Reference Verification Targets

When executed on the original Version 9 Ioannidis workbooks and World Bank FY2026 classification, [`src/code.R`](src/code.R) reproduces the exact benchmark values reported in the manuscript:

| Indicator | Career-Long Cohort | Single-Year Cohort (2025) |
| :--- | ---: | ---: |
| Original author records (`N_raw`) | 243,949 | 249,310 |
| Paired analytical sample (`N_paired`, both countries available) | 243,697 | 249,140 |
| Excluded records (missing country under A or B) | 252 | 170 |
| Researchers with discordant country assignments ($A \neq B$) | 16,876 | 19,800 |
| Attribution discordance (%) | 6.92% | 7.95% |
| Distinct country codes represented (union of A and B) | 180 | 174 |
| Income-classified sample (both countries mapped to FY2026 groups) | 243,614 | 248,785 |
| Researchers retaining the same income group under A and B | 239,215 (98.19%) | 241,690 (97.15%) |

#### Geographical Concentration Benchmarks

| Concentration Metric | Scenario A (Recent Affiliation) | Scenario B (Predominant Career Country) |
| :--- | ---: | ---: |
| **Career-long HHI** | 0.161833 | 0.166376 |
| **Career-long Gini** | 0.916539 | 0.919915 |
| **Career-long Top-10 country share** | 76.88% | 77.53% |
| **Single-year (2025) HHI** | 0.124777 | 0.126535 |
| **Single-year (2025) Gini** | 0.902334 | 0.904840 |
| **Single-year (2025) Top-10 country share** | 74.14% | 74.51% |

---

## 7. Output Files

Executing [`src/code.R`](src/code.R) creates two subdirectories inside the configured output directory (`<output_dir>/results_R/` and `<output_dir>/figures_R/`):

### A. Manuscript Main Tables (`<output_dir>/results_R/`)

| Generated CSV File | Technical Companion File | Manuscript Target Reproduced |
| :--- | :--- | :--- |
| `Table_1_analytical_sample_and_discordance.csv` | `summary.csv` | **Table 1.** Analytical sample and geographical attribution discordance under alternative country-assignment rules (also provides HHI, Gini, and top-10 shares for **Figure 2**). |
| `Table_2_income_group_distribution.csv` | `income_groups.csv` | **Table 2.** Distribution of researchers across World Bank FY2026 income groups under Scenarios A and B, net change ($B - A$), and percentage change (also feeds **Figure 3**). |

### B. Manuscript Figures (`<output_dir>/figures_R/`)

All four figures are exported automatically in both high-resolution PNG (`180 dpi`, white background, no gridlines) and editable vector SVG formats:

| Figure Files (`.png` & `.svg`) | Manuscript Target and Visual Specification |
| :--- | :--- |
| `Figure_1_country_changes.png`<br>`Figure_1_country_changes.svg` | **Figure 1.** National changes in researcher attribution ($B - A$) in the career-long cohort for the 25 countries with the largest absolute changes among those with $N_A \ge 100$ (increases in blue `#1F77B4`, decreases in red `#CF624B`). |
| `Figure_2_concentration.png`<br>`Figure_2_concentration.svg` | **Figure 2.** Two-panel comparison of geographical concentration across cohorts under Scenario A (`#6674A4`) and Scenario B (`#45917F`): Panel A shows the Herfindahl–Hirschman Index (HHI) and Panel B shows the Gini coefficient with preserved y-axis zoom limits. |
| `Figure_3_income_groups.png`<br>`Figure_3_income_groups.svg` | **Figure 3.** Two-panel horizontal bar chart of net researcher count changes ($B - A$) across World Bank FY2026 income groups for the career-long cohort and the 2025 single-year citation cohort. |
| `Figure_4_income_transitions.png`<br>`Figure_4_income_transitions.svg` | **Figure 4.** $4 \times 4$ cross-income attribution matrix for the career-long cohort (rows: Scenario A; columns: Scenario B), shaded by $\log_{10}(N + 1)$ with exact researcher counts printed in each cell. |

### C. Additional Technical and Diagnostic Outputs (`<output_dir>/results_R/`)

- `Table_S1_country_changes.csv` – `Table_S7_cosmo_discordance.csv` (and technical aliases `country_changes.csv`, `income_transitions.csv`, `income_discordance.csv`, `field_discordance.csv`, `subfield_discordance.csv`, `publication_cohorts.csv`, `cosmo_discordance.csv`): Re-generated supplementary tables, automatically validated against [`supplementary material/`](supplementary%20material/).
- `bilateral_disagreements.csv`: Directed counts of discordant country pairs `(country_a, country_b)` for both cohorts.
- `coverage_sensitivity.csv` & `dominance_sensitivity.csv`: Subset summaries across `cntry_cov` ($\ge 0.50, 0.80, 0.90$) and `top_cntry_share` ($\ge 0.50, 0.75$) thresholds.
- `multinational_footprint.csv`: Number of authors listing each country at the $\ge 10\%$ career publication threshold (`cntry_10pct`).
- `unmapped_income_codes.csv` & `missingness.csv`: Documentation of country codes without an FY2026 World Bank income group and variable-level missingness in raw records.
- `wb_income_fy26_codebook.csv`: Standardized ISO-3 code, economy name, region, and FY2026 income group lookup table.

---

## 8. Supplementary Materials (S1–S7)

The [`supplementary material/`](supplementary%20material/) directory contains the seven individual CSV files cited in the manuscript:

| ID | File in `supplementary material/` | Scientific Content | Rows (excl. header) | Key Variables |
| :--- | :--- | :--- | ---: | :--- |
| **S1** | [`Table_S1_country_changes.csv`](supplementary%20material/Table_S1_country_changes.csv) | National researcher counts under Scenarios A and B, absolute changes ($\Delta = B - A$), relative and symmetric percentage changes, rankings (`rank_A`, `rank_B`), rank shifts, World Bank FY2026 income group, and region for both cohorts (180 countries in `career`; 174 in `singleyr`). | 354 | `code`, `N_A`, `N_B`, `delta_B_minus_A`, `pct_change_from_A`, `symmetric_change_pct`, `rank_A`, `rank_B`, `rank_change_A_minus_B`, `income_group`, `region`, `cohort` |
| **S2** | [`Table_S2_income_transitions.csv`](supplementary%20material/Table_S2_income_transitions.csv) | Complete $4 \times 4$ World Bank FY2026 income-group transition matrices between Scenario A (`income_A`) and Scenario B (`income_B`) for both cohorts. | 32 | `income_A`, `income_B`, `N`, `cohort` |
| **S3** | [`Table_S3_income_discordance.csv`](supplementary%20material/Table_S3_income_discordance.csv) | Country-level attribution discordance counts and percentages stratified by Scenario A World Bank FY2026 income group for both cohorts. | 8 | `cohort`, `income_group_A`, `N`, `N_discordant`, `discordance_pct` |
| **S4** | [`Table_S4_field_discordance.csv`](supplementary%20material/Table_S4_field_discordance.csv) | Geographical attribution discordance across the 20 Science-Metrix primary scientific fields (`sm-field`) for both cohorts. | 40 | `field`, `N`, `N_discordant`, `discordance_pct`, `cohort` |
| **S5** | [`Table_S5_subfield_discordance.csv`](supplementary%20material/Table_S5_subfield_discordance.csv) | Geographical attribution discordance across 174 Science-Metrix primary scientific subfields (`sm-subfield-1`) for both cohorts. | 348 | `subfield`, `N`, `N_discordant`, `discordance_pct`, `cohort` |
| **S6** | [`Table_S6_publication_cohorts.csv`](supplementary%20material/Table_S6_publication_cohorts.csv) | Geographical attribution discordance stratified by first-publication year cohort (`Before 1992`, `1992-2001`, `2002-2011`, `2012 or later`) derived from `firstyr`. | 8 | `publication_cohort`, `N`, `N_discordant`, `discordance_pct`, `cohort` |
| **S7** | [`Table_S7_cosmo_discordance.csv`](supplementary%20material/Table_S7_cosmo_discordance.csv) | Geographical attribution discordance stratified by the database's binary scientific cosmopolitanism classification (`cosmo`: `0` vs. `1`). | 4 | `cosmo`, `N`, `N_discordant`, `discordance_pct`, `cohort` |

---

## 9. Methodological Notes

1. **Scenario Definitions:**
   - **Scenario A (`cntry`):** Assigns each researcher to the country of their most recently recorded institutional affiliation in Scopus.
   - **Scenario B (`top_cntry_career`):** Assigns each researcher to the predominant country across their career eligible publications (defined in the Ioannidis database as publications associated with one or two countries).
2. **Directional Convention ($B - A$):**
   - Throughout the code, tables, and figures, all differences in researcher counts are defined as $\Delta = N_B - N_A$. Positive values indicate that a country or income group gains attributed researchers when moving from Scenario A (recent affiliation) to Scenario B (predominant career publication country); negative values indicate a reduction under Scenario B.
3. **Single-Country Attribution vs. Fractional Counting:**
   - Both Scenario A and Scenario B assign each researcher as a single unit to one country per scenario. Predominant-country attribution (Scenario B) is therefore a whole-researcher reclassification rule and **does not** represent fractional allocation of publication or citation credit across multiple countries.
4. **Multinational Publication Profiles vs. Migration:**
   - The cosmopolitanism indicator (`cosmo = 1`, identifying authors for whom at least two countries each account for $\ge 10\%$ of eligible career publications) and discordance between Scenarios A and B capture cross-national publication and affiliation structures. They **do not** necessarily indicate physical migration, permanent relocation, or brain drain, as multi-country publication records can also arise from international co-authorship, dual appointments, or institutional country-enrichment heuristics (which carry an estimated ~4% classification error rate in the source database; Ioannidis & Baas, 2026).

---

## 10. Reproducibility and Verification

- **Deterministic Execution:** All calculations are purely descriptive and deterministic (no stochastic sampling or simulation).
- **Automated Consistency Check:** Whenever [`src/code.R`](src/code.R) is executed with the input workbooks, it automatically compares the newly computed tables against the seven reference CSV files in [`supplementary material/`](supplementary%20material/) (`verify_against_supplementary_csvs()`) and verifies column names, dimensions, country codes, and numerical equivalence to within floating-point tolerance (`1e-9`).
- **Verification Status:** The analytical script [`src/code.R`](src/code.R) has been syntax-checked, statically audited against the original analytical workflow, and cross-validated against [`supplementary material/Table_S1_country_changes.csv`](supplementary%20material/Table_S1_country_changes.csv) through [`Table_S7_cosmo_discordance.csv`](supplementary%20material/Table_S7_cosmo_discordance.csv) and all manuscript tables. Because the raw external Excel workbooks are not hosted inside the repository, users must download the three source `.xlsx` files locally to perform a full end-to-end execution from raw data.

---

## 11. GitHub / Zenodo Repository Checklist

- [x] 1. Final R script: clean, documented and reproducible.
- [x] 2. README with complete execution instructions.
- [x] 3. Seven supplementary CSV files (S1–S7).
- [x] 4. Technical output files required to reproduce manuscript tables.
- [x] 5. Code for reproducing all four manuscript figures.
- [x] 6. Dependency specification and package versions.
- [x] 7. Formal citation of the original Ioannidis dataset.
- [ ] 8. DOI of the archived repository version on Zenodo *(pending Zenodo archive release)*.

---

## 12. Citation

Please distinguish between citing the original underlying datasets, the study manuscript, and this reproducibility repository:

### 1. Original Ioannidis Dataset (Version 9)

> Ioannidis, J. P. A. (2026). *August 2026 data-update for "Updated science-wide author databases of standardized citation indicators"* (Version 9) [Dataset]. Elsevier Data Repository. https://doi.org/10.17632/btchxktzyw.9

### 2. World Bank FY2026 Income Classification

> World Bank. (2025). *World Bank Country and Lending Groups: Historical classification by income (FY2026, `CLASS_2025_07_02.xlsx`)* [Dataset]. World Bank Group. https://datahelpdesk.worldbank.org/knowledgebase/articles/906519-world-bank-country-and-lending-groups (Reproducibility package catalog reference: https://reproducibility.worldbank.org/catalog/624)

### 3. Study Manuscript

> Acosta-Monterrosa, A. A. (2026). *Whose scientific impact? How country attribution rules shape the geography of highly cited researchers*. *(Manuscript submitted for publication)*.

### 4. Reproducibility Repository

> Acosta-Monterrosa, A. A. (2026). *Reproducibility repository for "Whose Scientific Impact? Cross-National Affiliations and the Geography of Highly Cited Researchers"* [Software and supplementary datasets]. GitHub. https://github.com/AndyPaaai/scientific-impact-attribution

---

## 13. License and Data Reuse Conditions

- **Repository Code:** The analytical code in this repository is licensed under the **MIT License** (see [`LICENSE`](LICENSE), Copyright (c) 2026 Andy A. Acosta-Monterrosa).
- **External Input Datasets:** The standardized citation database by Ioannidis (2026, Version 9; https://doi.org/10.17632/btchxktzyw.9) is distributed via the Elsevier Data Repository under its published license and Scopus data terms. The World Bank income classification (`CLASS_2025_07_02.xlsx`) is subject to the World Bank Open Data Terms of Use.

---

## 14. Zenodo Archive

A permanent versioned snapshot of this repository will be archived on Zenodo upon publication of the GitHub release:

- **Zenodo DOI:** *Pending archival release on Zenodo.*

---

## 15. Contact and Authorship

- **Author:** Andy A. Acosta-Monterrosa
- **Repository:** https://github.com/AndyPaaai/scientific-impact-attribution
