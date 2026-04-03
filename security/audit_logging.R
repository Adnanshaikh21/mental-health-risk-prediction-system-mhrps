library(config)
library(jsonlite)

# Load configuration
config <- config::get(file = "C:/Project/Second/config/config.yaml")

# Logger function
logger <- function(message, file = "C:/Project/Second/api/logs/api_access.log") {
  cat(sprintf("[%s] %s\n", Sys.time(), message), file = file, append = TRUE)
}

# Audit log function
log_audit <- function(user, action, details) {
  tryCatch({
    audit_record <- list(
      user = user,
      action = action,
      details = details,
      timestamp = Sys.time()
    )
    write_json(audit_record, "C:/Project/Second/security/output/audit_log.json", auto_unbox = TRUE, append = TRUE)
    logger(sprintf("Audit log: %s performed %s", user, action))
  }, error = function(e) {
    logger(sprintf("Audit logging error: %s", e$message), "C:/Project/Second/api/logs/api_error.log")
  })
}

# Example usage
log_audit("counselor", "Login", "Successful login to dashboard")