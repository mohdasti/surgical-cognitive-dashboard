#!/bin/bash
cd "$(dirname "$0")"
Rscript -e "shiny::runApp('app_working.R', port = 3838, launch.browser = FALSE)"


