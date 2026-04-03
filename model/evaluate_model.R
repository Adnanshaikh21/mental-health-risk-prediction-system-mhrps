library(caret)
library(ggplot2)
library(config)

setwd("C:/Project/Second")
config <- config::get(file = "config/config.yaml")

# Load model and test data
if (!file.exists(config$model$path)) stop("Model file not found: ", config$model$path)# nolint
if (!file.exists(config$model$test_data)) stop("Test data file not found: ", config$model$test_data)# nolint
tryCatch({
  model <- readRDS(config$model$path)
  test_data <- readRDS(config$model$test_data)
}, error = function(e) {
  stop("Error loading model/test data: ", e$message)
})

# Prepare test predictors
test_predictors <- test_data[, !names(test_data) %in% c("student_id", "mental_health_risk", "contact_counselor")]# nolint

# Make predictions
tryCatch({
  predictions <- predict(model, test_predictors)
  probabilities <- predict(model, test_predictors, type = "prob")
}, error = function(e) {
  stop("Error making predictions: ", e$message)
})

# Create results data frame
results <- data.frame(
  student_id = test_data$student_id,
  actual = test_data$mental_health_risk,
  predicted = predictions,
  prob_high = probabilities$High,
  prob_low = probabilities$Low,
  prob_medium = probabilities$Medium
)

# Evaluate performance
conf_matrix <- confusionMatrix(predictions, test_data$mental_health_risk)
cat("Confusion Matrix and Statistics:\n")
print(conf_matrix)

# Save results
tryCatch({
  write.csv(as.table(conf_matrix), "model/output/performance_metrics.csv")
  write.csv(results, "model/output/predictions_with_student_id.csv", row.names = FALSE)# nolint
  cat("Performance metrics saved to: model/output/performance_metrics.csv\n")# nolint
  cat("Predictions with student_id saved to: model/output/predictions_with_student_id.csv\n")# nolint
}, error = function(e) {
  stop("Error saving results: ", e$message)
})

# Create bar chart
conf_df <- as.data.frame(as.table(conf_matrix))
ggplot(conf_df, aes(x = Prediction, y = Freq, fill = Reference)) +
  geom_bar(stat = "identity", position = "dodge") +
  labs(title = "Confusion Matrix", x = "Predicted Risk", y = "Count", fill = "Actual Risk") +# nolint
  scale_fill_manual(values = c("High" = "red", "Medium" = "yellow", "Low" = "green")) +# nolint
  theme_minimal()
ggsave("model/confusion_matrix_plot.jpeg")
cat("Confusion matrix plot saved to: model/confusion_matrix_plot.jpeg\n")# nolint