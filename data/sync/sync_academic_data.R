# h//ttps://docs.google.com/spreadsheets/d/1et83PmyxeYxqVmTPVXXxNCgojm8EEJWgUC9UjumNr4c/edit?resourcekey=&pli=1&hl=en_GB&gid=787912738#gid=787912738
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
academic_sheet_id <- ""

# Function to normalize student_id
normalize_student_id <- function(id) {
  tolower(trimws(id))
}

# Main function
sync_academic_data <- function() {
  tryCatch({
    logger("Reading Academic Performance Data from Google Sheets")
    new_data <- read_sheet(academic_sheet_id) %>%
      rename(
        timestamp = Timestamp,
        student_id = `Student ID`,
        gpa = `GPA (0.0–10.0)`,
        attendance_rate = `Attendance Rate (%)`,
        course_failures = `Course Failures`,
        semester = `Current Semester`,
        academic_probation = `Academic Probation`
      ) %>%
      mutate(
        student_id = normalize_student_id(student_id),
        gpa = as.numeric(gpa),
        attendance_rate = as.numeric(attendance_rate),
        course_failures = as.integer(course_failures),
        semester = as.integer(semester),
        academic_probation = as.character(academic_probation)
      ) %>%
      select(student_id, semester, gpa, attendance_rate, course_failures, academic_probation)
    
    logger("Loading existing academic data")
    existing_data <- read_csv("data/output/academic_data.csv", col_types = cols(student_id = col_character())) %>%
      mutate(student_id = normalize_student_id(student_id))
    
    # Update or append
    updated_data <- existing_data %>%
      filter(!student_id %in% new_data$student_id) %>%
      bind_rows(new_data) %>%
      arrange(student_id)
    
    logger("Saving updated academic data")
    write_csv(updated_data, "data/output/academic_data.csv")
    cat("Updated academic_data.csv with", nrow(new_data), "new or updated records\n")
    
    return(updated_data)
  }, error = function(e) {
    logger(sprintf("Error syncing academic data: %s", e$message), "C:/Project/Second/api/logs/api_error.log")
    stop(e)
  })
}

# Execute
sync_academic_data()
