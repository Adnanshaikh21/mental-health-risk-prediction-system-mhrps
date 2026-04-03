library(dplyr)

setwd("C:/Project/Second")
config <- config::get(file = "config/config.yaml")

# Load datasets
tryCatch({
  academic_data <- read.csv("data/output/academic_data.csv")
  behavioral_data <- read.csv("data/output/behavioral_data.csv")
  survey_data <- read.csv("data/output/mental_health_survey.csv")
}, error = function(e) {
  stop("Error loading datasets: ", e$message)
})

# Define required columns
required_cols <- c("student_id", "semester", "gpa", "attendance_rate", "course_failures", "academic_probation", "library_visits", "extracurricular_hours", "campus_events_attended", "engagement_score", "behavioral_risk", "consent", "age", "gender", "socioeconomic_status", "living_situation", "phq_total", "gad_total", "sleep_hours", "exercise_frequency", "extracurricular_participation", "disciplinary_notices", "academic_pressure_rating", "social_media_usage", "social_media_feeling", "image_pressure", "comparison_feeling", "mental_state", "stress_color", "emotional_resilience_rating", "negative_habit", "mental_health_battery", "keeps_you_up", "advice_to_past_self", "self_harm_thoughts", "contact_counselor", "know_mental_health_support", "used_counseling_services", "hopeful_about_future", "magic_wand_change")

# Validate columns
missing_cols <- setdiff(required_cols, c(names(academic_data), names(behavioral_data), names(survey_data)))
if (length(missing_cols) > 0) {
  stop("Missing columns: ", paste(missing_cols, collapse = ", "))
}

# Integrate datasets
integrated_data <- academic_data %>%
  inner_join(behavioral_data, by = "student_id") %>%
  inner_join(survey_data, by = "student_id") %>%
  mutate(
    mental_health_risk = case_when(
      phq_total >= 20 | gad_total >= 15 | self_harm_thoughts == "Yes" ~ "High",
      phq_total >= 10 | gad_total >= 8 ~ "Medium",
      TRUE ~ "Low"
    ) %>% as.factor()
  )

saveRDS(integrated_data, config$data$raw)
cat("Integrated dataset saved to:", config$data$raw, "\n")

print("Done with data integration.")