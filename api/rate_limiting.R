library(lubridate)
library(dplyr)
library(readr)

setwd("C:/Project/Second")
if (!dir.exists("api")) dir.create("api", recursive = TRUE)

request_log_file <- "api/logs/request_log.csv"
if (!file.exists(request_log_file)) {
  write_csv(data.frame(timestamp = as.POSIXct(character()), ip = character()), request_log_file)
}

check_rate_limit <- function(max_requests = 100, per_minutes = 60) {
  current_time <- now()
  request_log <- read_csv(request_log_file, col_types = cols(timestamp = "T", ip = "c"))
  request_log <- request_log[request_log$timestamp > current_time - minutes(per_minutes), ]
  if (nrow(request_log) >= max_requests) return(FALSE)
  request_log <- rbind(request_log, data.frame(timestamp = current_time, ip = "unknown"))
  write_csv(request_log, request_log_file)
  return(TRUE)
}