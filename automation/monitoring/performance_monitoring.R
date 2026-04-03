library(config)
library(httr)
library(jsonlite)

# Load configuration
config <- config::get(file = "C:/Project/Second/config/config.yaml")

# Logger function
logger <- function(message, file = "C:/Project/Second/api/logs/api_access.log") {
  cat(sprintf("[%s] %s\n", Sys.time(), message), file = file, append = TRUE)
}

# Performance monitoring function
monitor_performance <- function() {
  tryCatch({
    logger("Checking system performance")
    
    # Check API status
    api_response <- GET(
      sprintf("http://%s:%s/health", config$api$host, config$api$port),
      add_headers(Authorization = paste("Bearer", config$api$key))
    )
    api_status <- if (status_code(api_response) == 200) "Up" else "Down"
    
    # Log metrics
    metrics <- list(
      timestamp = Sys.time(),
      api_status = api_status,
      cpu_usage = system("ps aux | grep R | awk '{print $3}'", intern = TRUE),
      memory_usage = system("ps aux | grep R | awk '{print $4}'", intern = TRUE)
    )
    write_json(metrics, "C:/Project/Second/automation/monitoring/performance_metrics.json", auto_unbox = TRUE)
    logger("Performance metrics logged")
  }, error = function(e) {
    logger(sprintf("Performance monitoring error: %s", e$message), "C:/Project/Second/api/logs/api_error.log")
  })
}
print("Done performance monitoring.")
# Run every 5 minutes
while (TRUE) {
  monitor_performance()
  Sys.sleep(5 * 60)
}