library(config)
library(caret)
library(randomForest)
library(smotefamily)
library(ranger)  # Added for ranger::importance

# Set working directory
setwd("C:/Project/Second")
cat("Working directory set to:", getwd(), "\n")

# Logger function
logger <- function(message, file = "C:/Project/Second/api/logs/api_access.log") {
  cat(sprintf("[%s] %s\n", Sys.time(), message), file = file, append = TRUE)
}

# Load configuration
logger("Loading configuration")
config <- config::get(file = "C:/Project/Second/config/config.yaml")
cat("Config loaded successfully\n")

# Retraining function
retrain_model <- function() {
  tryCatch({
    logger("Starting model retraining")
    
    # Source training script in the local environment
    logger("Step 1: Sourcing train_model.R")
    source("C:/Project/Second/model/train_model.R", local = TRUE)
    
    # Check for duplicated student_id
    logger("Step 2: Checking for duplicated student_id")
    if (any(train_data$student_id %in% test_data$student_id)) {
      logger("Duplicated student_id found", "C:/Project/Second/api/logs/api_error.log")
      stop("Duplicated student_id across train and test")
    } else {
      logger("No duplicated student_id found")
      cat("Duplicated student_id across train and test:\n")
      print(any(train_data$student_id %in% test_data$student_id))
    }
    
    # Log metrics
    logger("Step 3: Logging performance metrics")
    cat("Best parameters:\n")
    print(model$bestTune)
    
    # Log diagnostics
    logger("Step 4: Logging diagnostics")
    cat("Missing values in train_data:\n")
    print(colSums(is.na(train_data)))
    cat("Class distribution in train_data:\n")
    print(table(train_data$mental_health_risk))
    cat("Variable importance:\n")
    print(ranger::importance(model$finalModel))
    cat("Cross-validation results:\n")
    print(model$results)
    
    logger("Model retraining completed successfully")
  }, error = function(e) {
    logger(sprintf("Model retraining error at step: %s", e$message), 
           "C:/Project/Second/api/logs/api_error.log")
    stop(e)
  })
}

# Schedule retraining
cat("Model retraining scheduler started\n")
logger("Model retraining scheduler started")
while (TRUE) {
  retrain_model()
  Sys.sleep(60)  # Sleep for 30 days
}