library(config)
library(httr)
library(jsonlite)

# Load configuration
config <- config::get(file = "C:/Project/Second/config/config.yaml")

# Logger function
logger <- function(message, file = "C:/Project/Second/api/logs/api_access.log") {
  cat(sprintf("[%s] %s\n", Sys.time(), message), file = file, append = TRUE)
}

# System health check function
check_system_health <- function() {
  tryCatch({
    logger("Checking system health")
    
    # Check API
    api_response <- GET(
      sprintf("http://%s:%s/health", config$api$host, config$api$port),
      add_headers(Authorization = paste("Bearer", config$api$key))
    )
    api_status <- if (status_code(api_response) == 200) "Up" else "Down"
    
    # Check database
    db_status <- if (config$database$use_db) {
      source("C:/Project/Second/data/database_connect.R")
      con <- tryCatch(connect_db(), error = function(e) NULL)
      if (!is.null(con)) { dbDisconnect(con); "Up" } else { "Down" }
    } else {
      "Not used"
    }
    
    # Log health report
    health_report <- list(
      timestamp = Sys.time(),
      api_status = api_status,
      db_status = db_status
    )
    write_json(health_report, "C:/Project/Second/automation/monitoring/system_health_report.json", auto_unbox = TRUE)
    logger("System health check completed")
  }, error = function(e) {
    logger(sprintf("System health check error: %s", e$message), "C:/Project/Second/api/logs/api_error.log")
  })
}
print("Done checking system health")
# Run every 10 minutes
while (TRUE) {
  check_system_health()
  Sys.sleep(10 * 60)
}