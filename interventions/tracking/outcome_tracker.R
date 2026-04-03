library(config)
library(RSQLite)
library(jsonlite)

# Load configuration
config <- config::get(file = "C:/Project/Second/config/config.yaml")

# Logger function
logger <- function(message, file = "C:/Project/Second/api/logs/api_access.log") {
  cat(sprintf("[%s] %s\n", Sys.time(), message), file = file, append = TRUE)
}

# Track outcome
track_outcome <- function(student_id, intervention_id, outcome, details) {
  tryCatch({
    outcome_record <- list(
      student_id = student_id,
      intervention_id = intervention_id,
      outcome = outcome,
      details = details,
      timestamp = Sys.time()
    )
    
    # Save to database or file
    if (config$database$use_db) {
      source("C:/Project/Second/data/database_connect.R")
      con <- connect_db()
      dbWriteTable(con, "outcomes", as.data.frame(outcome_record), append = TRUE)
      dbDisconnect(con)
      logger(sprintf("Outcome tracked for student %s", student_id))
    } else {
      outcomes <- if (file.exists("C:/Project/Second/interventions/tracking/outcomes.rds")) {
        readRDS("C:/Project/Second/interventions/tracking/outcomes.rds")
      } else {
        list()
      }
      outcomes[[length(outcomes) + 1]] <- outcome_record
      saveRDS(outcomes, "C:/Project/Second/interventions/tracking/outcomes.rds")
      logger(sprintf("Outcome tracked for student %s", student_id))
    }
  }, error = function(e) {
    logger(sprintf("Outcome tracking error: %s", e$message), "C:/Project/Second/api/logs/api_error.log")
  })
}

# Example usage
track_outcome(1, 1, "Positive", "Student reported improved mood after counseling")