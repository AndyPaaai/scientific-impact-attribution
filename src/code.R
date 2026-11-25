# ==============================================================================
# Whose Scientific Impact? Cross-National Affiliations and the Geography of
# Highly Cited Researchers
#
# Reproducible R implementation of the bibliometric analysis, manuscript tables,
# supplementary tables (S1-S7), and manuscript figures (Figures 1-4).
#
# Requirements:
#   - R >= 4.2 (tested with R 4.4.2)
#   - CRAN packages: readxl, ggplot2
#   - Base R packages: grid, grDevices, stats, utils
#
# Input datasets (read-only; must be obtained from official sources):
#   1. Ioannidis (2026), Version 9 (August 2026 data-update), career-long cohort:
#      Table_1_Authors_career_2025_pubs_since_1788_wopp_extracted_202608.xlsx
#      (DOI: https://doi.org/10.17632/btchxktzyw.9)
#   2. Ioannidis (2026), Version 9 (August 2026 data-update), single-year 2025 cohort:
#      Table_1_Authors_singleyr_2025_pubs_since_1788_wopp_extracted_202608.xlsx
#      (DOI: https://doi.org/10.17632/btchxktzyw.9)
#   3. World Bank FY2026 country income classification workbook:
#      CLASS_2025_07_02.xlsx
#
# Usage from repository root:
#   Rscript src/code.R
#   Rscript src/code.R <input_dir> <output_dir>
#   Rscript src/code.R <career_xlsx> <singleyr_xlsx> <wb_income_xlsx> <output_dir>
# ==============================================================================


# ------------------------------------------------------------------------------
# 1. USER CONFIGURATION
# ------------------------------------------------------------------------------
# Researchers can configure the locations of the three downloaded input files
# and the output directory using any of three methods (without modifying any
# analytical functions below):
#
# Method A - Edit the paths in `user_config` below (set full paths or leave as
#            NA_character_ to use automatic relative resolution).
# Method B - Pass command-line arguments to Rscript:
#            Rscript src/code.R "/path/to/inputs" "/path/to/outputs"
#            Rscript src/code.R "/path/to/career.xlsx" "/path/to/singleyr.xlsx" "/path/to/CLASS_2025_07_02.xlsx" "/path/to/outputs"
# Method C - Set environment variables before running Rscript:
#            SIA_INPUT_DIR, SIA_OUTPUT_DIR, SIA_CAREER_XLSX, SIA_SINGLEYR_XLSX, SIA_WB_XLSX

user_config <- list(
  input_dir      = NA_character_,  # Directory containing the three input .xlsx files
  career_xlsx    = NA_character_,  # Direct path to career-long Ioannidis workbook
  singleyr_xlsx  = NA_character_,  # Direct path to single-year (2025) Ioannidis workbook
  wb_income_xlsx = NA_character_,  # Direct path to CLASS_2025_07_02.xlsx
  output_dir     = NA_character_   # Directory where results and figures will be written
)

expected_filenames <- list(
  career    = "Table_1_Authors_career_2025_pubs_since_1788_wopp_extracted_202608.xlsx",
  singleyr  = "Table_1_Authors_singleyr_2025_pubs_since_1788_wopp_extracted_202608.xlsx",
  wb_income = "CLASS_2025_07_02.xlsx"
)


# ------------------------------------------------------------------------------
# 2. DEPENDENCY VERIFICATION
# ------------------------------------------------------------------------------
# Automatic package installation is intentionally disabled to ensure
# deterministic execution and prevent session restarts.

check_required_packages <- function(packages) {
  missing_pkgs <- packages[
    !vapply(packages, requireNamespace, logical(1), quietly = TRUE)
  ]
  if (length(missing_pkgs) > 0L) {
    stop(
      paste0(
        "Missing required R package(s): ",
        paste(missing_pkgs, collapse = ", "),
        ".\nPlease install them manually in R before running this script:\n",
        "  install.packages(c(",
        paste(sprintf("\"%s\"", missing_pkgs), collapse = ", "),
        "))\n",
        "See DEPENDENCIES.md for environment details and package versions."
      ),
      call. = FALSE
    )
  }
}

required_packages <- c("readxl", "ggplot2")
check_required_packages(required_packages)

suppressPackageStartupMessages({
  library(readxl)
  library(ggplot2)
})


# ------------------------------------------------------------------------------
# 3. PATH RESOLUTION AND INPUT VALIDATION
# ------------------------------------------------------------------------------
# Resolves script location, repository root, input workbooks, and output folders
# portably across Windows, macOS, and Linux.

get_script_dir <- function() {
  cmd_args <- commandArgs(trailingOnly = FALSE)
  file_arg <- grep("^--file=", cmd_args, value = TRUE)
  if (length(file_arg) > 0L) {
    script_path <- sub("^--file=", "", file_arg[[1]])
    return(dirname(normalizePath(script_path, mustWork = FALSE)))
  }
  frame_files <- vapply(sys.frames(), function(f) {
    if (!is.null(f$ofile)) as.character(f$ofile) else NA_character_
  }, character(1))
  frame_files <- frame_files[!is.na(frame_files)]
  if (length(frame_files) > 0L) {
    return(dirname(normalizePath(tail(frame_files, 1), mustWork = FALSE)))
  }
  normalizePath(getwd(), mustWork = FALSE)
}

get_repo_root <- function(script_dir) {
  if (tolower(basename(script_dir)) == "src") {
    return(normalizePath(file.path(script_dir, ".."), mustWork = FALSE))
  }
  normalizePath(script_dir, mustWork = FALSE)
}

non_empty_string <- function(x) {
  !is.null(x) && length(x) == 1L && !is.na(x) && nzchar(trimws(x))
}

first_defined <- function(...) {
  candidates <- list(...)
  for (item in candidates) {
    if (non_empty_string(item)) return(trimws(item))
  }
  NA_character_
}

strip_numeric_prefix <- function(filename) {
  sub("^[0-9]{2}-", "", basename(filename))
}

find_workbook <- function(expected_name, explicit_path, search_dirs) {
  if (non_empty_string(explicit_path)) {
    if (!file.exists(explicit_path)) {
      stop(
        paste0("Configured input file does not exist: ", explicit_path),
        call. = FALSE
      )
    }
    return(normalizePath(explicit_path, mustWork = TRUE))
  }

  existing_dirs <- unique(search_dirs[dir.exists(search_dirs)])
  target_canonical <- tolower(strip_numeric_prefix(expected_name))

  # First check direct file matches in candidate directories
  for (d in existing_dirs) {
    direct_candidates <- file.path(
      d,
      unique(c(expected_name, paste0("02-", expected_name), paste0("03-", expected_name)))
    )
    hit <- direct_candidates[file.exists(direct_candidates)]
    if (length(hit) == 1L) {
      return(normalizePath(hit[[1]], mustWork = TRUE))
    }
  }

  # Fallback: recursive search within the primary input directory
  if (length(existing_dirs) > 0L) {
    all_xlsx <- list.files(
      existing_dirs[[1]],
      pattern = "\\.xlsx$",
      recursive = TRUE,
      full.names = TRUE,
      ignore.case = TRUE
    )
    matches <- all_xlsx[tolower(strip_numeric_prefix(all_xlsx)) == target_canonical]
    if (length(matches) == 1L) {
      return(normalizePath(matches[[1]], mustWork = TRUE))
    }
    if (length(matches) > 1L) {
      stop(
        paste0(
          "Multiple copies of '", expected_name, "' were found:\n  ",
          paste(matches, collapse = "\n  "),
          "\nPlease specify an unambiguous path in user_config or command-line arguments."
        ),
        call. = FALSE
      )
    }
  }

  stop(
    paste0(
      "Required input file not found: ", expected_name, "\n",
      "Searched in:\n  ",
      paste(existing_dirs, collapse = "\n  "), "\n\n",
      "To run the analysis:\n",
      "  1. Download the official input files listed in README.md:\n",
      "     - Ioannidis V9 (2026): https://doi.org/10.17632/btchxktzyw.9\n",
      "     - World Bank FY2026 (CLASS_2025_07_02.xlsx): https://reproducibility.worldbank.org/catalog/624\n",
      "  2. Place them in the repository root (or a local input folder), OR\n",
      "  3. Set their paths in `user_config` at the top of src/code.R, OR\n",
      "  4. Pass the input and output directories via command line:\n",
      "     Rscript src/code.R \"/path/to/inputs\" \"/path/to/outputs\""
    ),
    call. = FALSE
  )
}

resolve_runtime_paths <- function(cfg, expected) {
  script_dir <- get_script_dir()
  repo_root  <- get_repo_root(script_dir)
  cli_args   <- commandArgs(trailingOnly = TRUE)

  cli_input_dir  <- NA_character_
  cli_output_dir <- NA_character_
  cli_career     <- NA_character_
  cli_singleyr   <- NA_character_
  cli_wb         <- NA_character_

  if (length(cli_args) == 1L) {
    cli_input_dir <- cli_args[[1]]
  } else if (length(cli_args) == 2L) {
    cli_input_dir  <- cli_args[[1]]
    cli_output_dir <- cli_args[[2]]
  } else if (length(cli_args) == 3L) {
    if (dir.exists(cli_args[[1]]) && dir.exists(cli_args[[2]])) {
      # Compatibility with legacy 3-argument signature: project_dir input_dir output_dir
      cli_input_dir  <- cli_args[[2]]
      cli_output_dir <- cli_args[[3]]
    } else {
      cli_career   <- cli_args[[1]]
      cli_singleyr <- cli_args[[2]]
      cli_wb       <- cli_args[[3]]
    }
  } else if (length(cli_args) >= 4L) {
    cli_career     <- cli_args[[1]]
    cli_singleyr   <- cli_args[[2]]
    cli_wb         <- cli_args[[3]]
    cli_output_dir <- cli_args[[4]]
  }

  input_dir <- first_defined(
    cli_input_dir,
    cfg$input_dir,
    Sys.getenv("SIA_INPUT_DIR", unset = ""),
    repo_root
  )

  if (non_empty_string(cli_input_dir) && !dir.exists(cli_input_dir)) {
    stop(paste0("Specified input directory does not exist: ", cli_input_dir), call. = FALSE)
  }

  search_dirs <- unique(c(
    input_dir,
    repo_root,
    file.path(repo_root, "inputs"),
    file.path(repo_root, "data"),
    script_dir,
    getwd()
  ))

  career_path <- find_workbook(
    expected_name = expected$career,
    explicit_path = first_defined(cli_career, cfg$career_xlsx, Sys.getenv("SIA_CAREER_XLSX", unset = "")),
    search_dirs   = search_dirs
  )
  singleyr_path <- find_workbook(
    expected_name = expected$singleyr,
    explicit_path = first_defined(cli_singleyr, cfg$singleyr_xlsx, Sys.getenv("SIA_SINGLEYR_XLSX", unset = "")),
    search_dirs   = search_dirs
  )
  wb_path <- find_workbook(
    expected_name = expected$wb_income,
    explicit_path = first_defined(cli_wb, cfg$wb_income_xlsx, Sys.getenv("SIA_WB_XLSX", unset = "")),
    search_dirs   = search_dirs
  )

  output_root <- first_defined(
    cli_output_dir,
    cfg$output_dir,
    Sys.getenv("SIA_OUTPUT_DIR", unset = ""),
    file.path(repo_root, "output")
  )

  results_dir <- file.path(output_root, "results_R")
  figures_dir <- file.path(output_root, "figures_R")

  dir.create(results_dir, recursive = TRUE, showWarnings = FALSE)
  dir.create(figures_dir, recursive = TRUE, showWarnings = FALSE)

  if (!dir.exists(results_dir) || !dir.exists(figures_dir)) {
    stop(
      paste0("Could not create output directories inside: ", output_root),
      call. = FALSE
    )
  }

  list(
    script_dir  = script_dir,
    repo_root   = repo_root,
    input_paths = c(career = career_path, singleyr = singleyr_path),
    income_file = wb_path,
    output_root = normalizePath(output_root, mustWork = TRUE),
    results_dir = normalizePath(results_dir, mustWork = TRUE),
    figures_dir = normalizePath(figures_dir, mustWork = TRUE),
    supp_dir    = file.path(repo_root, "supplementary material")
  )
}


# ------------------------------------------------------------------------------
# 4. DATA IMPORT AND STANDARDIZATION FUNCTIONS
# ------------------------------------------------------------------------------
# Standardizes ISO-3 country codes to uppercase and treats blank or sentinel
# strings as missing (NA_character_). Reads only the required columns from the
# 'Data' sheet of each Ioannidis workbook to minimize memory consumption.

income_levels <- c(
  "Low income",
  "Lower middle income",
  "Upper middle income",
  "High income"
)

normalize_country_code <- function(v) {
  x <- toupper(trimws(as.character(v)))
  x[is.na(x) | x %in% c("", "NA", "N/A", "NONE")] <- NA_character_
  x
}

read_author_table <- function(path) {
  headers <- names(readxl::read_xlsx(path, sheet = "Data", n_max = 0))
  text_fields <- c("cntry", "top_cntry_career", "cntry_10pct", "sm-field", "sm-subfield-1")
  num_fields  <- c("firstyr", "cosmo", "n_cntry_10pct", "top_cntry_share", "cntry_cov")
  required_fields <- c(text_fields, num_fields)

  missing_cols <- setdiff(required_fields, headers)
  if (length(missing_cols) > 0L) {
    stop(
      paste0(
        "Workbook '", basename(path), "' is missing expected column(s) in sheet 'Data': ",
        paste(missing_cols, collapse = ", ")
      ),
      call. = FALSE
    )
  }

  col_types <- ifelse(
    headers %in% text_fields, "text",
    ifelse(headers %in% num_fields, "numeric", "skip")
  )
  raw_df <- readxl::read_xlsx(path, sheet = "Data", col_types = col_types, na = c("", "NA"))

  data.frame(
    country_a         = normalize_country_code(raw_df$cntry),
    country_b         = normalize_country_code(raw_df$top_cntry_career),
    firstyr           = as.numeric(raw_df$firstyr),
    cosmo             = as.numeric(raw_df$cosmo),
    n_countries_10pct = as.numeric(raw_df$n_cntry_10pct),
    countries_10pct   = trimws(as.character(raw_df$cntry_10pct)),
    top_country_share = as.numeric(raw_df$top_cntry_share),
    country_coverage  = as.numeric(raw_df$cntry_cov),
    field             = trimws(as.character(raw_df[["sm-field"]])),
    subfield          = trimws(as.character(raw_df[["sm-subfield-1"]])),
    stringsAsFactors  = FALSE
  )
}

read_world_bank_classification <- function(income_file, valid_income_levels) {
  wb <- as.data.frame(readxl::read_xlsx(income_file, sheet = "List of economies"))
  wb$Code <- normalize_country_code(wb$Code)
  wb <- wb[!is.na(wb$Code) & !duplicated(wb$Code), ]

  income_lookup <- stats::setNames(as.character(wb[["Income group"]]), wb$Code)
  income_lookup[!income_lookup %in% valid_income_levels] <- NA_character_
  region_lookup <- stats::setNames(as.character(wb$Region), wb$Code)

  list(
    wb            = wb,
    income_lookup = income_lookup,
    region_lookup = region_lookup
  )
}


# ------------------------------------------------------------------------------
# 5. ANALYTICAL AND STATISTICAL FUNCTIONS
# ------------------------------------------------------------------------------
# Implements exact descriptive metrics used in the manuscript:
#   - Scenario A: most recent institutional affiliation country (`cntry`).
#   - Scenario B: predominant country across career publications (`top_cntry_career`).
#   - Directional differences are always expressed as B - A.
#   - Geographical concentration indices (HHI, Gini, and Top-10 share) are
#     evaluated over the union of country codes present under either scenario.

map_by_code <- function(code, lookup) {
  unname(lookup[match(code, names(lookup))])
}

count_codes <- function(x, levels = NULL) {
  t <- table(x, useNA = "no")
  if (is.null(levels)) return(t)
  result <- stats::setNames(integer(length(levels)), levels)
  result[names(t)] <- as.integer(t)
  result
}

compute_gini <- function(x) {
  x <- sort(as.numeric(x))
  n <- length(x)
  if (n == 0L || sum(x) == 0) return(NA_real_)
  sum((2 * seq_len(n) - n - 1) * x) / (n * sum(x))
}

compute_concentration <- function(d) {
  codes <- sort(union(unique(d$country_a), unique(d$country_b)))
  a <- count_codes(d$country_a, codes)
  b <- count_codes(d$country_b, codes)
  n <- nrow(d)
  data.frame(
    N               = n,
    countries_union = length(codes),
    hhi_A           = sum((a / n)^2),
    hhi_B           = sum((b / n)^2),
    gini_A          = compute_gini(a),
    gini_B          = compute_gini(b),
    top10_share_A   = sum(utils::tail(sort(a), 10)) / n,
    top10_share_B   = sum(utils::tail(sort(b), 10)) / n
  )
}

compute_discordance_by_group <- function(d, column, cohort) {
  labels <- as.character(d[[column]])
  labels[is.na(labels)] <- "NA"
  parts <- split(seq_len(nrow(d)), labels)
  result <- data.frame(
    key          = names(parts),
    N            = vapply(parts, length, integer(1)),
    N_discordant = vapply(parts, function(j) sum(d$discordant[j]), integer(1)),
    stringsAsFactors = FALSE
  )
  names(result)[1] <- column
  result$discordance_pct <- 100 * result$N_discordant / result$N
  result$cohort <- cohort
  row.names(result) <- NULL
  result
}

compute_subset_sensitivity <- function(d, mask, cohort, label) {
  sub <- d[which(mask %in% TRUE), , drop = FALSE]
  cbind(
    data.frame(
      cohort          = cohort,
      subset          = label,
      N_discordant    = sum(sub$discordant),
      discordance_pct = 100 * mean(sub$discordant),
      stringsAsFactors = FALSE
    ),
    compute_concentration(sub)
  )
}

classify_publication_cohort <- function(firstyr) {
  ifelse(
    is.na(firstyr), "Unknown",
    ifelse(
      firstyr <= 1991, "Before 1992",
      ifelse(
        firstyr <= 2001, "1992-2001",
        ifelse(firstyr <= 2011, "2002-2011", "2012 or later")
      )
    )
  )
}

write_csv_table <- function(df, name, out_dir) {
  row.names(df) <- NULL
  utils::write.csv(
    df,
    file         = file.path(out_dir, paste0(name, ".csv")),
    row.names    = FALSE,
    na           = "",
    fileEncoding = "UTF-8"
  )
}


# ------------------------------------------------------------------------------
# 6. COHORT ANALYSIS PIPELINE
# ------------------------------------------------------------------------------
# Processes each cohort independently:
#   - Documents missingness on raw records.
#   - Restricts paired comparisons to records with valid country_a and country_b.
#   - Computes country-level redistribution, concentration, bilateral flows,
#     income-group transitions, and stratified discordance tables.

analyze_cohort <- function(cohort, source_path, income_lookup, region_lookup, valid_income_levels) {
  d <- read_author_table(source_path)
  n_raw <- nrow(d)

  vars <- c("country_a", "country_b", "country_coverage", "top_country_share")
  missing_df <- data.frame(
    cohort   = cohort,
    variable = vars,
    missing  = vapply(vars, function(v) sum(is.na(d[[v]])), integer(1)),
    N_raw    = n_raw,
    stringsAsFactors = FALSE
  )
  row.names(missing_df) <- NULL

  # Multinational footprint across all records with non-empty 10%-threshold country lists
  texts <- d$countries_10pct[!is.na(d$countries_10pct) & d$countries_10pct != ""]
  all_codes <- unlist(
    lapply(
      strsplit(texts, ";", fixed = TRUE),
      function(x) unique(toupper(trimws(x[x != ""])))
    ),
    use.names = FALSE
  )
  footprint_df <- as.data.frame(table(all_codes), stringsAsFactors = FALSE)
  names(footprint_df) <- c("code", "N_qualifying_authors")
  footprint_df$cohort <- cohort

  # Primary paired analytical sample: valid country assignments under both scenarios
  p <- d[!is.na(d$country_a) & !is.na(d$country_b), , drop = FALSE]
  rm(d)

  p$discordant <- p$country_a != p$country_b
  p$income_A   <- map_by_code(p$country_a, income_lookup)
  p$income_B   <- map_by_code(p$country_b, income_lookup)
  p$field[is.na(p$field) | p$field == ""]       <- "Unknown field"
  p$subfield[is.na(p$subfield) | p$subfield == ""] <- "Unknown subfield"
  p$publication_cohort <- classify_publication_cohort(p$firstyr)

  good_income <- !is.na(p$income_A) & !is.na(p$income_B)
  conc <- compute_concentration(p)

  summary_df <- cbind(
    data.frame(
      cohort          = cohort,
      N_raw           = n_raw,
      N_paired        = nrow(p),
      N_discordant    = sum(p$discordant),
      discordance_pct = mean(p$discordant) * 100,
      N_income_both   = sum(good_income),
      stringsAsFactors = FALSE
    ),
    conc
  )

  # Country-level redistribution and ranking changes (Supplementary Table S1)
  codes <- sort(union(unique(p$country_a), unique(p$country_b)))
  ca <- count_codes(p$country_a, codes)
  cb <- count_codes(p$country_b, codes)

  ct <- data.frame(
    code            = codes,
    N_A             = as.integer(ca),
    N_B             = as.integer(cb),
    delta_B_minus_A = as.integer(cb - ca),
    stringsAsFactors = FALSE
  )
  ct$pct_change_from_A <- ifelse(
    ct$N_A > 0,
    100 * ct$delta_B_minus_A / ct$N_A,
    NA_real_
  )
  ct$symmetric_change_pct <- ifelse(
    ct$N_A + ct$N_B > 0,
    200 * ct$delta_B_minus_A / (ct$N_A + ct$N_B),
    NA_real_
  )
  ct$rank_A <- as.integer(rank(-ct$N_A, ties.method = "min"))
  ct$rank_B <- as.integer(rank(-ct$N_B, ties.method = "min"))
  ct$rank_change_A_minus_B <- ct$rank_A - ct$rank_B
  ct$income_group <- map_by_code(ct$code, income_lookup)
  ct$region       <- map_by_code(ct$code, region_lookup)
  ct$cohort       <- cohort
  stopifnot(sum(ct$N_A) == nrow(p), sum(ct$N_B) == nrow(p))

  unmapped_df <- data.frame(
    cohort = cohort,
    ct[is.na(ct$income_group), c("code", "N_A", "N_B"), drop = FALSE],
    stringsAsFactors = FALSE
  )
  row.names(unmapped_df) <- NULL

  # Bilateral discordant country pairs
  mism <- p[p$discordant, c("country_a", "country_b"), drop = FALSE]
  flow <- as.data.frame(table(mism$country_a, mism$country_b), stringsAsFactors = FALSE)
  names(flow) <- c("country_a", "country_b", "N")
  flow <- flow[flow$N > 0, , drop = FALSE]
  flow$cohort <- cohort
  row.names(flow) <- NULL
  rm(mism)

  # Stratified discordance tables (Supplementary Tables S4, S5, S6, S7)
  cosmo_df       <- compute_discordance_by_group(p, "cosmo", cohort)
  field_df       <- compute_discordance_by_group(p, "field", cohort)
  subfield_df    <- compute_discordance_by_group(p, "subfield", cohort)
  publication_df <- compute_discordance_by_group(p, "publication_cohort", cohort)

  # Coverage and dominance subsets
  coverage_df <- do.call(rbind, list(
    compute_subset_sensitivity(p, rep(TRUE, nrow(p)), cohort, "All paired"),
    compute_subset_sensitivity(p, p$country_coverage >= 0.50, cohort, "Coverage >= 0.50"),
    compute_subset_sensitivity(p, p$country_coverage >= 0.80, cohort, "Coverage >= 0.80"),
    compute_subset_sensitivity(p, p$country_coverage >= 0.90, cohort, "Coverage >= 0.90")
  ))
  dominance_df <- do.call(rbind, list(
    compute_subset_sensitivity(p, p$top_country_share >= 0.50, cohort, "Top share >= 0.50"),
    compute_subset_sensitivity(p, p$top_country_share >= 0.75, cohort, "Top share >= 0.75")
  ))

  # World Bank FY2026 income-group analyses (Table 2, Supplementary Tables S2 and S3)
  q <- p[good_income, , drop = FALSE]
  ya <- count_codes(q$income_A, valid_income_levels)
  yb <- count_codes(q$income_B, valid_income_levels)

  income_df <- data.frame(
    cohort            = cohort,
    income_group      = valid_income_levels,
    N_A               = as.integer(ya),
    N_B               = as.integer(yb),
    delta_B_minus_A   = as.integer(yb - ya),
    pct_change_from_A = ifelse(ya > 0, 100 * (yb - ya) / ya, NA_real_),
    N_income_both     = nrow(q),
    stringsAsFactors  = FALSE
  )

  income_disc_df <- data.frame(
    cohort         = cohort,
    income_group_A = valid_income_levels,
    N              = as.integer(ya),
    N_discordant   = vapply(
      valid_income_levels,
      function(x) sum(q$discordant[q$income_A == x]),
      integer(1)
    ),
    stringsAsFactors = FALSE
  )
  income_disc_df$discordance_pct <- with(
    income_disc_df,
    ifelse(N > 0, 100 * N_discordant / N, NA_real_)
  )

  trans_df <- as.data.frame(
    table(
      income_A = factor(q$income_A, levels = valid_income_levels),
      income_B = factor(q$income_B, levels = valid_income_levels)
    ),
    stringsAsFactors = FALSE
  )
  names(trans_df)[names(trans_df) == "Freq"] <- "N"
  trans_df$cohort <- cohort

  cat(
    cohort, ": paired = ", nrow(p),
    ", discordant = ", sum(p$discordant),
    ", income mapped = ", nrow(q), "\n",
    sep = ""
  )

  rm(p, q)
  gc(verbose = FALSE)

  list(
    summary            = summary_df,
    country_changes    = ct,
    bilateral          = flow,
    cosmo_discordance  = cosmo_df,
    income_groups      = income_df,
    income_transitions = trans_df,
    income_discordance = income_disc_df,
    field_discordance  = field_df,
    subfield_discordance = subfield_df,
    publication_cohorts  = publication_df,
    coverage           = coverage_df,
    dominance          = dominance_df,
    footprint          = footprint_df,
    unmapped           = unmapped_df,
    missing            = missing_df
  )
}


# ------------------------------------------------------------------------------
# 7. MANUSCRIPT TABLE BUILDERS AND VALIDATION
# ------------------------------------------------------------------------------
# Constructs formatted tables reproducing Manuscript Table 1 and Table 2 directly
# from the computed cohort summaries, and validates generated supplementary
# tables against existing S1-S7 CSV files if present.

build_manuscript_table_1 <- function(summary_df) {
  c_row <- summary_df[summary_df$cohort == "career", ]
  s_row <- summary_df[summary_df$cohort == "singleyr", ]

  data.frame(
    Indicator = c(
      "Original author records",
      "Paired analytical sample",
      "Excluded records",
      "Discordant assignments, n",
      "Discordant assignments, %",
      "Country codes represented",
      "Income-classified sample"
    ),
    Career_long_cohort = c(
      as.character(c_row$N_raw),
      as.character(c_row$N_paired),
      as.character(c_row$N_raw - c_row$N_paired),
      as.character(c_row$N_discordant),
      sprintf("%.2f", c_row$discordance_pct),
      as.character(c_row$countries_union),
      as.character(c_row$N_income_both)
    ),
    Single_year_cohort = c(
      as.character(s_row$N_raw),
      as.character(s_row$N_paired),
      as.character(s_row$N_raw - s_row$N_paired),
      as.character(s_row$N_discordant),
      sprintf("%.2f", s_row$discordance_pct),
      as.character(s_row$countries_union),
      as.character(s_row$N_income_both)
    ),
    stringsAsFactors = FALSE
  )
}

build_manuscript_table_2 <- function(income_df) {
  cohort_labels <- c(career = "Career", singleyr = "2025 citations")
  group_labels  <- c(
    "Low income"          = "Low income",
    "Lower middle income" = "Lower-middle",
    "Upper middle income" = "Upper-middle",
    "High income"         = "High income"
  )

  data.frame(
    Cohort       = unname(cohort_labels[income_df$cohort]),
    Income_group = unname(group_labels[income_df$income_group]),
    Scenario_A_n = income_df$N_A,
    Scenario_B_n = income_df$N_B,
    Difference_n = income_df$delta_B_minus_A,
    Change_pct   = round(income_df$pct_change_from_A, 2),
    stringsAsFactors = FALSE
  )
}

verify_against_supplementary_csvs <- function(supp_dir, generated_tables) {
  if (!dir.exists(supp_dir)) return(invisible(FALSE))

  file_map <- list(
    Table_S1_country_changes     = "country_changes",
    Table_S2_income_transitions  = "income_transitions",
    Table_S3_income_discordance  = "income_discordance",
    Table_S4_field_discordance   = "field_discordance",
    Table_S5_subfield_discordance = "subfield_discordance",
    Table_S6_publication_cohorts = "publication_cohorts",
    Table_S7_cosmo_discordance   = "cosmo_discordance"
  )

  for (supp_name in names(file_map)) {
    csv_path <- file.path(supp_dir, paste0(supp_name, ".csv"))
    if (!file.exists(csv_path)) next

    ref_df <- utils::read.csv(csv_path, stringsAsFactors = FALSE, na.strings = "")
    gen_df <- generated_tables[[file_map[[supp_name]]]]

    stopifnot(
      nrow(gen_df) == nrow(ref_df),
      ncol(gen_df) == ncol(ref_df),
      identical(names(gen_df), names(ref_df))
    )

    for (col_name in names(ref_df)) {
      if (is.numeric(gen_df[[col_name]]) || is.numeric(ref_df[[col_name]])) {
        stopifnot(
          isTRUE(all.equal(
            as.numeric(gen_df[[col_name]]),
            as.numeric(ref_df[[col_name]]),
            tolerance = 1e-9
          ))
        )
      } else {
        g_chr <- as.character(gen_df[[col_name]])
        r_chr <- as.character(ref_df[[col_name]])
        g_chr[is.na(g_chr)] <- ""
        r_chr[is.na(r_chr)] <- ""
        stopifnot(identical(g_chr, r_chr))
      }
    }
  }
  message("PASS: Generated supplementary tables match existing S1-S7 CSV files.")
  invisible(TRUE)
}


# ------------------------------------------------------------------------------
# 8. FIGURE GENERATION FUNCTIONS (FIGURES 1-4)
# ------------------------------------------------------------------------------
# Reproduces the four publication figures in high-resolution PNG and editable
# vector SVG formats while preserving exact colors, white backgrounds, panel
# structures, axis limits, and B - A directional conventions.

palette_colors <- list(
  bg     = "white",
  blue   = "#1F77B4",
  red    = "#CF624B",
  purple = "#6674A4",
  green  = "#45917F"
)

theme_manuscript <- function(base_size = 12) {
  ggplot2::theme_classic(base_size = base_size) +
    ggplot2::theme(
      plot.background   = ggplot2::element_rect(fill = palette_colors$bg, colour = NA),
      panel.background  = ggplot2::element_rect(fill = palette_colors$bg, colour = NA),
      panel.grid.major  = ggplot2::element_blank(),
      panel.grid.minor  = ggplot2::element_blank(),
      axis.line         = ggplot2::element_line(colour = "#555555", linewidth = 0.4),
      axis.ticks        = ggplot2::element_line(colour = "#555555", linewidth = 0.4),
      axis.text         = ggplot2::element_text(colour = "#222222"),
      axis.title        = ggplot2::element_text(colour = "#222222"),
      plot.title        = ggplot2::element_text(face = "bold", size = 15, hjust = 0.5),
      legend.background = ggplot2::element_blank(),
      legend.key        = ggplot2::element_rect(fill = palette_colors$bg, colour = NA),
      strip.background  = ggplot2::element_blank(),
      strip.text        = ggplot2::element_text(face = "bold", colour = "#222222")
    )
}

save_figure_pair <- function(plot_obj, filename_stem, figures_dir, width, height) {
  ggplot2::ggsave(
    filename = file.path(figures_dir, paste0(filename_stem, ".png")),
    plot     = plot_obj,
    width    = width,
    height   = height,
    units    = "in",
    dpi      = 180,
    bg       = palette_colors$bg
  )
  ggplot2::ggsave(
    filename = file.path(figures_dir, paste0(filename_stem, ".svg")),
    plot     = plot_obj,
    width    = width,
    height   = height,
    units    = "in",
    device   = grDevices::svg,
    bg       = palette_colors$bg
  )
  cat("Exported figure:", filename_stem, "(PNG + SVG)\n")
}

generate_figure_1 <- function(countries_df, figures_dir) {
  fig1 <- countries_df[
    countries_df$cohort == "career" & countries_df$N_A >= 100,
    ,
    drop = FALSE
  ]
  fig1$abs_delta <- abs(fig1$delta_B_minus_A)
  fig1 <- fig1[order(-fig1$abs_delta, fig1$code), ]
  fig1 <- utils::head(fig1, 25)
  fig1 <- fig1[order(fig1$delta_B_minus_A), ]
  fig1$code <- factor(fig1$code, levels = fig1$code)
  fig1$direction <- ifelse(fig1$delta_B_minus_A >= 0, "Increase", "Decrease")

  p1 <- ggplot2::ggplot(
    fig1,
    ggplot2::aes(x = code, y = delta_B_minus_A, fill = direction)
  ) +
    ggplot2::geom_col(width = 0.74) +
    ggplot2::geom_hline(
      yintercept = 0,
      colour     = "black",
      linewidth  = 0.6,
      alpha      = 0.8
    ) +
    ggplot2::coord_flip() +
    ggplot2::scale_fill_manual(
      values = c("Increase" = palette_colors$blue, "Decrease" = palette_colors$red),
      guide  = "none"
    ) +
    ggplot2::labs(
      title = "National reattribution: career-impact cohort",
      x     = NULL,
      y     = "Change in researcher count (B - A)"
    ) +
    theme_manuscript()

  save_figure_pair(p1, "Figure_1_country_changes", figures_dir, width = 10, height = 8)
}

generate_figure_2 <- function(summary_df, figures_dir) {
  s2 <- summary_df[match(c("career", "singleyr"), summary_df$cohort), ]
  stopifnot(!anyNA(s2$cohort))

  hhi_data <- data.frame(
    cohort   = factor(rep(c("Career", "2025 citations"), each = 2), levels = c("Career", "2025 citations")),
    scenario = factor(rep(c("Scenario A", "Scenario B"), 2), levels = c("Scenario A", "Scenario B")),
    value    = c(s2$hhi_A[1], s2$hhi_B[1], s2$hhi_A[2], s2$hhi_B[2])
  )

  gini_data <- data.frame(
    cohort   = factor(rep(c("Career", "2025 citations"), each = 2), levels = c("Career", "2025 citations")),
    scenario = factor(rep(c("Scenario A", "Scenario B"), 2), levels = c("Scenario A", "Scenario B")),
    value    = c(s2$gini_A[1], s2$gini_B[1], s2$gini_A[2], s2$gini_B[2])
  )

  theme_fig2 <- ggplot2::theme_classic(base_size = 12, base_family = "sans") +
    ggplot2::theme(
      plot.background   = ggplot2::element_rect(fill = "white", colour = NA),
      panel.background  = ggplot2::element_rect(fill = "white", colour = NA),
      panel.grid        = ggplot2::element_blank(),
      plot.title        = ggplot2::element_text(size = 14, face = "plain", hjust = 0.5, margin = ggplot2::margin(b = 12)),
      axis.title.x      = ggplot2::element_blank(),
      axis.title.y      = ggplot2::element_text(size = 12, margin = ggplot2::margin(r = 9)),
      axis.text.x       = ggplot2::element_text(size = 11, face = "bold", colour = "#222222", margin = ggplot2::margin(t = 9)),
      axis.text.y       = ggplot2::element_text(size = 10.5, colour = "#222222"),
      axis.ticks        = ggplot2::element_line(colour = "#555555", linewidth = 0.35),
      axis.line         = ggplot2::element_line(colour = "#555555", linewidth = 0.4),
      legend.background = ggplot2::element_blank(),
      legend.key        = ggplot2::element_blank(),
      legend.text       = ggplot2::element_text(size = 10.5),
      plot.margin       = ggplot2::margin(12, 12, 12, 12)
    )

  p2_hhi <- ggplot2::ggplot(
    hhi_data,
    ggplot2::aes(x = cohort, y = value, fill = scenario)
  ) +
    ggplot2::geom_col(position = ggplot2::position_dodge(width = 0.76), width = 0.66) +
    ggplot2::scale_fill_manual(
      values = c("Scenario A" = palette_colors$purple, "Scenario B" = palette_colors$green)
    ) +
    ggplot2::scale_y_continuous(
      breaks = c(0.13, 0.14, 0.15, 0.16),
      labels = function(x) sprintf("%.2f", x),
      expand = ggplot2::expansion(mult = c(0, 0))
    ) +
    ggplot2::coord_cartesian(ylim = c(0.1202770291, 0.1683759667), expand = FALSE) +
    ggplot2::labs(title = "Geographical concentration: HHI", y = "HHI", fill = NULL) +
    theme_fig2 +
    ggplot2::theme(
      legend.position      = c(0.97, 0.96),
      legend.justification = c(1, 1),
      legend.direction     = "vertical"
    )

  p2_gini <- ggplot2::ggplot(
    gini_data,
    ggplot2::aes(x = cohort, y = value, fill = scenario)
  ) +
    ggplot2::geom_col(position = ggplot2::position_dodge(width = 0.76), width = 0.66) +
    ggplot2::scale_fill_manual(
      values = c("Scenario A" = palette_colors$purple, "Scenario B" = palette_colors$green)
    ) +
    ggplot2::scale_y_continuous(
      breaks = c(0.900, 0.905, 0.910, 0.915, 0.920),
      labels = function(x) sprintf("%.3f", x),
      expand = ggplot2::expansion(mult = c(0, 0))
    ) +
    ggplot2::coord_cartesian(ylim = c(0.8988339599, 0.9214149171), expand = FALSE) +
    ggplot2::labs(title = "Geographical concentration: Gini", y = "Gini") +
    theme_fig2 +
    ggplot2::theme(legend.position = "none")

  draw_figure_2_panels <- function() {
    grid::grid.newpage()
    grid::pushViewport(
      grid::viewport(
        layout = grid::grid.layout(
          nrow   = 1,
          ncol   = 2,
          widths = grid::unit(c(1, 1), "null")
        )
      )
    )
    grid::pushViewport(grid::viewport(layout.pos.row = 1, layout.pos.col = 1))
    grid::grid.draw(ggplot2::ggplotGrob(p2_hhi))
    grid::upViewport()

    grid::pushViewport(grid::viewport(layout.pos.row = 1, layout.pos.col = 2))
    grid::grid.draw(ggplot2::ggplotGrob(p2_gini))
    grid::upViewport(0)
  }

  grDevices::png(
    filename = file.path(figures_dir, "Figure_2_concentration.png"),
    width    = 12.2,
    height   = 5,
    units    = "in",
    res      = 180,
    bg       = "white"
  )
  draw_figure_2_panels()
  grDevices::dev.off()

  grDevices::svg(
    filename  = file.path(figures_dir, "Figure_2_concentration.svg"),
    width     = 12.2,
    height    = 5,
    bg        = "white",
    pointsize = 12
  )
  draw_figure_2_panels()
  grDevices::dev.off()

  cat("Exported figure: Figure_2_concentration (PNG + SVG)\n")
}

generate_figure_3 <- function(income_df, figures_dir) {
  fig3 <- income_df[income_df$cohort %in% c("career", "singleyr"), , drop = FALSE]
  fig3$cohort_label <- factor(
    fig3$cohort,
    levels = c("career", "singleyr"),
    labels = c("Career impact", "2025 citations")
  )

  short_group_map <- c(
    "High income"         = "High",
    "Upper middle income" = "Upper-middle",
    "Lower middle income" = "Lower-middle",
    "Low income"          = "Low"
  )
  fig3$income_short <- factor(
    unname(short_group_map[as.character(fig3$income_group)]),
    levels = c("Low", "Lower-middle", "Upper-middle", "High")
  )

  fig3$span <- stats::ave(
    abs(fig3$delta_B_minus_A),
    fig3$cohort,
    FUN = function(x) max(x, na.rm = TRUE)
  )
  fig3$offset <- fig3$span * 0.03
  fig3$label_position <- fig3$delta_B_minus_A +
    ifelse(fig3$delta_B_minus_A >= 0, fig3$offset, -fig3$offset)
  fig3$label       <- sprintf("%+d", fig3$delta_B_minus_A)
  fig3$label_hjust <- ifelse(fig3$delta_B_minus_A >= 0, 0, 1)
  fig3$direction   <- ifelse(fig3$delta_B_minus_A >= 0, "Increase", "Decrease")

  p3 <- ggplot2::ggplot(
    fig3,
    ggplot2::aes(x = income_short, y = delta_B_minus_A, fill = direction)
  ) +
    ggplot2::geom_col(width = 0.64) +
    ggplot2::geom_hline(
      yintercept = 0,
      colour     = "black",
      linewidth  = 0.6,
      alpha      = 0.8
    ) +
    ggplot2::geom_text(
      ggplot2::aes(y = label_position, label = label, hjust = label_hjust),
      size   = 3.4,
      colour = "#222222"
    ) +
    ggplot2::facet_wrap(~ cohort_label, nrow = 1) +
    ggplot2::coord_flip(ylim = c(-1800, 1800), clip = "off") +
    ggplot2::scale_fill_manual(
      values = c("Increase" = palette_colors$blue, "Decrease" = palette_colors$red),
      guide  = "none"
    ) +
    ggplot2::labs(
      title = "Reattribution by World Bank FY2026 income group",
      x     = NULL,
      y     = "Change in researcher count (B - A)"
    ) +
    theme_manuscript() +
    ggplot2::theme(
      strip.text    = ggplot2::element_text(face = "bold", size = 12),
      panel.spacing = grid::unit(1.2, "lines"),
      plot.margin   = ggplot2::margin(12, 18, 12, 12)
    )

  save_figure_pair(p3, "Figure_3_income_groups", figures_dir, width = 12.2, height = 5.5)
}

generate_figure_4 <- function(transitions_df, figures_dir, valid_income_levels) {
  fig4 <- transitions_df[transitions_df$cohort == "career", , drop = FALSE]

  income_labels <- c(
    "Low income"          = "Low",
    "Lower middle income" = "Lower-mid",
    "Upper middle income" = "Upper-mid",
    "High income"         = "High"
  )

  fig4$income_A <- factor(fig4$income_A, levels = rev(valid_income_levels))
  fig4$income_B <- factor(fig4$income_B, levels = valid_income_levels)
  fig4$logN     <- log10(fig4$N + 1)
  fig4$label    <- format(as.integer(fig4$N), big.mark = ",", scientific = FALSE, trim = TRUE)

  contrast_threshold <- max(fig4$logN, na.rm = TRUE) * 0.6
  fig4$label_colour <- ifelse(fig4$logN > contrast_threshold, "#FFFFFF", "#18324A")

  p4 <- ggplot2::ggplot(
    fig4,
    ggplot2::aes(x = income_B, y = income_A, fill = logN)
  ) +
    ggplot2::geom_tile(colour = NA) +
    ggplot2::geom_text(
      ggplot2::aes(label = label, colour = label_colour),
      size = 3.5
    ) +
    ggplot2::scale_colour_identity() +
    ggplot2::scale_fill_gradient(
      low   = "#EDF4FB",
      high  = "#225886",
      name  = "log10(N + 1)",
      guide = ggplot2::guide_colorbar(
        title.position = "right",
        title.theme    = ggplot2::element_text(angle = 90),
        barheight      = grid::unit(4.5, "cm"),
        barwidth       = grid::unit(0.45, "cm")
      )
    ) +
    ggplot2::scale_x_discrete(
      limits = valid_income_levels,
      labels = function(x) unname(income_labels[x])
    ) +
    ggplot2::scale_y_discrete(
      limits = rev(valid_income_levels),
      labels = function(x) unname(income_labels[x])
    ) +
    ggplot2::coord_fixed() +
    ggplot2::labs(
      title = "Cross-income attribution matrix (career)",
      x     = "B: predominant career country",
      y     = "A: recent affiliation"
    ) +
    theme_manuscript() +
    ggplot2::theme(
      axis.text.x     = ggplot2::element_text(angle = 30, hjust = 1, size = 11),
      axis.text.y     = ggplot2::element_text(size = 11),
      legend.position = "right",
      legend.title    = ggplot2::element_text(size = 11),
      legend.text     = ggplot2::element_text(size = 10),
      plot.margin     = ggplot2::margin(12, 12, 12, 12)
    )

  save_figure_pair(p4, "Figure_4_income_transitions", figures_dir, width = 9.5, height = 7)
}


# ------------------------------------------------------------------------------
# 9. MAIN EXECUTION
# ------------------------------------------------------------------------------

main <- function() {
  paths <- resolve_runtime_paths(user_config, expected_filenames)

  message("Career-long workbook : ", paths$input_paths[["career"]])
  message("Single-year workbook : ", paths$input_paths[["singleyr"]])
  message("World Bank FY2026    : ", paths$income_file)
  message("Output root directory: ", paths$output_root)

  wb_data <- read_world_bank_classification(paths$income_file, income_levels)

  cohort_names <- c("career", "singleyr")
  cohort_results <- lapply(
     stats::setNames(cohort_names, cohort_names),
    function(cohort) {
      analyze_cohort(
        cohort              = cohort,
        source_path         = paths$input_paths[[cohort]],
        income_lookup       = wb_data$income_lookup,
        region_lookup       = wb_data$region_lookup,
        valid_income_levels = income_levels
      )
    }
  )

  combine_metric <- function(field) {
    df <- do.call(rbind, lapply(cohort_results, `[[`, field))
    row.names(df) <- NULL
    df
  }

  summary_df            <- combine_metric("summary")
  countries_df          <- combine_metric("country_changes")
  bilateral_df          <- combine_metric("bilateral")
  cosmo_discordance_df  <- combine_metric("cosmo_discordance")
  income_df             <- combine_metric("income_groups")
  transitions_df        <- combine_metric("income_transitions")
  income_discordance_df <- combine_metric("income_discordance")
  field_discordance_df  <- combine_metric("field_discordance")
  subfield_discord_df   <- combine_metric("subfield_discordance")
  publication_coh_df    <- combine_metric("publication_cohorts")
  coverage_df           <- combine_metric("coverage")
  dominance_df          <- combine_metric("dominance")
  footprint_df          <- combine_metric("footprint")
  unmapped_df           <- combine_metric("unmapped")
  missing_df            <- combine_metric("missing")

  wb_codebook_df <- data.frame(
    code         = wb_data$wb$Code,
    economy      = wb_data$wb$Economy,
    region       = wb_data$wb$Region,
    income_group = unname(wb_data$income_lookup),
    stringsAsFactors = FALSE
  )

  # Export primary analytical and diagnostic tables
  write_csv_table(wb_codebook_df,        "wb_income_fy26_codebook",   paths$results_dir)
  write_csv_table(summary_df,            "summary",                   paths$results_dir)
  write_csv_table(countries_df,          "country_changes",           paths$results_dir)
  write_csv_table(bilateral_df,          "bilateral_disagreements",   paths$results_dir)
  write_csv_table(cosmo_discordance_df,  "cosmo_discordance",         paths$results_dir)
  write_csv_table(income_df,             "income_groups",             paths$results_dir)
  write_csv_table(transitions_df,        "income_transitions",        paths$results_dir)
  write_csv_table(income_discordance_df, "income_discordance",        paths$results_dir)
  write_csv_table(field_discordance_df,  "field_discordance",         paths$results_dir)
  write_csv_table(subfield_discord_df,   "subfield_discordance",      paths$results_dir)
  write_csv_table(publication_coh_df,    "publication_cohorts",       paths$results_dir)
  write_csv_table(coverage_df,           "coverage_sensitivity",      paths$results_dir)
  write_csv_table(dominance_df,          "dominance_sensitivity",     paths$results_dir)
  write_csv_table(footprint_df,          "multinational_footprint",   paths$results_dir)
  write_csv_table(unmapped_df,           "unmapped_income_codes",     paths$results_dir)
  write_csv_table(missing_df,            "missingness",               paths$results_dir)

  # Export explicitly named manuscript tables (Table 1, Table 2) and Supplementary Tables (S1-S7)
  write_csv_table(build_manuscript_table_1(summary_df), "Table_1_analytical_sample_and_discordance", paths$results_dir)
  write_csv_table(build_manuscript_table_2(income_df),  "Table_2_income_group_distribution",         paths$results_dir)
  write_csv_table(countries_df,          "Table_S1_country_changes",      paths$results_dir)
  write_csv_table(transitions_df,        "Table_S2_income_transitions",   paths$results_dir)
  write_csv_table(income_discordance_df, "Table_S3_income_discordance",   paths$results_dir)
  write_csv_table(field_discordance_df,  "Table_S4_field_discordance",    paths$results_dir)
  write_csv_table(subfield_discord_df,   "Table_S5_subfield_discordance", paths$results_dir)
  write_csv_table(publication_coh_df,    "Table_S6_publication_cohorts",  paths$results_dir)
  write_csv_table(cosmo_discordance_df,  "Table_S7_cosmo_discordance",    paths$results_dir)

  # Verify against repository supplementary material CSVs if present
  verify_against_supplementary_csvs(
    supp_dir = paths$supp_dir,
    generated_tables = list(
      country_changes      = countries_df,
      income_transitions   = transitions_df,
      income_discordance   = income_discordance_df,
      field_discordance    = field_discordance_df,
      subfield_discordance = subfield_discord_df,
      publication_cohorts  = publication_coh_df,
      cosmo_discordance    = cosmo_discordance_df
    )
  )

  # Generate all four manuscript figures (PNG + SVG)
  generate_figure_1(countries_df, paths$figures_dir)
  generate_figure_2(summary_df,   paths$figures_dir)
  generate_figure_3(income_df,    paths$figures_dir)
  generate_figure_4(transitions_df, paths$figures_dir, income_levels)

  exported_figures <- sort(list.files(
    paths$figures_dir,
    pattern     = "\\.(png|svg)$",
    full.names  = FALSE,
    ignore.case = TRUE
  ))

  cat("\n========================================\n")
  cat("ANALYSIS AND FIGURES COMPLETED\n")
  cat("========================================\n")
  cat("Results directory:", paths$results_dir, "\n")
  cat("Figures directory:", paths$figures_dir, "\n")
  cat("Generated figure files (", length(exported_figures), "):\n", sep = "")
  for (f in exported_figures) {
    cat("  -", f, "\n")
  }
}

if (!isTRUE(getOption("sia.skip_main", FALSE))) {
  main()
}
