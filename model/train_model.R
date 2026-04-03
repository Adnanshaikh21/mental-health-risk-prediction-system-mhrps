library(caret)
library(randomForest)
library(smotefamily)
library(config)

# Clear environment and close connections
closeAllConnections()
rm(list = ls())

# Set working directory
setwd("C:/Project/Second")
cat("Working directory set to:", getwd(), "\n")

# Load configuration
config_file <- "config/config.yaml"
if (!file.exists(config_file)) stop("Config file not found: ", config_file)
tryCatch({
  config <- config::get(file = config_file)
  cat("Config loaded successfully\n")
}, error = function(e) {
  stop("Error loading config.yaml: ", e$message)
})

# Load data
rds_file <- config$data$features
if (!file.exists(rds_file)) stop("RDS file not found: ", rds_file)
tryCatch({
  data <- readRDS(rds_file)
  cat("RDS file loaded successfully\n")
}, error = function(e) {
  stop("Error loading RDS file: ", e$message)
})

# Convert student_id to character
data$student_id <- as.character(data$student_id)

# Convert factor columns to numeric for SMOTE
data$self_harm_thoughts <- as.numeric(data$self_harm_thoughts == "Yes")
data$contact_counselor <- as.numeric(data$contact_counselor == "Yes")

# Ensure mental_health_risk is a factor
data$mental_health_risk <- factor(data$mental_health_risk, levels = c("High", "Low", "Medium"))# nolint

# Split data
set.seed(123)
trainIndex <- createDataPartition(data$mental_health_risk, p = 0.7, list = FALSE)# nolint
train_data <- data[trainIndex, ]
test_data <- data[-trainIndex, ]
cat("Duplicated student_id across train and test:\n")
print(any(train_data$student_id %in% test_data$student_id))

# Apply SMOTE
predictors <- train_data[, !names(train_data) %in% c("student_id", "mental_health_risk", "contact_counselor")]# nolint
tryCatch({
  smote_data <- smotefamily::SMOTE(X = predictors, target = train_data$mental_health_risk, K = 5, dup_size = 2)# nolint
  train_data_smote <- smote_data$data
  train_data_smote$mental_health_risk <- factor(train_data_smote$class, levels = c("High", "Low", "Medium"))# nolint
  predictors_smote <- train_data_smote[, !names(train_data_smote) %in% c("class", "student_id", "mental_health_risk", "contact_counselor")]# nolint
  cat("SMOTE applied successfully\n")
  cat("Class distribution after SMOTE:\n")
  print(table(train_data_smote$mental_health_risk))
}, error = function(e) {
  stop("Error applying SMOTE: ", e$message)
})

# Define hyperparameter grid
tune_grid <- expand.grid(
  mtry = c(1, 2, 3),
  splitrule = c("gini"),
  min.node.size = c(5, 10, 15)
)

# Train model
tryCatch({
  model <- train(
    x = predictors_smote,
    y = train_data_smote$mental_health_risk,
    method = "ranger",
    tuneGrid = tune_grid,
    trControl = trainControl(
      method = "cv",
      number = 10,
      classProbs = TRUE,
      summaryFunction = multiClassSummary,
      allowParallel = FALSE
    ),
    num.trees = 500,
    importance = "impurity"
  )
  cat("Model training completed successfully\n")
}, error = function(e) {
  stop("Error during model training: ", e$message)
})

# Save model and test data
tryCatch({
  saveRDS(model, config$model$path)
  saveRDS(test_data, config$model$test_data)
  cat("Model saved to:", config$model$path, "\n")
  cat("Test data saved to:", config$model$test_data, "\n")
  cat("Best parameters:\n")
  print(model$bestTune)
}, error = function(e) {
  stop("Error saving model/test data: ", e$message)
})

# Diagnostics
cat("Missing values in train_data:\n")
print(colSums(is.na(train_data)))
cat("Class distribution in train_data:\n")
print(table(train_data$mental_health_risk))
cat("Variable importance:\n")
print(model$finalModel$variable.importance)
cat("Cross-validation results:\n")
print(model$results)