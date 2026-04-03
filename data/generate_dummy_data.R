# Load required libraries
library(tidyverse)
library(lubridate)

# Set working directory
setwd("C:/Project/Second")

# Set seed for reproducibility
set.seed(123)

# Configuration
n_students <- 1000
start_date <- as.Date("2023-09-01")
end_date <- as.Date("2024-01-31")

# Helper functions
generate_phq9 <- function() sample(0:3, 9, replace = TRUE, prob = c(0.4, 0.3, 0.2, 0.1)) # nolint
generate_gad7 <- function() sample(0:3, 7, replace = TRUE, prob = c(0.5, 0.25, 0.15, 0.1)) # nolint

# Academic Data
academic_data <- tibble(
  student_id = 1:n_students,
  semester = sample(1:12, n_students, replace = TRUE),
  gpa = round(runif(n_students, 0.0, 10.0), 2),
  attendance_rate = round(runif(n_students, 65, 100), 1), # Percentage
  course_failures = rpois(n_students, lambda = 0.3),
  academic_probation = ifelse(gpa < 2.5 & attendance_rate < 75, sample(c("Yes", "No"), n_students, replace = TRUE, prob = c(0.7, 0.3)), "No") # nolint
)

# Behavioral Data
behavioral_data <- tibble(
  student_id = 1:n_students,
  library_visits = rpois(n_students, lambda = 8),
  extracurricular_hours = round(runif(n_students, 0, 15), 1),
  campus_events_attended = rpois(n_students, lambda = 3)
) %>%
  mutate(
    engagement_score = round((library_visits * 0.3) + (extracurricular_hours * 0.4) + (campus_events_attended * 0.3), 1), # nolint
    behavioral_risk = case_when(
      engagement_score < 2.5 ~ "high",
      engagement_score < 4.0 ~ "medium",
      TRUE ~ "low"
    )
  )

# Mental Health Survey Data
survey_data <- tibble(student_id = 1:n_students) %>%
  mutate(
    consent = sample(c("Yes", "No"), n_students, replace = TRUE, prob = c(0.95, 0.05)), # nolint
    age = sample(18:25, n_students, replace = TRUE),
    gender = sample(c("Male", "Female", "Other", "Prefer not to say"), n_students, replace = TRUE, prob = c(0.45, 0.45, 0.05, 0.05)), # nolint
    socioeconomic_status = sample(c("Low", "Middle", "High"), n_students, replace = TRUE, prob = c(0.25, 0.60, 0.15)), # nolint
    living_situation = sample(c("On-campus", "Off-campus with friends", "Off-campus with family", "Alone"), n_students, replace = TRUE), # nolint
    phq_responses = map(1:n_students, ~generate_phq9()),
    phq_1 = map_dbl(phq_responses, ~.[1]),
    phq_2 = map_dbl(phq_responses, ~.[2]),
    phq_3 = map_dbl(phq_responses, ~.[3]),
    phq_4 = map_dbl(phq_responses, ~.[4]),
    phq_5 = map_dbl(phq_responses, ~.[5]),
    phq_6 = map_dbl(phq_responses, ~.[6]),
    phq_7 = map_dbl(phq_responses, ~.[7]),
    phq_8 = map_dbl(phq_responses, ~.[8]),
    phq_9 = map_dbl(phq_responses, ~.[9]),
    phq_total = phq_1 + phq_2 + phq_3 + phq_4 + phq_5 + phq_6 + phq_7 + phq_8 + phq_9, # nolint
    gad_responses = map(1:n_students, ~generate_gad7()),
    gad_1 = map_dbl(gad_responses, ~.[1]),
    gad_2 = map_dbl(gad_responses, ~.[2]),
    gad_3 = map_dbl(gad_responses, ~.[3]),
    gad_4 = map_dbl(gad_responses, ~.[4]),
    gad_5 = map_dbl(gad_responses, ~.[5]),
    gad_6 = map_dbl(gad_responses, ~.[6]),
    gad_7 = map_dbl(gad_responses, ~.[7]),
    gad_total = gad_1 + gad_2 + gad_3 + gad_4 + gad_5 + gad_6 + gad_7,
    sleep_hours = sample(c("Less than 4", "4-6", "6-8", "More than 8"), n_students, replace = TRUE, prob = c(0.1, 0.4, 0.4, 0.1)), # nolint
    exercise_frequency = sample(c("Never", "Occasionally", "2-3 times/week", "Daily"), n_students, replace = TRUE, prob = c(0.2, 0.4, 0.3, 0.1)), # nolint
    extracurricular_participation = sample(c("No", "Rarely", "Often", "Very frequently"), n_students, replace = TRUE, prob = c(0.2, 0.3, 0.3, 0.2)), # nolint
    disciplinary_notices = sample(c("Yes", "No"), n_students, replace = TRUE, prob = c(0.15, 0.85)), # nolint
    academic_pressure_rating = sample(1:10, n_students, replace = TRUE),
    social_media_usage = sample(c("Less than 1", "1-3", "4-6", "More than 6"), n_students, replace = TRUE, prob = c(0.1, 0.4, 0.3, 0.2)), # nolint
    social_media_feeling = sample(c("Connected", "Isolated"), n_students, replace = TRUE, prob = c(0.6, 0.4)), # nolint
    image_pressure = sample(c("Yes", "No"), n_students, replace = TRUE, prob = c(0.7, 0.3)), # nolint
    comparison_feeling = sample(c("Never", "Rarely", "Sometimes", "Often"), n_students, replace = TRUE, prob = c(0.2, 0.3, 0.3, 0.2)), # nolint
    mental_state = sample(c("Stressed", "Anxious", "Overwhelmed", "Calm", "Tired", "Optimistic"), n_students, replace = TRUE), # nolint
    stress_color = sample(c("Red", "Gray", "Black", "Blue", "Yellow"), n_students, replace = TRUE), # nolint
    emotional_resilience_rating = sample(1:10, n_students, replace = TRUE),
    negative_habit = sample(c("Procrastination", "Overthinking", "Social Media", "Poor Sleep", "None"), n_students, replace = TRUE, prob = c(0.3, 0.3, 0.2, 0.15, 0.05)), # nolint
    mental_health_battery = sample(0:100, n_students, replace = TRUE),
    keeps_you_up = sample(c("Academic pressure", "Relationship issues", "Financial worries", "Health concerns"), n_students, replace = TRUE), # nolint
    advice_to_past_self = sample(c("Take breaks", "Seek help earlier", "Don't compare yourself", "Prioritize health"), n_students, replace = TRUE), # nolint
    self_harm_thoughts = ifelse(phq_total >= 20, sample(c("Yes", "No"), n_students, replace = TRUE, prob = c(0.8, 0.2)), sample(c("Yes", "No"), n_students, replace = TRUE, prob = c(0.05, 0.95))), # nolint
    contact_counselor = ifelse(self_harm_thoughts == "Yes", sample(c("Yes", "No"), n_students, replace = TRUE, prob = c(0.6, 0.4)), NA), # nolint
    know_mental_health_support = sample(c("Yes", "No"), n_students, replace = TRUE, prob = c(0.4, 0.6)), # nolint
    used_counseling_services = sample(c("Yes", "No"), n_students, replace = TRUE, prob = c(0.3, 0.7)), # nolint
    hopeful_about_future = sample(c("Yes", "No", "Unsure"), n_students, replace = TRUE, prob = c(0.5, 0.2, 0.3)), # nolint
    magic_wand_change = sample(c("Less pressure", "More time", "Better support", "Financial security"), n_students, replace = TRUE) # nolint
  ) %>%
  select(-phq_responses, -gad_responses)

# Combine datasets
full_dataset <- academic_data %>%
  inner_join(behavioral_data, by = "student_id") %>%
  inner_join(survey_data, by = "student_id")

# Save datasets
write_csv(academic_data, "data/output/academic_data.csv")
write_csv(behavioral_data, "data/output/behavioral_data.csv")
write_csv(survey_data, "data/output/mental_health_survey.csv")
write_csv(full_dataset, "data/output/full_student_dataset.csv")

cat("Datasets generated:\n")
cat("- data/output/academic_data.csv\n")
cat("- data/output/behavioral_data.csv\n")
cat("- data/output/mental_health_survey.csv\n")
cat("- data/output/full_student_dataset.csv\n")

print("Done with generate dummy data.")