library(plumber)
library(caret)
library(dplyr)
library(config)
library(jsonlite)

# Use absolute path for config file to avoid any working directory issues
config <- config::get(file = "C:/Project/Second/config/config.yaml")

# Convert relative paths to absolute paths
model_path <- file.path("C:/Project/Second", config$model$path)
scaling_path <- file.path("C:/Project/Second", config$data$scaling_params)

# Logger function with error handling
logger <- function(message, file = "api/logs/api_access.log") {
  tryCatch({
    dir.create(dirname(file), recursive = TRUE, showWarnings = FALSE)
    cat(sprintf("[%s] %s\n", Sys.time(), message), file = file, append = TRUE)
  }, error = function(e) {
    message(sprintf("Logger error: %s", e$message))
  })
}

# Helper function for null-coalescing operator
`%||%` <- function(x, y) {
  if (is.null(x)) y else x
}

# Helper function for error responses
create_error_response <- function(error_message, status_code = 500) {
  logger(sprintf("API Error [%d]: %s", status_code, error_message), "api/logs/api_error.log")
  
  response <- list(
    error = error_message,
    status = status_code,
    timestamp = as.character(Sys.time())
  )
  
  return(response)
}

#* @apiTitle Mental Health Prediction API
#* @apiDescription API for predicting mental health risk
#* @apiSecurity BearerAuth

#* Health check endpoint
#* @get /health
#* @serializer json
function() {
  tryCatch({
    logger("API: Health check accessed")
    
    # Simple health check
    current_dir <- getwd()
    
    logger(sprintf("API: Current directory: %s", current_dir))
    logger(sprintf("API: Model path: %s", model_path))
    logger(sprintf("API: Scaling path: %s", scaling_path))
    
    # Check if files exist
    model_exists <- file.exists(model_path)
    scaling_exists <- file.exists(scaling_path)
    
    logger(sprintf("API: Model file exists: %s", model_exists))
    logger(sprintf("API: Scaling file exists: %s", scaling_exists))
    
    if (model_exists && scaling_exists) {
      logger("API: Health check passed - returning OK")
      return(list(status = "OK", timestamp = as.character(Sys.time())))
    } else {
      warning_msg <- sprintf("Missing files - Model: %s, Scaling: %s", 
                           ifelse(model_exists, "OK", "MISSING"),
                           ifelse(scaling_exists, "OK", "MISSING"))
      logger(sprintf("API: Health check warning: %s", warning_msg))
      return(list(status = "WARNING", message = warning_msg, timestamp = as.character(Sys.time())))
    }
    
  }, error = function(e) {
    logger(sprintf("API: Health check error: %s", e$message), "api/logs/api_error.log")
    return(create_error_response(sprintf("Health check failed: %s", e$message), 500))
  })
}

#* Predict mental health risk
#* @post /predict
#* @param semester:integer Semester number (1-12)
#* @param gpa:numeric GPA (0.0-10.0)
#* @param attendance_rate:numeric Attendance percentage (0-100)
#* @param course_failures:integer Number of course failures (0-5)
#* @param academic_probation:string Academic probation status ("Yes" or "No")
#* @param phq_total:integer PHQ-9 total score (0-27)
#* @param gad_total:integer GAD-7 total score (0-21)
#* @param self_harm_thoughts:string Self-harm thoughts ("Yes" or "No")
#* @param mental_health_score:integer Enter mental health score
#* @param outcome:integer Enter Outcome
#* @serializer json
function(req, semester, gpa, attendance_rate, course_failures, academic_probation, phq_total, gad_total, self_harm_thoughts, mental_health_score, outcome) {
  tryCatch({
    # Log basic request info
    logger("API: Prediction request received")
    
    # Check Authorization header
    auth_header <- req$HTTP_AUTHORIZATION %||% req$headers$authorization
    if (is.null(auth_header)) {
      return(create_error_response("Missing Authorization header", 401))
    }

    # Validate API key
    expected_key <- paste0("Bearer ", config$api$key)
    if (auth_header != expected_key) {
      logger("API: Invalid API key provided", "api/logs/api_error.log")
      return(create_error_response("Invalid API key", 401))
    }

    # Handle JSON body if provided
    if (!is.null(req$postBody) && nchar(req$postBody) > 0) {
      tryCatch({
        body <- jsonlite::fromJSON(req$postBody)
        semester <- body$semester %||% semester
        gpa <- body$gpa %||% gpa
        attendance_rate <- body$attendance_rate %||% attendance_rate
        course_failures <- body$course_failures %||% course_failures
        academic_probation <- body$academic_probation %||% academic_probation
        phq_total <- body$phq_total %||% phq_total
        gad_total <- body$gad_total %||% gad_total
        self_harm_thoughts <- body$self_harm_thoughts %||% self_harm_thoughts
        mental_health_score <- body$mental_health_score %||% mental_health_score
        outcome <- body$outcome %||% outcome
      }, error = function(e) {
        return(create_error_response(sprintf("Invalid JSON in request body: %s", e$message), 400))
      })
    }

    # Quick validation of required parameters
    required_params <- list(
      phq_total = phq_total, 
      gad_total = gad_total, 
      self_harm_thoughts = self_harm_thoughts,
      mental_health_score = mental_health_score
    )
    
    missing_params <- names(required_params)[sapply(required_params, is.null)]
    if (length(missing_params) > 0) {
      return(create_error_response(sprintf("Missing required parameters: %s", paste(missing_params, collapse = ", ")), 400))
    }

    # Validate input ranges for the key parameters we use
    if (!is.numeric(as.numeric(phq_total)) || as.numeric(phq_total) < 0 || as.numeric(phq_total) > 27) {
      return(create_error_response("PHQ-9 Total must be between 0 and 27", 400))
    }
    if (!is.numeric(as.numeric(gad_total)) || as.numeric(gad_total) < 0 || as.numeric(gad_total) > 21) {
      return(create_error_response("GAD-7 Total must be between 0 and 21", 400))
    }
    if (!self_harm_thoughts %in% c("Yes", "No")) {
      return(create_error_response("Self-Harm Thoughts must be Yes or No", 400))
    }
    if (!is.numeric(as.numeric(mental_health_score))) {
      return(create_error_response("Mental Health Score must be numeric", 400))
    }

    # Check file paths and log them
    logger(sprintf("API: Looking for model at: %s", model_path))
    logger(sprintf("API: Looking for scaling params at: %s", scaling_path))
    logger(sprintf("API: Current working directory: %s", getwd()))

    # Check if model file exists
    if (!file.exists(model_path)) {
      error_msg <- sprintf("Model file not found at: %s (working dir: %s)", model_path, getwd())
      logger(error_msg, "api/logs/api_error.log")
      return(create_error_response(error_msg, 500))
    }

    # Check if scaling parameters exist
    if (!file.exists(scaling_path)) {
      error_msg <- sprintf("Scaling parameters file not found at: %s (working dir: %s)", scaling_path, getwd())
      logger(error_msg, "api/logs/api_error.log")
      return(create_error_response(error_msg, 500))
    }

    # Load model and scaling parameters
    logger("API: Loading model and scaling parameters")
    model <- readRDS(model_path)
    scaling_params <- readRDS(scaling_path)
    logger("API: Model and scaling parameters loaded successfully")

    # Prepare data for prediction (using only the features the model expects)
    new_data <- data.frame(
      phq_total = as.integer(phq_total),
      self_harm_thoughts = as.character(self_harm_thoughts),
      gad_total = as.integer(gad_total),
      mental_health_score = as.integer(mental_health_score)
    )

    # Apply scaling to numerical columns with error handling
    logger("API: Applying scaling to input data")
    
    # Check if scaling parameters exist for the required fields
    required_scaling <- c("phq_total", "gad_total", "mental_health_battery")  # Note: using mental_health_battery, not mental_health_score
    missing_scaling <- required_scaling[!required_scaling %in% names(scaling_params)]
    
    if (length(missing_scaling) > 0) {
      error_msg <- sprintf("Missing scaling parameters for: %s. Available: %s", 
                          paste(missing_scaling, collapse = ", "),
                          paste(names(scaling_params), collapse = ", "))
      logger(error_msg, "api/logs/api_error.log")
      return(create_error_response(error_msg, 500))
    }
    
    # Apply scaling using the correct parameter names
    new_data$phq_total <- (new_data$phq_total - scaling_params$phq_total$mean) / scaling_params$phq_total$sd
    new_data$gad_total <- (new_data$gad_total - scaling_params$gad_total$mean) / scaling_params$gad_total$sd
    
    # Use mental_health_battery instead of mental_health_score for scaling
    new_data$mental_health_score <- (new_data$mental_health_score - scaling_params$mental_health_battery$mean) / scaling_params$mental_health_battery$sd

    # Convert self_harm_thoughts to numeric
    new_data$self_harm_thoughts <- as.numeric(new_data$self_harm_thoughts == "Yes")

    # Log the processed input data
    logger(sprintf("API: Processed input data: %s", jsonlite::toJSON(new_data)))

    # Make prediction
    logger("API: Making prediction")
    prediction <- predict(model, new_data, type = "raw")
    probabilities <- predict(model, new_data, type = "prob")

    # Log prediction results
    logger(sprintf("API: Prediction completed: %s", prediction))
    logger(sprintf("API: Probabilities: %s", jsonlite::toJSON(probabilities)))

    # Return result
    result <- list(
      prediction = as.character(prediction),
      probabilities = as.list(probabilities),
      timestamp = as.character(Sys.time())
    )
    
    return(result)
    
  }, error = function(e) {
    error_msg <- sprintf("Internal server error: %s", e$message)
    logger(error_msg, "api/logs/api_error.log")
    return(create_error_response(error_msg, 500))
  })
}