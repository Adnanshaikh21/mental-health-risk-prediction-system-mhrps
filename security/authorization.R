library(config)

# Load configuration
config <- config::get(file = "C:/Project/Second/config/config.yaml")

# Logger function
logger <- function(message, file = "C:/Project/Second/api/logs/api_access.log") {
  cat(sprintf("[%s] %s\n", Sys.time(), message), file = file, append = TRUE)
}

# Authorization function
authorize_role <- function(user, required_role) {
  tryCatch({
    if (is.null(user$role) || user$role != required_role) {
      logger(sprintf("Unauthorized access attempt by %s for role %s", user$user, required_role), "C:/Project/Second/api/logs/api_error.log")
      return(list(error = sprintf("Unauthorized: %s access required", required_role), status = 403))
    }
    return(list(authorized = TRUE))
  }, error = function(e) {
    logger(sprintf("Authorization error: %s", e$message), "C:/Project/Second/api/logs/api_error.log")
    return(list(error = "Authorization failed", status = 403))
  })
}