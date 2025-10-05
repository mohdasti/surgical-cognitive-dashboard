# Repro
if (!requireNamespace("renv", quietly=TRUE)) install.packages("renv")
if (file.exists("renv.lock")) renv::activate()

set.seed(1337)
options(warn = 1)

# Packages for the whole project
pkgs <- c(
  # core
  "yaml","tidyverse","data.table","zoo","slider","R6",
  # modeling
  "xgboost","yardstick","rsample","recipes","glmnet","PRROC","pROC",
  # explainability & viz
  "fastshap","pdp","plotly","gt","DT","ggpubr","patchwork",
  # shiny
  "shiny","shinydashboard",
  # anomaly
  "solitude",
  # utils
  "jsonlite","microbenchmark"
)
to_install <- pkgs[!pkgs %in% rownames(installed.packages())]
if (length(to_install)) install.packages(to_install, repos = "https://cloud.r-project.org")
invisible(lapply(pkgs, require, character.only = TRUE))

CFG <- yaml::read_yaml("config/config.yml")
set.seed(CFG$random_seed)

# dirs
dir.create("data/processed", recursive = TRUE, showWarnings = FALSE)
dir.create("data/diagnostics", recursive = TRUE, showWarnings = FALSE)
dir.create("data/logs", recursive = TRUE, showWarnings = FALSE)
dir.create("shiny_app/modules", recursive = TRUE, showWarnings = FALSE)
dir.create("tests", showWarnings = FALSE)
