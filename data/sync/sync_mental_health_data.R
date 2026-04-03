# h//ttps://docs.google.com/spreadsheets/d/1jSIwjjP6a7c2snkcZxcSS-SYTyRYyuqONU_YXmJFp6g/edit?resourcekey=&pli=1&gid=707215548#gid=707215548
library(googlesheets4)
library(tidyverse)

# Set working directory
setwd("C:/Project/Second")
cat("Working directory set to:", getwd(), "\n")

# Logger function
logger <- function(message, file = "C:/Project/Second/api/logs/api_access.log") {
  cat(sprintf("[%s] %s\n", Sys.time(), message), file = file, append = TRUE)
}

# Google Sheet ID (replace with actual ID)
mental_health_sheet_id <- "1jSIwjjP6a7c2snkcZxcSS-SYTyRYyuqONU_YXmJFp6g"

# Function to normalize student_id
normalize_student_id <- function(id) {
  tolower(trimws(id))
}

# Function to convert Likert scale responses to numeric
likert_to_numeric <- function(response) {
  case_when(
    response == "0 – Not at all" ~ 0,
    response == "1 – Several days" ~ 1,
    response == "2 – More than half the days" ~ 2,
    response == "3 – Nearly every day" ~ 3,
    TRUE ~ NA_real_
  )
}

# Function to clean and convert mental_health_battery
clean_mental_health_battery <- function(value) {
  # Remove "%" and any non-numeric characters, trim whitespace
  cleaned <- gsub("[^0-9]", "", trimws(value))
  # Convert to integer, return NA if not a valid number
  result <- as.integer(cleaned)
  if (is.na(result) || result < 0 || result > 100) {
    logger(sprintf("Invalid mental_health_battery value: %s", value), "C:/Project/Second/api/logs/api_error.log")
    return(NA_integer_)
  }
  result
}

# Main function
sync_mental_health_data <- function() {
  tryCatch({
    logger("Reading Complete Student Mental Health Survey from Google Sheets")
    new_data <- read_sheet(mental_health_sheet_id) %>%
      rename(
        timestamp = Timestamp,
        consent = `1. I consent to participate and understand responses are confidential.`,
        student_id = `2. Student ID`,
        age = `3. Age`,
        gender = `4. Gender`,
        socioeconomic_status = `5. Socioeconomic status`,
        living_situation = `6. Living situation`,
        phq_1 = `7. Little interest or pleasure in doing things`,
        phq_2 = `8. Feeling down, depressed, or hopeless`,
        phq_3 = `9. Trouble falling/staying asleep or sleeping too much`,
        phq_4 = `10. Feeling tired or having little energy`,
        phq_5 = `11. Poor appetite or overeating`,
        phq_6 = `12. Feeling bad about yourself—or that you are a failure`,
        phq_7 = `13. Trouble concentrating on things`,
        phq_8 = `14. Moving/speaking slowly or restlessness`,
        phq_9 = `15. Thoughts of being better off dead or self-harm`,
        gad_1 = `16. Feeling nervous, anxious, or on edge`,
        gad_2 = `17. Not being able to stop or control worrying`,
        gad_3 = `18. Worrying too much about different things`,
        gad_4 = `19. Trouble relaxing`,
        gad_5 = `20. Being so restless it's hard to sit still`,
        gad_6 = `21. Becoming easily annoyed or irritable`,
        gad_7 = `22. Feeling afraid something awful might happen`,
        sleep_hours = `23. Hours of sleep/night`,
        exercise_frequency = `24. How often do you exercise?`,
        extracurricular_participation = `25. Participation in social/extracurriculars`,
        disciplinary_notices = `26. Any disciplinary notices this year?`,
        academic_pressure_rating = `27. Academic pressure (1–10)`,
        social_media_usage = `28. Daily time on social media`,
        social_media_feeling = `29. Social media makes me feel:`,
        image_pressure = `30. Feel pressure to maintain image online?`,
        comparison_feeling = `31. Compare life online and feel worse`,
        mental_state = `32. Mental state in one word`,
        stress_color = `33. If your stress was a color, what and why?`,
        emotional_resilience_rating = `34. Emotional resilience (1–10)`,
        negative_habit = `35. Habit negatively impacting mental health?`,
        mental_health_battery = `36. Mental health battery (% charged)`,
        keeps_you_up = `37. What keeps you up at night?`,
        advice_to_past_self = `38. One advice to past self about stress?`,
        self_harm_thoughts = `39. Had thoughts of harming yourself in the past 30 days?`,
        contact_counselor = `40. Would you like to be contacted by a counselor?`,
        know_mental_health_support = `41. Know where to get mental health support on campus?`,
        used_counseling_services = `42. Used counseling services before?`,
        hopeful_about_future = `43. Feel hopeful about your future?`,
        magic_wand_change = `44. Magic wand: change one thing in academic life?`
      ) %>%
      mutate(
        student_id = normalize_student_id(student_id),
        age = as.integer(age),
        academic_pressure_rating = as.integer(academic_pressure_rating),
        emotional_resilience_rating = as.integer(emotional_resilience_rating),
        mental_health_battery = sapply(mental_health_battery, clean_mental_health_battery),
        phq_1 = likert_to_numeric(phq_1),
        phq_2 = likert_to_numeric(phq_2),
        phq_3 = likert_to_numeric(phq_3),
        phq_4 = likert_to_numeric(phq_4),
        phq_5 = likert_to_numeric(phq_5),
        phq_6 = likert_to_numeric(phq_6),
        phq_7 = likert_to_numeric(phq_7),
        phq_8 = likert_to_numeric(phq_8),
        phq_9 = likert_to_numeric(phq_9),
        gad_1 = likert_to_numeric(gad_1),
        gad_2 = likert_to_numeric(gad_2),
        gad_3 = likert_to_numeric(gad_3),
        gad_4 = likert_to_numeric(gad_4),
        gad_5 = likert_to_numeric(gad_5),
        gad_6 = likert_to_numeric(gad_6),
        gad_7 = likert_to_numeric(gad_7),
        phq_total = phq_1 + phq_2 + phq_3 + phq_4 + phq_5 + phq_6 + phq_7 + phq_8 + phq_9,
        gad_total = gad_1 + gad_2 + gad_3 + gad_4 + gad_5 + gad_6 + gad_7,
        mental_health_risk = case_when(
          phq_total >= 20 | self_harm_thoughts == "Yes" ~ "High",
          phq_total >= 10 | gad_total >= 10 ~ "Medium",
          TRUE ~ "Low"
        )
      ) %>%
      select(
        student_id, consent, age, gender, socioeconomic_status, living_situation,
        phq_1, phq_2, phq_3, phq_4, phq_5, phq_6, phq_7, phq_8, phq_9, phq_total,
        gad_1, gad_2, gad_3, gad_4, gad_5, gad_6, gad_7, gad_total,
        sleep_hours, exercise_frequency, extracurricular_participation,
        disciplinary_notices, academic_pressure_rating, social_media_usage,
        social_media_feeling, image_pressure, comparison_feeling, mental_state,
        stress_color, emotional_resilience_rating, negative_habit,
        mental_health_battery, keeps_you_up, advice_to_past_self,
        self_harm_thoughts, contact_counselor, know_mental_health_support,
        used_counseling_services, hopeful_about_future, magic_wand_change,
        mental_health_risk
      )
    
    logger("Loading existing mental health survey data")
    existing_data <- read_csv("data/output/mental_health_survey.csv", col_types = cols(student_id = col_character())) %>%
      mutate(student_id = normalize_student_id(student_id))
    
    # Update or append
    updated_data <- existing_data %>%
      filter(!student_id %in% new_data$student_id) %>%
      bind_rows(new_data) %>%
      arrange(student_id)
    
    logger("Saving updated mental health survey data")
    write_csv(updated_data, "data/output/mental_health_survey.csv")
    cat("Updated mental_health_survey.csv with", nrow(new_data), "new or updated records\n")
    
    return(updated_data)
  }, error = function(e) {
    logger(sprintf("Error syncing mental health data: %s", e$message), "C:/Project/Second/api/logs/api_error.log")
    stop(e)
  })
}

# Execute
sync_mental_health_data()