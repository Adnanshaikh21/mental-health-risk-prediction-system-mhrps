library(jose)
library(config)

# Load configuration
config <- config::get(file = "C:/Project/Second/config/config.yaml")

# Logger function
logger <- function(message, file = "C:/Project/Second/api/logs/api_access.log") {
  cat(sprintf("[%s] %s\n", Sys.time(), message), file = file, append = TRUE)
}

# JWT authentication function
authenticate_jwt <- function(req) {
  tryCatch({
    auth_header <- req$HTTP_AUTHORIZATION
    if (is.null(auth_header) || !grepl("^Bearer ", auth_header)) {
      logger("Missing or invalid Authorization header", "C:/Project/Second/api/logs/api_error.log")
      return(list(error = "Missing or invalid Authorization header", status = 401))
    }
    
    token <- sub("^Bearer ", "", auth_header)
    decoded <- jwt_decode_hmac(token, secret = config$api$key)
    
    if (is.null(decoded)) {
      logger("Invalid JWT token", "C:/Project/Second/api/logs/api_error.log")
      return(list(error = "Invalid JWT token", status = 401))
    }
    
    return(list(user = decoded$user, role = decoded$role))
  }, error = function(e) {
    logger(sprintf("Authentication error: %s", e$message), "C:/Project/Second/api/logs/api_error.log")
    return(list(error = "Authentication failed", status = 401))
  })
}