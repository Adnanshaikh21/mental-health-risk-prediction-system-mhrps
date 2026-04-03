library(config)
library(sendmailR)

# Load configuration
config <- config::get(file = "C:/Project/Second/config/config.yaml")

# Logger function
logger <- function(message, file = "C:/Project/Second/api/logs/api_access.log") {
  cat(sprintf("[%s] %s\n", Sys.time(), message), file = file, append = TRUE)
}

# Email template for high-risk alert
high_risk_alert <- function(student_id, phq_total, gad_total, recipient) {
  tryCatch({
    subject <- sprintf("High-Risk Alert for Student %s", student_id)
    body <- sprintf(
      "Dear Counselor,\n\nA high-risk student has been identified:\n- Student ID: %s\n- PHQ-9 Score: %s\n- GAD-7 Score: %s\n\nPlease take appropriate action.\n\nBest,\nMental Health System",
      student_id, phq_total, gad_total
    )
    sendmail(
      from = "alerts@mentalhealthsystem.com",
      to = recipient,
      subject = subject,
      msg = body,
      control = list(smtpServer = "smtp.yourserver.com")
    )
    logger(sprintf("High-risk alert email sent for student %s", student_id))
  }, error = function(e) {
    logger(sprintf("Email sending error: %s", e$message), "C:/Project/Second/api/logs/api_error.log")
  })
}

# Example usage
high_risk_alert(1, 22, 12, "counselor@school.edu")