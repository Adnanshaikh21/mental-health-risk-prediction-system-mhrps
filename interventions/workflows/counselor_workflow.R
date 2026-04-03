library(config)
library(dplyr)
library(RSQLite)

# Load configuration
config <- config::get(file = "C:/Project/Second/config/config.yaml")

# Logger function
logger <- function(message, file = "C:/Project/Second/api/logs/api_access.log") {
  cat(sprintf("[%s] %s\n", Sys.time(), message), file = file, append = TRUE)
}

# Counselor workflow
counselor_workflow <- function(student_id) {
  tryCatch({
    logger(sprintf("Starting counselor workflow for student %s", student_id))
    
    # Load data
    if (config$database$use_db) {
      source("C:/Project/Second/data/database_connect.R")
      con <- connect_db()
      student_data <- dbReadTable(con, "features_data") %>% filter(student_id == !!student_id)
      dbDisconnect(con)
    } else {
      student_data <- readRDS("C:/Project/Second/data/output/features_data.rds") %>% filter(student_id == !!student_id)
    }
    
    if (nrow(student_data) == 0) {
      logger(sprintf("Student %s not found", student_id), "C:/Project/Second/api/logs/api_error.log")
      return(NULL)
    }
    
    # Log intervention
    source("C:/Project/Second/interventions/tracking/intervention_logger.R")
    log_intervention(student_id, "counselor", "Counseling Session", "Initiated counseling session")
    
    # Send email alert
    source("C:/Project/Second/interventions/templates/email_templates.R")
    high_risk_alert(student_id, student_data$phq_total, student_data$gad_total, "counselor@school.edu")
    
    logger(sprintf("Counselor workflow completed for student %s", student_id))
  }, error = function(e) {
    logger(sprintf("Counselor workflow error: %s", e$message), "C:/Project/Second/api/logs/api_error.log")
  })
}

# Example usage
counselor_workflow(1)