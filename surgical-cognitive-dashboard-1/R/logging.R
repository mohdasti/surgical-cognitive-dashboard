#' Structured Logging with Privacy Controls
#'
#' Functions for logging signals, features, states, and events with
#' configurable privacy modes and automatic log rotation.
#'
#' Supports three privacy modes:
#' - "full": Keep all identifiers (requires explicit consent)
#' - "anonymized": Hash surgeon_id, strip PII
#' - "minimal": Only derived metrics, no identifiers

suppressPackageStartupMessages({
  library(jsonlite)
  library(digest)
  library(dplyr)
})

#' Initialize Logging System
#'
#' Creates log directories and sets up rotation policy.
#'
#' @param log_dir Base directory for logs (default "logs")
#' @param params Parameters object with logging configuration
#' @return List with log paths
#' @export

init_logging <- function(log_dir = "logs", params = NULL) {
  
  # Create log subdirectories
  subdirs <- c("signals", "features", "states", "events")
  for (subdir in subdirs) {
    dir.create(file.path(log_dir, subdir), recursive = TRUE, showWarnings = FALSE)
  }
  
  # Get privacy mode
  privacy_mode <- if (!is.null(params)) {
    params$logging$pii_mode
  } else {
    "anonymized"
  }
  
  # Create/update metadata file
  metadata <- list(
    initialized = Sys.time(),
    privacy_mode = privacy_mode,
    version = "1.0.0"
  )
  
  jsonlite::write_json(metadata, file.path(log_dir, "metadata.json"), 
                       auto_unbox = TRUE, pretty = TRUE)
  
  message(sprintf("Logging initialized: %s (privacy: %s)", log_dir, privacy_mode))
  
  return(list(
    log_dir = log_dir,
    signals = file.path(log_dir, "signals"),
    features = file.path(log_dir, "features"),
    states = file.path(log_dir, "states"),
    events = file.path(log_dir, "events"),
    privacy_mode = privacy_mode
  ))
}

#' Anonymize Identifiers
#'
#' @param surgeon_id Surgeon identifier
#' @param session_id Session identifier
#' @param privacy_mode Privacy mode
#' @return List with potentially anonymized IDs
#' @keywords internal

anonymize_ids <- function(surgeon_id, session_id, privacy_mode) {
  
  if (privacy_mode == "full") {
    return(list(
      surgeon_id = surgeon_id,
      session_id = session_id
    ))
  }
  
  if (privacy_mode == "anonymized") {
    return(list(
      surgeon_id = if (!is.null(surgeon_id)) digest::digest(surgeon_id, algo = "sha256") else NA,
      session_id = if (!is.null(session_id)) digest::digest(session_id, algo = "sha256") else NA
    ))
  }
  
  if (privacy_mode == "minimal") {
    return(list(
      surgeon_id = NA,
      session_id = NA
    ))
  }
  
  stop(sprintf("Unknown privacy mode: %s", privacy_mode))
}

#' Log Signal Data
#'
#' Appends raw biosignal data to JSONL log.
#'
#' @param df Data frame with timestamp and signal columns
#' @param path Path to log file
#' @param surgeon_id Optional surgeon identifier
#' @param session_id Optional session identifier
#' @param privacy_mode Privacy mode
#' @export

log_signals <- function(df, path, surgeon_id = NULL, session_id = NULL, 
                       privacy_mode = "anonymized") {
  
  if (nrow(df) == 0) {
    return(invisible(NULL))
  }
  
  # Anonymize IDs
  ids <- anonymize_ids(surgeon_id, session_id, privacy_mode)
  
  # Add metadata
  df$surgeon_id <- ids$surgeon_id
  df$session_id <- ids$session_id
  df$logged_at <- as.numeric(Sys.time())
  
  # Append to JSONL
  jsonlite::stream_out(df, file(path, "a"), verbose = FALSE)
  
  invisible(NULL)
}

#' Log Feature Data
#'
#' Appends computed features to JSONL log.
#'
#' @param df Data frame with window_end_time and feature columns
#' @param path Path to log file
#' @param surgeon_id Optional surgeon identifier
#' @param session_id Optional session identifier
#' @param privacy_mode Privacy mode
#' @export

log_features <- function(df, path, surgeon_id = NULL, session_id = NULL, 
                        privacy_mode = "anonymized") {
  
  if (nrow(df) == 0) {
    return(invisible(NULL))
  }
  
  # Anonymize IDs
  ids <- anonymize_ids(surgeon_id, session_id, privacy_mode)
  
  # Add metadata
  df$surgeon_id <- ids$surgeon_id
  df$session_id <- ids$session_id
  df$logged_at <- as.numeric(Sys.time())
  
  # Append to JSONL
  jsonlite::stream_out(df, file(path, "a"), verbose = FALSE)
  
  invisible(NULL)
}

#' Log State Predictions
#'
#' Appends state predictions to JSONL log.
#'
#' @param df Data frame with timestamp, state, probabilities
#' @param path Path to log file
#' @param surgeon_id Optional surgeon identifier
#' @param session_id Optional session identifier
#' @param privacy_mode Privacy mode
#' @export

log_states <- function(df, path, surgeon_id = NULL, session_id = NULL, 
                      privacy_mode = "anonymized") {
  
  if (nrow(df) == 0) {
    return(invisible(NULL))
  }
  
  # Anonymize IDs
  ids <- anonymize_ids(surgeon_id, session_id, privacy_mode)
  
  # Add metadata
  df$surgeon_id <- ids$surgeon_id
  df$session_id <- ids$session_id
  df$logged_at <- as.numeric(Sys.time())
  
  # Append to JSONL
  jsonlite::stream_out(df, file(path, "a"), verbose = FALSE)
  
  invisible(NULL)
}

#' Log Event
#'
#' Logs a discrete event (alert, break, calibration, etc.)
#'
#' @param event_type Type of event
#' @param event_data Named list of event-specific data
#' @param path Path to events log file
#' @param surgeon_id Optional surgeon identifier
#' @param session_id Optional session identifier
#' @param privacy_mode Privacy mode
#' @export
#'
#' @examples
#' log_event("break_started", list(duration_s = 120), 
#'           path = "logs/events/events.jsonl")
#' log_event("alert_triggered", list(type = "lapse", probability = 0.45),
#'           path = "logs/events/events.jsonl")

log_event <- function(event_type, event_data, path, surgeon_id = NULL, 
                     session_id = NULL, privacy_mode = "anonymized") {
  
  # Anonymize IDs
  ids <- anonymize_ids(surgeon_id, session_id, privacy_mode)
  
  # Create event record
  event <- list(
    timestamp = as.numeric(Sys.time()),
    event_type = event_type,
    surgeon_id = ids$surgeon_id,
    session_id = ids$session_id,
    data = event_data
  )
  
  # Append to JSONL
  jsonlite::write_json(event, path, append = TRUE, auto_unbox = TRUE)
  
  invisible(NULL)
}

#' Create Daily Log File Name
#'
#' @param log_dir Base log directory
#' @param log_type Type of log ("signals", "features", "states", "events")
#' @return Path to daily log file
#' @keywords internal

get_daily_log_path <- function(log_dir, log_type) {
  date_str <- format(Sys.Date(), "%Y-%m-%d")
  file.path(log_dir, log_type, sprintf("%s_%s.jsonl", log_type, date_str))
}

#' Rotate Logs
#'
#' Compresses old logs and removes expired logs based on retention policy.
#'
#' @param log_dir Base log directory
#' @param retention_days Number of days to retain logs
#' @param compress Compress old logs with gzip
#' @export

rotate_logs <- function(log_dir = "logs", retention_days = 90, compress = TRUE) {
  
  log_types <- c("signals", "features", "states", "events")
  
  for (log_type in log_types) {
    type_dir <- file.path(log_dir, log_type)
    
    if (!dir.exists(type_dir)) {
      next
    }
    
    # Get all log files
    log_files <- list.files(type_dir, pattern = "\\.jsonl$", full.names = TRUE)
    
    for (log_file in log_files) {
      file_info <- file.info(log_file)
      file_age_days <- as.numeric(difftime(Sys.time(), file_info$mtime, units = "days"))
      
      # Compress old files
      if (compress && file_age_days > 1 && !grepl("\\.gz$", log_file)) {
        gzip_file <- paste0(log_file, ".gz")
        if (!file.exists(gzip_file)) {
          R.utils::gzip(log_file, destname = gzip_file, overwrite = FALSE, remove = TRUE)
          message(sprintf("Compressed: %s", basename(log_file)))
        }
      }
      
      # Remove expired files
      if (file_age_days > retention_days) {
        file.remove(log_file)
        message(sprintf("Removed expired log: %s", basename(log_file)))
      }
    }
    
    # Also check compressed files
    gz_files <- list.files(type_dir, pattern = "\\.jsonl\\.gz$", full.names = TRUE)
    for (gz_file in gz_files) {
      file_info <- file.info(gz_file)
      file_age_days <- as.numeric(difftime(Sys.time(), file_info$mtime, units = "days"))
      
      if (file_age_days > retention_days) {
        file.remove(gz_file)
        message(sprintf("Removed expired compressed log: %s", basename(gz_file)))
      }
    }
  }
  
  message("Log rotation complete")
  invisible(NULL)
}

#' Read Log File
#'
#' Reads JSONL log file (handles gzipped files).
#'
#' @param path Path to log file
#' @return Tibble with log data
#' @export

read_log <- function(path) {
  
  if (!file.exists(path)) {
    # Try gzipped version
    gz_path <- paste0(path, ".gz")
    if (file.exists(gz_path)) {
      path <- gz_path
    } else {
      stop(sprintf("Log file not found: %s", path))
    }
  }
  
  if (grepl("\\.gz$", path)) {
    # Read gzipped file
    con <- gzfile(path, "rt")
    data <- jsonlite::stream_in(con, verbose = FALSE)
    close(con)
  } else {
    # Read regular JSONL
    data <- jsonlite::stream_in(file(path), verbose = FALSE)
  }
  
  tibble::as_tibble(data)
}

#' Get Log Summary Statistics
#'
#' @param log_dir Base log directory
#' @return List with log statistics
#' @export

log_summary <- function(log_dir = "logs") {
  
  log_types <- c("signals", "features", "states", "events")
  summary <- list()
  
  for (log_type in log_types) {
    type_dir <- file.path(log_dir, log_type)
    
    if (!dir.exists(type_dir)) {
      summary[[log_type]] <- list(n_files = 0, total_size_mb = 0)
      next
    }
    
    log_files <- list.files(type_dir, pattern = "\\.jsonl", full.names = TRUE, 
                           recursive = TRUE)
    
    total_size <- sum(file.info(log_files)$size, na.rm = TRUE)
    
    summary[[log_type]] <- list(
      n_files = length(log_files),
      total_size_mb = round(total_size / 1024^2, 2)
    )
  }
  
  return(summary)
}

#' Check Privacy Consent
#'
#' Validates that consent is recorded for full logging mode.
#'
#' @param surgeon_id Surgeon identifier
#' @param consent_file Path to consent records
#' @return Logical indicating consent status
#' @export

check_privacy_consent <- function(surgeon_id, consent_file = "config/privacy_consent.yml") {
  
  if (!file.exists(consent_file)) {
    warning(sprintf("Consent file not found: %s", consent_file))
    return(FALSE)
  }
  
  consents <- yaml::read_yaml(consent_file)
  
  if (is.null(consents[[surgeon_id]])) {
    return(FALSE)
  }
  
  consent_record <- consents[[surgeon_id]]
  
  # Check consent is active and not expired
  if (consent_record$status == "active") {
    if (!is.null(consent_record$expiry_date)) {
      expiry <- as.Date(consent_record$expiry_date)
      if (Sys.Date() > expiry) {
        warning(sprintf("Consent expired for surgeon %s", surgeon_id))
        return(FALSE)
      }
    }
    return(TRUE)
  }
  
  return(FALSE)
}

