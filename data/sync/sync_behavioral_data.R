# h//ttps://docs.google.com/spreadsheets/d/1-aMO7FkWcgjA68j4ypSU8rCBrm01Eh3bgGKrPfOv0F8/edit?resourcekey=&pli=1&gid=1374517250#gid=1374517250
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
behavioral_sheet_id <- "1-aMO7FkWcgjA68j4ypSU8rCBrm01Eh3bgGKrPfOv0F8"

# Function to normalize student_id
normalize_student_id <- function(id) {
  tolower(trimws(id))
}

# Main function
sync_behavioral_data <- function() {
  tryCatch({
    logger("Reading Student Engagement Data from Google Sheets")
    new_data <- read_sheet(behavioral_sheet_id) %>%
      rename(
        timestamp = Timestamp,
        student_id = `Student ID`,
        library_visits = `Library Visits (Past Month)`,
        extracurricular_hours = `Extracurricular Hours/Week`,
        campus_events_attended = `Campus Events Attended`
      ) %>%
      mutate(
        student_id = normalize_student_id(student_id),
        library_visits = as.integer(library_visits),
        extracurricular_hours = as.numeric(extracurricular_hours),
        campus_events_attended = as.integer(campus_events_attended),
        engagement_score = round((library_visits * 0.3) + (extracurricular_hours * 0.4) + (campus_events_attended * 0.3), 1),
        behavioral_risk = case_when(
          engagement_score < 2.5 ~ "high",
          engagement_score < 4.0 ~ "medium",
          TRUE ~ "low"
        )
      ) %>%
      select(student_id, library_visits, extracurricular_hours, campus_events_attended, engagement_score, behavioral_risk)
    
    logger("Loading existing behavioral data")
    existing_data <- read_csv("data/output/behavioral_data.csv", col_types = cols(student_id = col_character())) %>%
      mutate(student_id = normalize_student_id(student_id))
    
    # Update or append
    updated_data <- existing_data %>%
      filter(!student_id %in% new_data$student_id) %>%
      bind_rows(new_data) %>%
      arrange(student_id)
    
    logger("Saving updated behavioral data")
    write_csv(updated_data, "data/output/behavioral_data.csv")
    cat("Updated behavioral_data.csv with", nrow(new_data), "new or updated records\n")
    
    return(updated_data)
  }, error = function(e) {
    logger(sprintf("Error syncing behavioral data: %s", e$message), "C:/Project/Second/api/logs/api_error.log")
    stop(e)
  })
}

# Execute
sync_behavioral_data()