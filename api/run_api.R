# Mental Health Risk Prediction API - Runner Script
# This script starts the REST API server

library(plumber)
library(config)

# CRITICAL: Ensure we're in the correct working directory
# Set to the project root directory, not the api subdirectory
setwd("C:/Project/Second")

cat("=== STARTING API SERVER ===\n")
cat("Working directory:", getwd(), "\n")

# Create logs directory
dir.create("api/logs", recursive = TRUE, showWarnings = FALSE)
cat("Logs directory created/verified\n")

# Load config and verify paths
config <- config::get(file = "config/config.yaml")
cat("Config loaded successfully\n")
cat("Model path:", config$model$path, "\n")
cat("Scaling params path:", config$data$scaling_params, "\n")

# Verify files exist before starting API
if (!file.exists(config$model$path)) {
  stop("Model file not found at: ", config$model$path)
}
if (!file.exists(config$data$scaling_params)) {
  stop("Scaling parameters file not found at: ", config$data$scaling_params)
}

cat("All required files verified\n")
cat("Starting API server at http://", config$api$host, ":", config$api$port, "\n")

# Start the plumber API
pr <- plumb("api/plumber.R")
pr$run(host = config$api$host, port = config$api$port)