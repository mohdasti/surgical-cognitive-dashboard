# Validate Docker configuration files
cat("=== Docker Configuration Validation ===\n")

# Check if required files exist
required_files <- c("Dockerfile", "shiny-server.conf", "nginx.conf", ".dockerignore")
for (file in required_files) {
  if (file.exists(file)) {
    cat("✓", file, "exists\n")
  } else {
    cat("✗", file, "MISSING\n")
  }
}

# Validate Dockerfile content
cat("\n=== Dockerfile Validation ===\n")
if (file.exists("Dockerfile")) {
  dockerfile_content <- readLines("Dockerfile")
  required_commands <- c("FROM rocker/shiny", "WORKDIR", "COPY", "RUN", "EXPOSE", "CMD")
  
  for (cmd in required_commands) {
    if (any(grepl(cmd, dockerfile_content))) {
      cat("✓", cmd, "found\n")
    } else {
      cat("✗", cmd, "MISSING\n")
    }
  }
}

# Validate shiny-server.conf
cat("\n=== Shiny Server Config Validation ===\n")
if (file.exists("shiny-server.conf")) {
  shiny_conf <- readLines("shiny-server.conf")
  if (any(grepl("listen 3838", shiny_conf))) {
    cat("✓ Shiny server listens on port 3838\n")
  } else {
    cat("✗ Shiny server port not configured\n")
  }
  
  if (any(grepl("app_dir", shiny_conf))) {
    cat("✓ App directory configured\n")
  } else {
    cat("✗ App directory not configured\n")
  }
}

# Validate nginx.conf
cat("\n=== nginx Config Validation ===\n")
if (file.exists("nginx.conf")) {
  nginx_conf <- readLines("nginx.conf")
  
  if (any(grepl("listen 80", nginx_conf))) {
    cat("✓ nginx listens on port 80\n")
  } else {
    cat("✗ nginx port not configured\n")
  }
  
  if (any(grepl("proxy_pass.*3838", nginx_conf))) {
    cat("✓ nginx proxies to Shiny server\n")
  } else {
    cat("✗ nginx proxy not configured\n")
  }
  
  if (any(grepl("frame-ancestors", nginx_conf))) {
    cat("✓ iframe headers configured\n")
  } else {
    cat("✗ iframe headers not configured\n")
  }
  
  if (any(grepl("WebSocket", nginx_conf))) {
    cat("✓ WebSocket support configured\n")
  } else {
    cat("✗ WebSocket support not configured\n")
  }
}

# Check app structure
cat("\n=== App Structure Validation ===\n")
app_files <- c("app.R", "00_setup.R", "config/config.yml", 
               "R/streaming_inference.R", "R/diagnostics_module.R")
for (file in app_files) {
  if (file.exists(file)) {
    cat("✓", file, "\n")
  } else {
    cat("✗", file, "MISSING\n")
  }
}

# Check data files
cat("\n=== Data Files Validation ===\n")
data_files <- list.files("data", recursive=TRUE, full.names=TRUE)
if (length(data_files) > 0) {
  total_size <- sum(file.size(data_files), na.rm=TRUE)
  cat("✓ Data files found (", round(total_size/1024/1024, 2), "MB)\n")
} else {
  cat("✗ No data files found\n")
}

cat("\n=== Docker Commands ===\n")
cat("To build: docker build -t cogbb .\n")
cat("To run:   docker run -p 8080:80 cogbb\n")
cat("To test:  curl http://localhost:8080\n")

cat("\n=== Validation Complete ===\n")
