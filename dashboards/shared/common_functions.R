library(httr)
library(jsonlite)

# Logger function
logger <- function(message, file = "api/logs/api_access.log") {
  cat(sprintf("[%s] %s\n", Sys.time(), message), file = file, append = TRUE)
}

# Prediction function
make_prediction <- function(new_data, config) {
  tryCatch({
    # Prepare JSON payload
    payload <- toJSON(new_data, auto_unbox = TRUE)
    logger(sprintf("Common Functions: Sending prediction request: %s", payload))
    
    # Make API call
    response <- POST(
      sprintf("http://%s:%s/predict", config$api$host, config$api$port),
      add_headers(Authorization = paste("Bearer", config$api$key)),
      content_type_json(),
      body = payload
    )
    
    # Check response
    if (status_code(response) != 200) {
      logger(sprintf("Common Functions: Prediction API error: %s", content(response, "text")), "api/logs/api_error.log")
      return(list(error = content(response, "text"), status = status_code(response)))
    }
    
    # Parse result
    result <- content(response, "parsed")
    logger(sprintf("Common Functions: Prediction result: %s", toJSON(result)))
    result
  }, error = function(e) {
    logger(sprintf("Common Functions: Prediction error: %s", e$message), "api/logs/api_error.log")
    list(error = e$message, status = 500)
  })
}