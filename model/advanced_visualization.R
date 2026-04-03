library(caret)
library(pROC)
library(ggplot2)
library(config)

setwd("C:/Project/Second")
config <- config::get(file = "config/config.yaml")

# Load model and test data
if (!file.exists(config$model$path)) stop("Model file not found: ", config$model$path)
if (!file.exists(config$model$test_data)) stop("Test data file not found: ", config$model$test_data)
tryCatch({
  model <- readRDS(config$model$path)
  test_data <- readRDS(config$model$test_data)
}, error = function(e) {
  stop("Error loading model/test data: ", e$message)
})

# Prepare test predictors
test_predictors <- test_data[, !names(test_data) %in% c("student_id", "mental_health_risk", "contact_counselor")]

# Make predictions
tryCatch({
  probabilities <- predict(model, test_predictors, type = "prob")
}, error = function(e) {
  stop("Error making predictions: ", e$message)
})

# ROC Curves
roc_high <- roc(test_data$mental_health_risk == "High", probabilities$High)
roc_low <- roc(test_data$mental_health_risk == "Low", probabilities$Low)
roc_medium <- roc(test_data$mental_health_risk == "Medium", probabilities$Medium)
ggroc(list(High = roc_high, Low = roc_low, Medium = roc_medium)) +
  labs(title = "ROC Curves for Mental Health Risk Classes", x = "1 - Specificity", y = "Sensitivity") +
  theme_minimal()
ggsave("model/output/roc_curves.jpeg")
cat("ROC curves saved to: model/output/roc_curves.jpeg\n")

# Feature Importance Plot
var_imp <- as.data.frame(model$finalModel$variable.importance)
var_imp$Feature <- rownames(var_imp)
colnames(var_imp) <- c("Importance", "Feature")
ggplot(var_imp, aes(x = reorder(Feature, Importance), y = Importance)) +
  geom_bar(stat = "identity", fill = "steelblue") +
  coord_flip() +
  labs(title = "Feature Importance in Random Forest Model", x = "Feature", y = "Importance") +
  theme_minimal()
ggsave("model/output/feature_importance.jpeg")
cat("Feature importance plot saved to: model/output/feature_importance.jpeg\n")

# Risk Probability Heatmap
results <- read.csv("model/output/predictions_with_student_id.csv")
ggplot(results, aes(x = prob_high, y = prob_medium, color = actual)) +
  geom_point() +
  labs(title = "Risk Probability Heatmap", x = "Probability High Risk", y = "Probability Medium Risk", color = "Actual Risk") +
  scale_color_manual(values = c("High" = "red", "Medium" = "yellow", "Low" = "green")) +
  theme_minimal()
ggsave("model/output/risk_probability_heatmap.jpeg")
cat("Risk probability heatmap saved to: model/output/risk_probability_heatmap.jpeg\n")