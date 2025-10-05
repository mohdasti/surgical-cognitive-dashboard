start_run <- function() {
  id <- format(Sys.time(), "%Y%m%d-%H%M%S")
  path <- file.path("data/logs", paste0("run-", id, ".csv"))
  list(id=id, path=path)
}
log_event <- function(run, t, final_state, lapse_p, high_prob, reasons) {
  line <- data.frame(ts=Sys.time(), t=t, state=final_state, lapse_p=lapse_p,
                     high_prob=high_prob, reasons=paste(reasons, collapse="; "))
  readr::write_csv(line, run$path, append=file.exists(run$path))
}
end_run <- function(run) invisible(run)
