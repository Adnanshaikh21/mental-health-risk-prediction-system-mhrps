library(config)
library(dplyr)
library(knitr)

# Load configuration
config <- config::get(file = "C:/Project/Second/config/config.yaml")

# Logger function
logger <- function(message, file = "C:/Project/Second/api/logs/api_access.log") {
  cat(sprintf("[%s] %s\n", Sys.time(), message), file = file, append = TRUE)
}

# Weekly high-risk report
weekly_high_risk_report <- function() {
  tryCatch({
    # Load data
    if (config$database$use_db) {
      source("C:/Project/Second/data/database_connect.R")
      con <- connect_db()
      data <- dbReadTable(con, "features_data")
      dbDisconnect(con)
    } else {
      data <- readRDS("C:/Project/Second/data/output/features_data.rds")
    }
    
    # Filter high-risk students
    high_risk <- data %>% filter(mental_health_risk == "High")
    
    # Generate report
    report <- knitr::kable(high_risk, format = "markdown")
    writeLines(report, "C:/Project/Second/interventions/templates/high_risk_report.md")
    logger("Weekly high-risk report generated")
  }, error = function(e) {
    logger(sprintf("Report generation error: %s", e$message), "C:/Project/Second/api/logs/api_error.log")
  })
}

# Example usage
weekly_high_risk_report()