library(dplyr)
library(tidyr)

setwd("C:/Project/Second")
config <- config::get(file = "config/config.yaml")
data <- readRDS(config$data$raw)

numerical_cols <- c("semester", "gpa", "attendance_rate", "course_failures", "library_visits", "extracurricular_hours", "campus_events_attended", "engagement_score", "phq_total", "gad_total", "academic_pressure_rating","emotional_resilience_rating", "mental_health_battery") # nolint
categorical_cols <- c("academic_probation", "behavioral_risk", "consent", "gender", "socioeconomic_status", "living_situation", "sleep_hours", "exercise_frequency", "extracurricular_participation", "disciplinary_notices", "social_media_usage", "social_media_feeling", "image_pressure", "comparison_feeling", "mental_state", "stress_color", "negative_habit", "keeps_you_up", "advice_to_past_self", "self_harm_thoughts", "contact_counselor", "know_mental_health_support", "used_counseling_services", "hopeful_about_future", "magic_wand_change", "mental_health_risk") # nolint

preprocessed_data <- data %>%
  mutate(
    across(all_of(numerical_cols), ~replace_na(., median(., na.rm = TRUE))),
    across(all_of(categorical_cols), ~replace_na(., names(sort(table(.), decreasing = TRUE))[1])), # nolint
    across(all_of(categorical_cols), as.factor)
  )

scaling_params <- list()
for (col in numerical_cols) {
  preprocessed_data[[col]] <- scale(preprocessed_data[[col]])[,1]
  scaling_params[[col]] <- list(
    mean = attr(scale(data[[col]], scale = FALSE), "scaled:center"),
    sd = attr(scale(data[[col]]), "scaled:scale")
  )
}

saveRDS(preprocessed_data, config$data$cleaned)
saveRDS(scaling_params, config$data$scaling_params)
cat("Preprocessed data saved to:", config$data$cleaned, "\n")
cat("Scaling parameters saved to:", config$data$scaling_params, "\n")
print("Done with data preprocessing.")