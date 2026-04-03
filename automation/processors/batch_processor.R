library(config)
library(dplyr)
library(RSQLite)

# Load configuration
config <- config::get(file = "C:/Project/Second/config/config.yaml")

# Logger function
logger <- function(message, file = "C:/Project/Second/api/logs/api_access.log") {
  cat(sprintf("[%s] %s\n", Sys.time(), message), file = file, append = TRUE)
}

# Batch processing function
batch_process <- function() {
  tryCatch({
    logger("Starting batch processing")
    
    # Load and integrate data
    source("C:/Project/Second/data/integrate_data.R")
    source("C:/Project/Second/data/preprocess_data.R")
    source("C:/Project/Second/data/feature_engineering.R")
    
    data <- integrate_data()
    data <- preprocess_data(data)
    data <- feature_engineering(data)
    
    # Save processed data
    if (config$database$use_db) {
      source("C:/Project/Second/data/database_connect.R")
      con <- connect_db()
      dbWriteTable(con, "features_data", data, overwrite = TRUE)
      dbDisconnect(con)
      logger("Batch processed data saved to database")
    } else {
      saveRDS(data, "C:/Project/Second/data/output/features_data.rds")
      logger("Batch processed data saved to features_data.rds")
    }
  }, error = function(e) {
    logger(sprintf("Batch processing error: %s", e$message), "C:/Project/Second/api/logs/api_error.log")
  })
}

# Run batch processing
batch_process()