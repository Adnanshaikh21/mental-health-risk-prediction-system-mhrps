library(config)
library(RSQLite)
library(dplyr)
library(lubridate)

# Load configuration
config <- config::get(file = "C:/Project/Second/config/config.yaml")

# Logger function
logger <- function(message, file = "C:/Project/Second/api/logs/api_access.log") {
  cat(sprintf("[%s] %s\n", Sys.time(), message), file = file, append = TRUE)
}

# Data ingestion function
ingest_data <- function() {
  tryCatch({
    logger("Starting data ingestion")
    
    # Run integration script
    source("C:/Project/Second/data/integrate_data.R")
    
    # Check if database is used
    if (config$database$use_db) {
      source("C:/Project/Second/data/database_connect.R")
      con <- connect_db()
      data <- integrate_data()  # From integrate_data.R
      dbWriteTable(con, "features_data", data, overwrite = TRUE)
      dbDisconnect(con)
      logger("Data ingested into database")
    } else {
      data <- integrate_data()
      saveRDS(data, "C:/Project/Second/data/output/features_data.rds")
      logger("Data saved to features_data.rds")
    }
  }, error = function(e) {
    logger(sprintf("Data ingestion error: %s", e$message), "C:/Project/Second/api/logs/api_error.log")
  })
}
print("Successfull")
print("Data ingestion scheduler started")
# Schedule ingestion every 24 hours
while (TRUE) {
  ingest_data()
  Sys.sleep(24 * 60 * 60)  # Sleep for 24 hours
}