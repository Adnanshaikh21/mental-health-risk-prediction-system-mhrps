library(config)
library(dplyr)
library(RSQLite)
library(sendmailR)

# Load configuration
config <- config::get(file = "C:/Project/Second/config/config.yaml")

# Logger function
logger <- function(message, file = "C:/Project/Second/api/logs/api_access.log") {
  cat(sprintf("[%s] %s\n", Sys.time(), message), file = file, append = TRUE)
}

# Alert function
send_alerts <- function() {
  tryCatch({
    logger("Checking for high-risk students")
    
    # Load data
    if (config$database$use_db) {
      source("C:/Project/Second/data/database_connect.R")
      con <- connect_db()
      data <- dbReadTable(con, "features_data")
      dbDisconnect(con)
    } else {
      data <- readRDS("C:/Project/Second/data/output/features_data.rds")
    }
    
    # Identify high-risk students
    high_risk <- data %>% filter(mental_health_risk == "High")
    
    if (nrow(high_risk) > 0) {
      # Send email alerts (configure SMTP server as needed)
      for (i in 1:nrow(high_risk)) {
        student <- high_risk[i, ]
        sendmail(
          from = "alerts@mentalhealthsystem.com",
          to = "counselor@school.edu",
          subject = paste("High-Risk Alert for Student", student$student_id),
          msg = paste("Student ID:", student$student_id, "\nPHQ-9:", student$phq_total, "\nGAD-7:", student$gad_total),
          control = list(smtpServer = "smtp.yourserver.com")
        )
      }
      logger(sprintf("Sent alerts for %d high-risk students", nrow(high_risk)))
    } else {
      logger("No high-risk students found")
    }
  }, error = function(e) {
    logger(sprintf("Alert scheduler error: %s", e$message), "C:/Project/Second/api/logs/api_error.log")
  })
}
print("Started alert")
# Schedule alerts every 12 hours
while (TRUE) {
  send_alerts()
  Sys.sleep(12 * 60 * 60)  # Sleep for 12 hours
}