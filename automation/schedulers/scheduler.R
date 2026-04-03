library(taskscheduleR)
taskscheduler_create(
  taskname = "data_ingestion",
  rscript = "C:/Project/Second/automation/schedulers/data_ingestion_scheduler.R",
  schedule = "DAILY",
  starttime = "00:00"
)
taskscheduler_create(
  taskname = "model_retraining",
  rscript = "C:/Project/Second/automation/schedulers/model_retraining_scheduler.R",
  schedule = "WEEKLY",
  starttime = "00:00"
)
taskscheduler_create(
  taskname = "alerts",
  rscript = "C:/Project/Second/automation/schedulers/alert_scheduler.R",
  schedule = "DAILY",
  starttime = "00:00"
)