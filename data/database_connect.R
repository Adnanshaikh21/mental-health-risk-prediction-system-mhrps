library(RPostgres)
library(DBI)
library(config)

setwd("C:/Project/Second")
if (!dir.exists("data/logs")) dir.create("data/logs", recursive = TRUE)

# Initialize logging
logger <- function(message) {
  cat(message, file = "data/logs/database_connect.log", append = TRUE)
}

connect_db <- function() {
  tryCatch({
    db_config <- config::get(file = "config/database_config.yaml")
    con <- dbConnect(
      Postgres(), # nolint
      host = db_config$database$host,
      port = db_config$database$port,
      dbname = db_config$database$dbname,
      user = db_config$database$user,
      password = db_config$database$password
    )
    logger("Successfully connected to database\n")
    return(con)
  }, error = function(e) {
    logger(sprintf("Database connection error: %s\n", e$message))
    stop("Database connection error: ", e$message)
  })
}

# Initialize database tables if they don't exist
tryCatch({
  con <- connect_db()
  dbExecute(con, "
    CREATE TABLE IF NOT EXISTS academic_data (
      student_id TEXT PRIMARY KEY,
      semester INTEGER,
      gpa FLOAT,
      attendance_rate FLOAT,
      course_failures INTEGER,
      academic_probation TEXT
    )")
  dbExecute(con, "
    CREATE TABLE IF NOT EXISTS behavioral_data (
      student_id TEXT PRIMARY KEY,
      library_visits INTEGER,
      extracurricular_hours FLOAT,
      campus_events_attended INTEGER,
      engagement_score FLOAT,
      behavioral_risk TEXT
    )")
  dbExecute(con, "
    CREATE TABLE IF NOT EXISTS survey_data (
      student_id TEXT PRIMARY KEY,
      consent TEXT,
      age INTEGER,
      gender TEXT,
      socioeconomic_status TEXT,
      living_situation TEXT,
      phq_total INTEGER,
      gad_total INTEGER,
      sleep_hours TEXT,
      exercise_frequency TEXT,
      extracurricular_participation TEXT,
      disciplinary_notices TEXT,
      academic_pressure_rating INTEGER,
      social_media_usage TEXT,
      social_media_feeling TEXT,
      image_pressure TEXT,
      comparison_feeling TEXT,
      mental_state TEXT,
      stress_color TEXT,
      emotional_resilience_rating INTEGER,
      negative_habit TEXT,
      mental_health_battery INTEGER,
      keeps_you_up TEXT,
      advice_to_past_self TEXT,
      self_harm_thoughts TEXT,
      contact_counselor TEXT,
      know_mental_health_support TEXT,
      used_counseling_services TEXT,
      hopeful_about_future TEXT,
      magic_wand_change TEXT
    )")
  dbExecute(con, "
    CREATE TABLE IF NOT EXISTS integrated_data (
      student_id TEXT PRIMARY KEY,
      semester INTEGER,
      gpa FLOAT,
      attendance_rate FLOAT,
      course_failures INTEGER,
      academic_probation TEXT,
      library_visits INTEGER,
      extracurricular_hours FLOAT,
      campus_events_attended INTEGER,
      engagement_score FLOAT,
      behavioral_risk TEXT,
      consent TEXT,
      age INTEGER,
      gender TEXT,
      socioeconomic_status TEXT,
      living_situation TEXT,
      phq_total INTEGER,
      gad_total INTEGER,
      sleep_hours TEXT,
      exercise_frequency TEXT,
      extracurricular_participation TEXT,
      disciplinary_notices TEXT,
      academic_pressure_rating INTEGER,
      social_media_usage TEXT,
      social_media_feeling TEXT,
      image_pressure TEXT,
      comparison_feeling TEXT,
      mental_state TEXT,
      stress_color TEXT,
      emotional_resilience_rating INTEGER,
      negative_habit TEXT,
      mental_health_battery INTEGER,
      keeps_you_up TEXT,
      advice_to_past_self TEXT,
      self_harm_thoughts TEXT,
      contact_counselor TEXT,
      know_mental_health_support TEXT,
      used_counseling_services TEXT,
      hopeful_about_future TEXT,
      magic_wand_change TEXT,
      mental_health_risk TEXT,
      mental_health_score INTEGER
    )")
  dbExecute(con, "
    CREATE TABLE IF NOT EXISTS preprocessed_data (
      student_id TEXT PRIMARY KEY,
      semester FLOAT,
      gpa FLOAT,
      attendance_rate FLOAT,
      course_failures FLOAT,
      academic_probation TEXT,
      library_visits FLOAT,
      extracurricular_hours FLOAT,
      campus_events_attended FLOAT,
      engagement_score FLOAT,
      behavioral_risk TEXT,
      consent TEXT,
      age INTEGER,
      gender TEXT,
      socioeconomic_status TEXT,
      living_situation TEXT,
      phq_total FLOAT,
      gad_total FLOAT,
      sleep_hours TEXT,
      exercise_frequency TEXT,
      extracurricular_participation TEXT,
      disciplinary_notices TEXT,
      academic_pressure_rating FLOAT,
      social_media_usage TEXT,
      social_media_feeling TEXT,
      image_pressure TEXT,
      comparison_feeling TEXT,
      mental_state TEXT,
      stress_color TEXT,
      emotional_resilience_rating FLOAT,
      negative_habit TEXT,
      mental_health_battery FLOAT,
      keeps_you_up TEXT,
      advice_to_past_self TEXT,
      self_harm_thoughts TEXT,
      contact_counselor TEXT,
      know_mental_health_support TEXT,
      used_counseling_services TEXT,
      hopeful_about_future TEXT,
      magic_wand_change TEXT,
      mental_health_risk TEXT,
      mental_health_score FLOAT
    )")
  dbExecute(con, "
    CREATE TABLE IF NOT EXISTS features_data (
      student_id TEXT PRIMARY KEY,
      mental_health_risk TEXT,
      phq_total FLOAT,
      gad_total FLOAT,
      self_harm_thoughts TEXT,
      mental_health_score FLOAT,
      academic_stress_index FLOAT,
      social_engagement_score FLOAT,
      digital_overload INTEGER
    )")
  dbExecute(con, "
    CREATE TABLE IF NOT EXISTS high_risk_alerts (
      student_id TEXT PRIMARY KEY,
      phq_total FLOAT,
      gad_total FLOAT,
      mental_health_score FLOAT
    )")
  dbDisconnect(con)
  logger("Database tables initialized\n")
}, error = function(e) {
  logger(sprintf("Error initializing database tables: %s\n", e$message))
  stop("Error initializing database tables: ", e$message)
})
cat("Database connection script initialized.\n")