# Whose Scientific Impact? Cross-National Affiliations and the Geography of Highly Cited Researchers

Reproducibility repository for the study:

> **Whose Scientific Impact? Cross-National Affiliations and the Geography of Highly Cited Researchers**  
> *(Manuscript title: Whose scientific impact? How country attribution rules shape the geography of highly cited researchers)*

---

## 1. Overview

This repository provides the analytical R script ([`src/code.R`](src/code.R)) and the seven supplementary datasets ([`supplementary material/`](supplementary%20material/)) examining how two researcher-level country-attribution rules affect the geographical distribution of highly cited researchers in Version 9 (August 2026) of the science-wide citation indicators database (Ioannidis, 2026):

- **Scenario A (`cntry`):** Most recent institutional affiliation country recorded in Scopus.
- **Scenario B (`top_cntry_career`):** Predominant country across career eligible publications (publications with one or two country affiliations).

Analyses are performed independently for the **career-long** ($N = 243,949$; paired sample $n = 243,697$) and **single-year 2025** ($N = 249,310$; paired sample $n = 249,140$) cohorts, evaluating attribution discordance, national counts and rank shifts ($\Delta = B - A$), geographical concentration (HHI, Gini, top-10 share), World Bank FY2026 income-group redistributions and transitions, and stratified discordance across fields, subfields, publication-start cohorts, and scientific cosmopolitanism (`cosmo`).

---

## 2. Data Sources

The three original Excel workbooks are not hosted in this repository and must be downloaded from their official sources:

1. **Ioannidis Science-Wide Author Databases (Version 9, August 2026)**
   - **DOI:** https://doi.org/10.17632/btchxktzyw.9 (Elsevier Data Repository)
   - **Required files (data read from sheet `Data`):**
     - Career-long cohort: `Table_1_Authors_career_2025_pubs_since_1788_wopp_extracted_202608.xlsx`
     - Single-year (2025) cohort: `Table_1_Authors_singleyr_2025_pubs_since_1788_wopp_extracted_202608.xlsx`
     *(Files with `02-` and `03-` prefixes from the archive are detected automatically.)*

2. **World Bank Country Income Classification (Fiscal Year 2026)**
   - **Required file (sheet `List of economies`):** `CLASS_2025_07_02.xlsx`
   - **Sources:** [World Bank Country and Lending Groups](https://datahelpdesk.worldbank.org/knowledgebase/articles/906519-world-bank-country-and-lending-groups) | [World Bank Reproducibility Package #624](https://reproducibility.worldbank.org/catalog/624)
   - **Note:** Use strictly the **FY2026** classification (`CLASS_2025_07_02.xlsx`); do not substitute it with newer fiscal-year releases.

---

## 3. Repository Structure

```text
scientific-impact-attribution/
├── README.md
├── DEPENDENCIES.md
├── LICENSE
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

---

## 4. Requirements and Installation

- **R:** `>= 4.2.0` (tested on **R 4.4.2**)
- **CRAN packages:** `readxl` (`1.4.3`), `ggplot2` (`3.5.1`) (plus base R `grid`, `grDevices`, `stats`, `utils`)

[`src/code.R`](src/code.R) checks for dependencies at startup and does not install packages automatically. Install them once in R (see [`DEPENDENCIES.md`](DEPENDENCIES.md)):

```r
install.packages(c("readxl", "ggplot2"))
```

---

## 5. Configuration and Execution

You can provide the locations of the three downloaded `.xlsx` files and an output directory without modifying any analytical functions:

1. **Default directory:** Place the three `.xlsx` files in the repository root and run:
   ```bash
   Rscript src/code.R
   ```
2. **Command-line paths:** Pass your local input folder and external output folder:
   ```bash
   Rscript src/code.R "/path/to/inputs" "/path/to/output_dir"
   ```
3. **Configuration block:** Edit `user_config` at the top of [`src/code.R`](src/code.R#L43-L49) (or set environment variables `SIA_INPUT_DIR` and `SIA_OUTPUT_DIR`).

### Reference Benchmarks

| Indicator | Career-Long | Single-Year (2025) |
| :--- | ---: | ---: |
| Original records / Paired sample | 243,949 / 243,697 | 249,310 / 249,140 |
| Discordant assignments ($A \neq B$) | 16,876 (6.92%) | 19,800 (7.95%) |
| Income-classified sample / Same income group | 243,614 / 239,215 (98.19%) | 248,785 / 241,690 (97.15%) |
| HHI (Scenario A $\rightarrow$ Scenario B) | 0.161833 $\rightarrow$ 0.166376 | 0.124777 $\rightarrow$ 0.126535 |
| Gini (Scenario A $\rightarrow$ Scenario B) | 0.916539 $\rightarrow$ 0.919915 | 0.902334 $\rightarrow$ 0.904840 |

---

## 6. Generated Outputs

Running [`src/code.R`](src/code.R) writes all outputs to `<output_dir>/results_R/` and `<output_dir>/figures_R/`:

- **Manuscript tables (`results_R/`):**
  - `Table_1_analytical_sample_and_discordance.csv` (and `summary.csv`) $\rightarrow$ **Table 1** & **Figure 2**
  - `Table_2_income_group_distribution.csv` (and `income_groups.csv`) $\rightarrow$ **Table 2** & **Figure 3**
  - `Table_S1_country_changes.csv` – `Table_S7_cosmo_discordance.csv` (automatically verified against [`supplementary material/`](supplementary%20material/)) and diagnostic CSVs (`bilateral_disagreements.csv`, `coverage_sensitivity.csv`, `dominance_sensitivity.csv`, `multinational_footprint.csv`, `unmapped_income_codes.csv`, `missingness.csv`, `wb_income_fy26_codebook.csv`).
- **Manuscript figures (`figures_R/`, exported in 180 DPI `.png` and vector `.svg`):**
  - `Figure_1_country_changes` (**Figure 1:** Top 25 national researcher changes $B - A$ in career cohort, $N_A \ge 100$)
  - `Figure_2_concentration` (**Figure 2:** Two-panel HHI and Gini comparison across cohorts and scenarios)
  - `Figure_3_income_groups` (**Figure 3:** Two-panel net changes $B - A$ across World Bank FY2026 income groups)
  - `Figure_4_income_transitions` (**Figure 4:** Career $4 \times 4$ cross-income attribution matrix with $\log_{10}(N + 1)$ shading)

---

## 7. Supplementary Materials (S1–S7)

| ID | File in `supplementary material/` | Description |
| :--- | :--- | :--- |
| **S1** | [`Table_S1_country_changes.csv`](supplementary%20material/Table_S1_country_changes.csv) | National counts ($N_A, N_B$), changes ($B - A$, %, symmetric %), ranks, and FY2026 income/region for both cohorts. |
| **S2** | [`Table_S2_income_transitions.csv`](supplementary%20material/Table_S2_income_transitions.csv) | $4 \times 4$ World Bank FY2026 income-group transition matrices between Scenarios A and B. |
| **S3** | [`Table_S3_income_discordance.csv`](supplementary%20material/Table_S3_income_discordance.csv) | Attribution discordance counts and percentages by Scenario A income group. |
| **S4** | [`Table_S4_field_discordance.csv`](supplementary%20material/Table_S4_field_discordance.csv) | Attribution discordance across 20 primary scientific fields (`sm-field`). |
| **S5** | [`Table_S5_subfield_discordance.csv`](supplementary%20material/Table_S5_subfield_discordance.csv) | Attribution discordance across 174 primary scientific subfields (`sm-subfield-1`). |
| **S6** | [`Table_S6_publication_cohorts.csv`](supplementary%20material/Table_S6_publication_cohorts.csv) | Attribution discordance across first-publication cohorts (`Before 1992`, `1992-2001`, `2002-2011`, `2012 or later`). |
| **S7** | [`Table_S7_cosmo_discordance.csv`](supplementary%20material/Table_S7_cosmo_discordance.csv) | Attribution discordance by scientific cosmopolitanism indicator (`cosmo`: `0` vs. `1`). |

---

## 8. Methodological Notes

- **Direction of differences ($B - A$):** All net changes represent the shift when moving from Scenario A (recent affiliation) to Scenario B (predominant career country).
- **Interpretation:** Predominant-country attribution assigns each researcher as a single unit and does not constitute fractional credit allocation. Multinational publication profiles (`cosmo = 1`) and scenario discordance reflect cross-national publication structures rather than confirmed physical migration.

---

## 9. GitHub / Zenodo Repository Checklist

- [x] 1. Final R script: clean, documented and reproducible.
- [x] 2. README with complete execution instructions.
- [x] 3. Seven supplementary CSV files (S1–S7).
- [x] 4. Technical output files required to reproduce manuscript tables.
- [x] 5. Code for reproducing all four manuscript figures.
- [x] 6. Dependency specification and package versions.
- [x] 7. Formal citation of the original Ioannidis dataset.
- [ ] 8. DOI of the archived repository version on Zenodo *(pending Zenodo archive release)*.

---

## 10. Citations, License, and Contact

- **Ioannidis Dataset:** Ioannidis, J. P. A. (2026). *August 2026 data-update for "Updated science-wide author databases of standardized citation indicators"* (Version 9) [Dataset]. Elsevier Data Repository. https://doi.org/10.17632/btchxktzyw.9
- **World Bank Classification:** World Bank. (2025). *World Bank Country and Lending Groups: Historical classification by income (FY2026, `CLASS_2025_07_02.xlsx`)* [Dataset]. https://datahelpdesk.worldbank.org/knowledgebase/articles/906519-world-bank-country-and-lending-groups (Catalog reference: https://reproducibility.worldbank.org/catalog/624)
- **Study & Repository:** Acosta-Monterrosa, A. A. (2026). *Whose scientific impact? How country attribution rules shape the geography of highly cited researchers*. Code and supplementary data: https://github.com/AndyPaaai/scientific-impact-attribution (Zenodo DOI: *Pending archival release*).
- **License:** Repository code is licensed under the [MIT License](LICENSE). Original datasets remain subject to Elsevier Data Repository and World Bank Open Data terms.
- **Author:** Andy A. Acosta-Monterrosa
