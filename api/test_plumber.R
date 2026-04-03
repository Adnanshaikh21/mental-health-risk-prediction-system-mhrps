library(plumber)

# Initialize logging
if (!dir.exists("api/logs")) dir.create("api/logs", recursive = TRUE)
logger <- function(message, file = "api/logs/api_access.log") {
  cat(sprintf("[%s] %s\n", Sys.time(), message), file = file, append = TRUE)
}

#* @apiTitle Test API
#* @apiDescription Minimal API for debugging

#* Health check
#* @get /health
function() {
  logger("Health check accessed")
  list(status = "API is running")
}
