library(googlesheets4)
library(tidyverse)

# Set working directory
setwd("C:/Project/Second")
cat("Working directory set to:", getwd(), "\n")

# Logger function
logger <- function(message, file = "C:/Project/Second/api/logs/api_access.log") {
  cat(sprintf("[%s] %s\n", Sys.time(), message), file = file, append = TRUE)
}

# Main function
data_sync_scheduler <- function() {
  tryCatch({
    logger("Starting data sync from Google Sheets")
    
    # Source sync scripts
    logger("Sourcing sync_academic_data.R")
    source("data/sync/sync_academic_data.R", local = TRUE)
    
    logger("Sourcing sync_behavioral_data.R")
    source("data/sync/sync_behavioral_data.R", local = TRUE)
    
    logger("Sourcing sync_mental_health_data.R")
    source("data/sync/sync_mental_health_data.R", local = TRUE)
    
    # Update full dataset
    logger("Sourcing update_full_dataset.R")
    source("data/sync/update_full_dataset.R", local = TRUE)
    
    logger("Data sync completed successfully")
    cat("Data sync from Google Sheets completed\n")
  }, error = function(e) {
    logger(sprintf("Error in data sync: %s", e$message), "C:/Project/Second/api/logs/api_error.log")
    stop(e)
  })
}

# Schedule sync (runs daily)
cat("Data sync scheduler started\n")
logger("Data sync scheduler started")
while (TRUE) {
    cat("Data sync scheduler started\n")
    data_sync_scheduler()
    Sys.sleep(10)  # Sleep for 1 day
    }