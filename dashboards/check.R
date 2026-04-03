library(RSQLite)
library(shinymanager)
library(jsonlite)

# Define credentials
credentials <- data.frame(
  user = c("counselor", "admin", "educator"),
  password = c("counselor123", "admin123", "educator123"),
  role = c("Counselor", "Admin", "Educator"),
  stringsAsFactors = FALSE
)

# Check permissions for database directory
db_dir <- "C:/Project/Second/dashboards"
db_path <- file.path(db_dir, "credentials.sqlite")
message("Checking database at: ", db_path)

if (!dir.exists(db_dir)) {
  message("Directory does not exist: ", db_dir, ". Creating directory...")
  dir.create(db_dir, recursive = TRUE)
}
if (file.access(db_dir, mode = 2) != 0) {
  message("No write permission for ", db_dir, ". Please run R as administrator or fix permissions.")
  stop("No write permission for database directory")
}

# Check if file exists
if (!file.exists(db_path)) {
  message("Database file does not exist. Creating new credentials.sqlite...")
  tryCatch({
    create_db(
      credentials_data = credentials,
      sqlite_path = db_path,
      passphrase = NULL
    )
    message("Credentials database created at: ", db_path)
  }, error = function(e) {
    message("Error creating credentials database: ", e$message)
    stop("Failed to create credentials database")
  })
} else {
  message("Database file exists: ", db_path)
}

# Connect and verify
tryCatch({
  con <- dbConnect(SQLite(), db_path)
  tables <- dbListTables(con)
  message("Tables in database: ", paste(tables, collapse = ", "))
  if ("credentials" %in% tables) {
    creds <- dbGetQuery(con, "SELECT * FROM credentials")
    message("Credentials data: ", toJSON(creds))
  } else {
    message("No credentials table found. Recreating database...")
    dbDisconnect(con)
    unlink(db_path)
    tryCatch({
      create_db(
        credentials_data = credentials,
        sqlite_path = db_path,
        passphrase = NULL
      )
      con <- dbConnect(SQLite(), db_path)
      creds <- dbGetQuery(con, "SELECT * FROM credentials")
      message("Credentials data after recreation: ", toJSON(creds))
    }, error = function(e) {
      message("Error recreating credentials database: ", e$message)
      stop("Failed to recreate credentials database")
    })
  }
  dbDisconnect(con)
}, error = function(e) {
  message("Error connecting to database: ", e$message)
  stop("Failed to connect to database")
})