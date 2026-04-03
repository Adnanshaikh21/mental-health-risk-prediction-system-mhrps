library(config)
library(dplyr)
library(RSQLite)

# Load configuration
config <- config::get(file = "C:/Project/Second/config/config.yaml")

# Logger function
logger <- function(message, file = "C:/Project/Second/api/logs/api_access.log") {
  cat(sprintf("[%s] %s\n", Sys.time(), message), file = file, append = TRUE)
}

# Data quality check function
check_data_quality <- function() {
  tryCatch({
    logger("Checking data quality")
    
    # Load data
    if (config$database$use_db) {
      source("C:/Project/Second/data/database_connect.R")
      con <- connect_db()
      data <- dbReadTable(con, "features_data")
      dbDisconnect(con)
    } else {
      data <- readRDS("C:/Project/Second/data/output/features_data.rds")
    }
    
    # Calculate missing data rate
    missing_rate <- mean(is.na(data)) * 100
    quality_report <- list(
      timestamp = Sys.time(),
      missing_rate = missing_rate,
      row_count = nrow(data),
      column_count = ncol(data)
    )
    
    # Save report
    write_json(quality_report, "C:/Project/Second/automation/monitoring/data_quality_report.json", auto_unbox = TRUE)
    
    if (missing_rate > 5) {
      logger(sprintf("High missing data rate: %.2f%%", missing_rate), "C:/Project/Second/api/logs/api_error.log")
    } else {
      logger("Data quality check passed")
    }
  }, error = function(e) {
    logger(sprintf("Data quality check error: %s", e$message), "C:/Project/Second/api/logs/api_error.log")
  })
}
print("Done with data quality monitor.")
# Run every 6 hours
while (TRUE) {
  check_data_quality()
  Sys.sleep(6 * 60 * 60)
}