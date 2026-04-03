library(tidyverse)

# Set working directory
setwd("C:/Project/Second")
cat("Working directory set to:", getwd(), "\n")

# Logger function
logger <- function(message, file = "C:/Project/Second/api/logs/api_access.log") {
  cat(sprintf("[%s] %s\n", Sys.time(), message), file = file, append = TRUE)
}

# Function to normalize student_id
normalize_student_id <- function(id) {
  tolower(trimws(id))
}

# Main function
update_full_dataset <- function() {
  tryCatch({
    logger("Loading individual datasets")
    academic_data <- read_csv("data/output/academic_data.csv", col_types = cols(student_id = col_character())) %>%
      mutate(student_id = normalize_student_id(student_id))
    behavioral_data <- read_csv("data/output/behavioral_data.csv", col_types = cols(student_id = col_character())) %>%
      mutate(student_id = normalize_student_id(student_id))
    mental_health_data <- read_csv("data/output/mental_health_survey.csv", col_types = cols(student_id = col_character())) %>%
      mutate(student_id = normalize_student_id(student_id))
    
    logger("Combining datasets into full_student_dataset")
    full_dataset <- academic_data %>%
      inner_join(behavioral_data, by = "student_id") %>%
      inner_join(mental_health_data, by = "student_id")
      mutate(timestamp = Sys.time())
    
    logger("Saving full student dataset")
    write_csv(full_dataset, "data/output/full_student_dataset.csv")
    cat("Updated full_student_dataset.csv with", nrow(full_dataset), "records\n")
    
    return(full_dataset)
  }, error = function(e) {
    logger(sprintf("Error updating full dataset: %s", e$message), "C:/Project/Second/api/logs/api_error.log")
    stop(e)
  })
}

# Execute
update_full_dataset()