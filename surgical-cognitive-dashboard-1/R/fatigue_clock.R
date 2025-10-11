#' Fatigue Clock and Break Management
#'
#' Tracks time-on-task and manages break periods for fatigue monitoring.
#' Provides counters for minutes since start and minutes since last break.
#'
#' @examples
#' clock <- FatigueClock$new()
#' clock$start()
#' Sys.sleep(5)
#' clock$get_time_on_task()  # ~5 seconds
#' clock$mark_break(duration_s = 120)
#' clock$get_time_since_break()  # ~0 seconds

suppressPackageStartupMessages({
  library(R6)
})

#' R6 Class for Fatigue Clock
#' @export
FatigueClock <- R6::R6Class(
  "FatigueClock",
  
  public = list(
    
    #' @description Initialize fatigue clock
    #' @param params Optional parameters object
    initialize = function(params = NULL) {
      private$start_time <- NULL
      private$last_break_time <- NULL
      private$break_history <- data.frame(
        break_start = numeric(),
        break_duration_s = numeric(),
        time_before_break_s = numeric()
      )
      private$pause_start <- NULL
      private$total_pause_duration <- 0
      private$params <- params
      
      message("Fatigue clock initialized. Call $start() to begin tracking.")
    },
    
    #' @description Start the clock
    start = function() {
      if (!is.null(private$start_time)) {
        warning("Clock already started")
        return(invisible(self))
      }
      
      private$start_time <- Sys.time()
      private$last_break_time <- Sys.time()
      message(sprintf("Fatigue clock started at %s", private$start_time))
      invisible(self)
    },
    
    #' @description Get time since procedure start (seconds)
    #' @return Numeric seconds since start (excluding pauses)
    get_time_on_task = function() {
      if (is.null(private$start_time)) {
        warning("Clock not started")
        return(0)
      }
      
      elapsed <- as.numeric(difftime(Sys.time(), private$start_time, units = "secs"))
      elapsed <- elapsed - private$total_pause_duration
      
      return(max(0, elapsed))
    },
    
    #' @description Get time since last break (seconds)
    #' @return Numeric seconds since last break (excluding pauses)
    get_time_since_break = function() {
      if (is.null(private$last_break_time)) {
        return(self$get_time_on_task())
      }
      
      elapsed <- as.numeric(difftime(Sys.time(), private$last_break_time, units = "secs"))
      
      # Subtract any pause time that occurred after last break
      if (!is.null(private$pause_start) && private$pause_start > private$last_break_time) {
        pause_duration <- as.numeric(difftime(Sys.time(), private$pause_start, units = "secs"))
        elapsed <- elapsed - pause_duration
      }
      
      return(max(0, elapsed))
    },
    
    #' @description Get time on task in minutes
    #' @return Numeric minutes since start
    get_minutes_on_task = function() {
      self$get_time_on_task() / 60
    },
    
    #' @description Get time since break in minutes
    #' @return Numeric minutes since last break
    get_minutes_since_break = function() {
      self$get_time_since_break() / 60
    },
    
    #' @description Mark a break period
    #' @param duration_s Break duration in seconds
    #' @param note Optional note about break
    mark_break = function(duration_s, note = "") {
      if (is.null(private$start_time)) {
        warning("Clock not started")
        return(invisible(self))
      }
      
      current_time <- Sys.time()
      time_before_break <- self$get_time_on_task()
      
      # Record break
      private$break_history <- rbind(
        private$break_history,
        data.frame(
          break_start = as.numeric(current_time),
          break_duration_s = duration_s,
          time_before_break_s = time_before_break,
          note = note,
          stringsAsFactors = FALSE
        )
      )
      
      # Reset last break time
      private$last_break_time <- current_time + duration_s
      
      # Add to total pause duration
      private$total_pause_duration <- private$total_pause_duration + duration_s
      
      message(sprintf("Break marked: %ds at %.1f min time-on-task", 
                      duration_s, time_before_break / 60))
      
      invisible(self)
    },
    
    #' @description Pause the clock (e.g., for interruptions)
    pause = function() {
      if (!is.null(private$pause_start)) {
        warning("Clock already paused")
        return(invisible(self))
      }
      
      private$pause_start <- Sys.time()
      message("Clock paused")
      invisible(self)
    },
    
    #' @description Resume the clock
    resume = function() {
      if (is.null(private$pause_start)) {
        warning("Clock not paused")
        return(invisible(self))
      }
      
      pause_duration <- as.numeric(difftime(Sys.time(), private$pause_start, units = "secs"))
      private$total_pause_duration <- private$total_pause_duration + pause_duration
      private$pause_start <- NULL
      
      message(sprintf("Clock resumed (paused for %.1fs)", pause_duration))
      invisible(self)
    },
    
    #' @description Check if break is recommended
    #' @return List with recommended flag and reason
    check_break_recommendation = function() {
      if (is.null(private$start_time)) {
        return(list(recommended = FALSE, reason = "Clock not started"))
      }
      
      mins_since_break <- self$get_minutes_since_break()
      
      # Default thresholds
      recommended_freq_min <- if (!is.null(private$params)) {
        private$params$breaks$recommended_break_frequency_min
      } else {
        45
      }
      
      max_no_break_min <- if (!is.null(private$params)) {
        private$params$breaks$max_no_break_duration_s / 60
      } else {
        60
      }
      
      if (mins_since_break >= max_no_break_min) {
        return(list(
          recommended = TRUE,
          urgency = "high",
          reason = sprintf("%.0f minutes without break (max: %.0f min)", 
                          mins_since_break, max_no_break_min)
        ))
      } else if (mins_since_break >= recommended_freq_min) {
        return(list(
          recommended = TRUE,
          urgency = "medium",
          reason = sprintf("%.0f minutes without break (recommended: %.0f min)", 
                          mins_since_break, recommended_freq_min)
        ))
      } else {
        return(list(
          recommended = FALSE,
          reason = sprintf("%.0f minutes since break (next recommended at %.0f min)", 
                          mins_since_break, recommended_freq_min)
        ))
      }
    },
    
    #' @description Get break history
    #' @return Data frame of all breaks
    get_break_history = function() {
      private$break_history
    },
    
    #' @description Get summary statistics
    #' @return List with clock summary
    get_summary = function() {
      if (is.null(private$start_time)) {
        return(list(
          status = "Not started",
          time_on_task_min = 0,
          time_since_break_min = 0,
          n_breaks = 0
        ))
      }
      
      list(
        status = if (is.null(private$pause_start)) "Running" else "Paused",
        start_time = private$start_time,
        time_on_task_min = self$get_minutes_on_task(),
        time_since_break_min = self$get_minutes_since_break(),
        n_breaks = nrow(private$break_history),
        total_break_time_min = sum(private$break_history$break_duration_s) / 60,
        break_recommendation = self$check_break_recommendation()
      )
    },
    
    #' @description Reset the clock
    reset = function() {
      private$start_time <- NULL
      private$last_break_time <- NULL
      private$break_history <- data.frame(
        break_start = numeric(),
        break_duration_s = numeric(),
        time_before_break_s = numeric()
      )
      private$pause_start <- NULL
      private$total_pause_duration <- 0
      
      message("Fatigue clock reset")
      invisible(self)
    },
    
    #' @description Print clock status
    print = function() {
      summary <- self$get_summary()
      
      cat("Fatigue Clock\n")
      cat("=============\n")
      cat(sprintf("Status: %s\n", summary$status))
      
      if (!is.null(private$start_time)) {
        cat(sprintf("Started: %s\n", private$start_time))
        cat(sprintf("Time on Task: %.1f minutes\n", summary$time_on_task_min))
        cat(sprintf("Since Last Break: %.1f minutes\n", summary$time_since_break_min))
        cat(sprintf("Number of Breaks: %d\n", summary$n_breaks))
        
        rec <- summary$break_recommendation
        if (rec$recommended) {
          cat(sprintf("\n⚠️  BREAK RECOMMENDED (%s urgency)\n", rec$urgency))
          cat(sprintf("   %s\n", rec$reason))
        } else {
          cat(sprintf("\n✓ %s\n", rec$reason))
        }
      }
      
      invisible(self)
    }
  ),
  
  private = list(
    start_time = NULL,
    last_break_time = NULL,
    break_history = NULL,
    pause_start = NULL,
    total_pause_duration = 0,
    params = NULL
  )
)

#' Create a Fatigue Clock Instance
#' 
#' Convenience function to create a new fatigue clock.
#'
#' @param params Optional parameters object
#' @param auto_start Logical, start clock immediately
#' @return FatigueClock instance
#' @export
#'
#' @examples
#' clock <- create_fatigue_clock(auto_start = TRUE)
#' Sys.sleep(2)
#' clock$get_minutes_on_task()

create_fatigue_clock <- function(params = NULL, auto_start = FALSE) {
  clock <- FatigueClock$new(params = params)
  
  if (auto_start) {
    clock$start()
  }
  
  return(clock)
}

