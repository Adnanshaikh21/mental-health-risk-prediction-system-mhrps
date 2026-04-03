library(dplyr)
library(caret)

setwd("C:/Project/Second")
config <- config::get(file = "config/config.yaml")
data <- readRDS(config$data$cleaned)

engineered_data <- data %>%
  mutate(
    academic_stress_index = gpa * -1 + course_failures + academic_pressure_rating, # nolint
    social_engagement_score = extracurricular_hours + campus_events_attended,
    mental_health_score = phq_total + gad_total,
    digital_overload = ifelse(social_media_usage %in% c("4-6", "More than 6"), 1, 0) # nolint
  )

numerical_cols <- c("semester", "gpa", "attendance_rate", "course_failures", "library_visits", "extracurricular_hours", "campus_events_attended", "engagement_score", "phq_total", "gad_total", "academic_pressure_rating", "emotional_resilience_rating", "mental_health_battery", "academic_stress_index", "social_engagement_score", "mental_health_score") # nolint

corr_matrix <- cor(engineered_data[, numerical_cols], use = "complete.obs")
highly_correlated <- findCorrelation(corr_matrix, cutoff = 0.8, names = TRUE)
selected_data <- if (length(highly_correlated) > 0) engineered_data %>% select(-all_of(highly_correlated)) else engineered_data # nolint

set.seed(123)
ctrl <- rfeControl(functions = rfFuncs, method = "cv", number = 5)
rfe_results <- rfe(
  x = selected_data %>% select(-c(student_id, mental_health_risk)),
  y = selected_data$mental_health_risk,
  sizes = c(5, 10, 15),
  rfeControl = ctrl
)
selected_features <- predictors(rfe_results)
final_data <- selected_data %>% select(student_id, mental_health_risk, all_of(selected_features)) # nolint

saveRDS(final_data, config$data$features)
saveRDS(selected_features, config$data$selected_features)
cat("Engineered data saved to:", config$data$features, "\n")
cat("Selected features:", paste(selected_features, collapse = ", "), "\n")
print("Done with feature engineering.")