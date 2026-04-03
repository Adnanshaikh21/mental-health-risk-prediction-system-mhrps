library(config)
library(dplyr)
library(RSQLite)
library(httr)
library(jsonlite)

# Load configuration
config <- config::get(file = "C:/Project/Second/config/config.yaml")

# Logger function
logger <- function(message, file = "C:/Project/Second/api/logs/api_access.log") {
  cat(sprintf("[%s] %s\n", Sys.time(), message), file = file, append = TRUE)
}

# Real-time processing function
process_real_time <- function(new_data) {
  tryCatch({
    logger("Processing real-time data")
    
    # Preprocess and engineer features
    source("C:/Project/Second/data/preprocess_data.R")
    source("C:/Project/Second/data/feature_engineering.R")
    
    processed_data <- preprocess_data(new_data)
    processed_data <- feature_engineering(processed_data)
    
    # Make prediction via API
    response <- POST(
      sprintf("http://%s:%s/predict", config$api$host, config$api$port),
      body = toJSON(processed_data, auto_unbox = TRUE),
      content_type_json(),
      add_headers(Authorization = paste("Bearer", config$api$key))
    )
    
    result <- content(response, "parsed")
    if (!is.null(result$error)) {
      logger(sprintf("Real-time prediction error: %s", result$error), "C:/Project/Second/api/logs/api_error.log")
      return(NULL)
    }
    
    # Save to database or file
    if (config$database$use_db) {
      source("C:/Project/Second/data/database_connect.R")
      con <- connect_db()
      dbWriteTable(con, "predictions", result, append = TRUE)
      dbDisconnect(con)
      logger("Real-time prediction saved to database")
    } else {
      saveRDS(result, "C:/Project/Second/data/output/predictions.rds")
      logger("Real-time prediction saved to predictions.rds")
    }
    
    return(result)
  }, error = function(e) {
    logger(sprintf("Real-time processing error: %s", e$message), "C:/Project/Second/api/logs/api_error.log")
    return(NULL)
  })
}

# Example usage (replace with real-time data source)
new_data <- data.frame(
  student_id = 1,
  phq_total = 22,
  gad_total = 12,
  self_harm_thoughts = "Yes",
  mental_health_score = 11,
  outcome = 10
)
process_real_time(new_data)