library(config)
library(RSQLite)
library(jsonlite)

# Load configuration
config <- config::get(file = "C:/Project/Second/config/config.yaml")

# Logger function
logger <- function(message, file = "C:/Project/Second/api/logs/api_access.log") {
  cat(sprintf("[%s] %s\n", Sys.time(), message), file = file, append = TRUE)
}

# Log intervention
log_intervention <- function(student_id, user, intervention_type, details) {
  tryCatch({
    intervention <- list(
      student_id = student_id,
      user = user,
      intervention_type = intervention_type,
      details = details,
      timestamp = Sys.time()
    )
    
    # Save to database or file
    if (config$database$use_db) {
      source("C:/Project/Second/data/database_connect.R")
      con <- connect_db()
      dbWriteTable(con, "interventions", as.data.frame(intervention), append = TRUE)
      dbDisconnect(con)
      logger(sprintf("Intervention logged for student %s by %s", student_id, user))
    } else {
      interventions <- if (file.exists("C:/Project/Second/interventions/tracking/interventions.rds")) {
        readRDS("C:/Project/Second/interventions/tracking/interventions.rds")
      } else {
        list()
      }
      interventions[[length(interventions) + 1]] <- intervention
      saveRDS(interventions, "C:/Project/Second/interventions/tracking/interventions.rds")
      logger(sprintf("Intervention logged for student %s by %s", student_id, user))
    }
  }, error = function(e) {
    logger(sprintf("Intervention logging error: %s", e$message), "C:/Project/Second/api/logs/api_error.log")
  })
}

# Example usage
log_intervention(1, "counselor", "Counseling Session", "Scheduled meeting to discuss mental health concerns")

print("Done with interventions.")