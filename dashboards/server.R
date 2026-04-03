library(shiny)
library(shinydashboard)
library(shinymanager)
library(RSQLite)
library(dplyr)
library(ggplot2)
library(DT)
library(httr)
library(jsonlite)
library(caret)
library(config)
library(shinyjs)
library(plotly)
library(ranger)
library(openssl)

# Define database path
db_path <- "C:/Project/Second/dashboards/credentials.sqlite"

# Set working directory and ensure directories exist
setwd("C:/Project/Second")
if (!dir.exists("dashboards")) dir.create("dashboards", recursive = TRUE)
if (!dir.exists("api/logs")) dir.create("api/logs", recursive = TRUE)

# Load configuration
config <- tryCatch({
  config::get(file = "config/config.yaml")
}, error = function(e) {
  message("Error loading config: ", e$message)
  stop("Failed to load config.yaml")
})
# Source common functions
common_functions_path <- "dashboards/shared/common_functions.R"
if (!file.exists(common_functions_path)) {
  logger(sprintf("Combined Dashboard: Common functions file not found: %s", common_functions_path), "api/logs/api_error.log") # nolint
} else {
  source(common_functions_path)
  logger("Combined Dashboard: Successfully sourced common_functions.R")
}

# Hash sensitive data
hash_sensitive <- function(data, columns) {
  tryCatch({
    for (col in columns) {
      if (col %in% names(data)) {
        data[[col]] <- sapply(data[[col]], function(x) {
          if (is.na(x) || x == "") return(NA_character_)
          openssl::sha256(as.character(x))
        })
      }
    }
    logger(sprintf("Combined Dashboard: Hashed sensitive columns: %s", paste(columns, collapse = ", "))) # nolint
    return(data)
  }, error = function(e) {
    logger(sprintf("Combined Dashboard: Error hashing sensitive data: %s", e$message), "api/logs/api_error.log") # nolint
    stop(e)
  })
}

# Logger function
logger <- function(message, file = "api/logs/api_access.log") {
  tryCatch({
    cat(sprintf("[%s] %s\n", Sys.time(), message), file = file, append = TRUE)
  }, error = function(e) {
    message(sprintf("Logger error: %s", e$message))
  })
}

# Load data
if (is.null(config$database$use_db)) {
  config$database$use_db <- FALSE
}
if (config$database$use_db) {
  if (!file.exists("data/database_connect.R")) {
    logger("Combined Dashboard: database_connect.R not found", "api/logs/api_error.log") # nolint
    stop("database_connect.R not found")
  }
  source("data/database_connect.R")
  con <- connect_db()
  data <- dbReadTable(con, "features_data")
  dbDisconnect(con)
} else {
  if (!file.exists(config$data$features)) {
    logger(sprintf("Combined Dashboard: Features data file not found: %s", config$data$features), "api/logs/api_error.log") # nolint
    stop("Features data file not found: ", config$data$features)
  }
  data <- readRDS(config$data$features)
}
# Load full dataset for export
full_data_path <- "C:/Project/Second/data/output/full_student_dataset.csv"
full_data <- tryCatch({
  read.csv(full_data_path, stringsAsFactors = FALSE)
}, error = function(e) {
  logger(sprintf("Combined Dashboard: Error loading full_student_dataset.csv: %s", e$message), "api/logs/api_error.log") # nolint
  data.frame(student_id = character(), phq_total = numeric(), gad_total = numeric(), mental_health_risk = character(), semester = integer(), gpa = numeric(), attendance_rate = numeric(), mental_health_score = numeric(), self_harm_thoughts = character(), contact_counselor = character()) # nolint
})
# Validate data structure
required_columns <- c("student_id", "phq_total", "gad_total", "mental_health_risk") # nolint
optional_columns <- c("semester", "gpa", "attendance_rate", "course_failures", "academic_probation", "mental_health_score", "outcome") # nolint
available_columns <- intersect(names(data), c(required_columns, optional_columns)) # nolint
missing_required <- setdiff(required_columns, names(data))
if (length(missing_required) > 0) {
  logger(sprintf("Combined Dashboard: Missing required columns: %s", paste(missing_required, collapse = ", ")), "api/logs/api_error.log") # nolint
  stop("Missing required columns in data: ", paste(missing_required, collapse = ", ")) # nolint
}

# Load model and test data for admin
if (!file.exists(config$model$path)) {
  logger(sprintf("Combined Dashboard: Model file not found: %s", config$model$path), "api/logs/api_error.log") # nolint
  stop("Model file not found: ", config$model$path)
}
if (!file.exists(config$model$test_data)) {
  logger(sprintf("Combined Dashboard: Test data file not found: %s", config$model$test_data), "api/logs/api_error.log") # nolint
  stop("Test data file not found: ", config$model$test_data)
}
model <- readRDS(config$model$path)
test_data <- readRDS(config$model$test_data)

# Prediction function
make_prediction <- function(new_data, config) {
  tryCatch({
    response <- POST(
      sprintf("http://%s:%s/predict", config$api$host, config$api$port),
      body = toJSON(new_data, auto_unbox = TRUE),
      content_type_json(),
      add_headers(Authorization = paste("Bearer", config$api$key))
    )
    content(response, "parsed")
  }, error = function(e) {
    logger(sprintf("Combined Dashboard: API prediction error: %s", e$message), "api/logs/api_error.log") # nolint
    list(error = e$message, status = 500)
  })
}

# Customize shinymanager login labels
set_labels(
  language = "en",
  "Please authenticate" = "Login to Mental Health Dashboard",
  "Username:" = "Username",
  "Password:" = "Password"
)

server <- function(input, output, session) { # nolint
  # Authentication with shinymanager
  auth <- secure_server(check_credentials = check_credentials(db_path)) # nolint
  # Get the authenticated user's role
  user_role <- reactive({
    user_info <- auth$user_info
    role <- if (!is.null(user_info) && "role" %in% names(user_info)) user_info$role else NULL # nolint
    # Fallback: Map username to role if role is NULL
    if (is.null(role)) {
      role <- switch(auth$user %||% "",
                     "counselor" = "Counselor",
                     "admin" = "Admin",
                     "educator" = "Educator",
                     NULL)
      message("Using fallback role mapping for username: ", auth$user %||% "NULL", ", assigned role: ", role %||% "NULL") # nolint
    }
    message("User logged in with username: ", auth$user %||% "NULL", ", role: ", role %||% "NULL") # nolint
    role
  })
  # Render debug message and redirect after 3 seconds
  output$debug_message <- renderUI({
    role <- user_role()
    if (is.null(role)) {
      tags$div(id = "debug_message", class = "debug-message",
               "No role detected. Ensure credentials.sqlite is initialized correctly. Check server logs and shinymanager version.") # nolint
    } else {
      tags$div(id = "debug_message", class = "debug-message",
               paste("Role detected:", role, "- Redirecting to dashboard..."))
    }
  })

  # Redirect to role-specific page after 3 seconds
  observe({
    role <- user_role()
    if (!is.null(role)) {
      delay(300, {  #  delay
        shinyjs::runjs("$('#debug_message').addClass('fade-out');")  # Fade out debug message # nolint
        delay(100, {  # Wait for fade-out to complete
          tab <- switch(role,
                        "Counselor" = "alerts",
                        "Educator" = "overview",
                        "Admin" = "system_overview",
                        "alerts")  # Default to alerts if role invalid
          message("Redirecting to tab: ", tab, " for role: ", role)
          updateTabItems(session, "tabs", selected = tab)
        })
      })
    }
  })
  # Dynamic sidebar based on role
  output$sidebar_menu <- renderUI({
    role <- user_role()
    message("Rendering sidebar for role: ", role %||% "NULL") # nolint
    tryCatch({
      if (is.null(role) || !role %in% c("Counselor", "Admin", "Educator")) {
        message("Invalid or missing role: ", role %||% "NULL")
        return(sidebarMenu(p("Invalid role. Please contact the administrator.", style = "color: red;"))) # nolint
      }

      if (role == "Counselor") {
        sidebarMenu(
          menuItem("High-Risk Alerts", tabName = "alerts", icon = icon("exclamation-triangle")), # nolint
          menuItem("Student Details", tabName = "details", icon = icon("user"))
        )
      } else if (role == "Educator") {
        sidebarMenu(
          menuItem("Risk Overview", tabName = "overview", icon = icon("dashboard")), # nolint
          menuItem("Student Prediction", tabName = "input", icon = icon("edit"))
        )
      } else if (role == "Admin") {
        sidebarMenu(
          menuItem("System Overview", tabName = "system_overview", icon = icon("dashboard")), # nolint
          menuItem("Performance Metrics", tabName = "metrics", icon = icon("chart-bar")), # nolint
          menuItem("Variable Importance", tabName = "var_importance", icon = icon("chart-line")) # nolint
        )
      }
    }, error = function(e) {
      message("Error rendering sidebar: ", e$message)
      sidebarMenu(p("Error rendering sidebar. Check server logs.", style = "color: red;")) # nolint
    })
  })
   # nolint
  # Counselor: High-risk students table
  output$alert_table <- DT::renderDataTable({
    req(user_role() == "Counselor")
    tryCatch({
      high_risk <- data %>%
        filter(mental_health_risk == "High") %>% # nolint
        select(all_of(intersect(c("student_id", "phq_total", "gad_total", "mental_health_risk", "semester", "gpa", "attendance_rate"), names(data)))) # nolint
      message("Rendering high-risk students table for Counselor with ", nrow(high_risk), " rows") # nolint
      DT::datatable(high_risk, options = list(pageLength = 10, lengthMenu = c(10, 25, 50, 100))) # nolint
    }, error = function(e) {
      logger(sprintf("Combined Dashboard: Error loading high-risk table: %s", e$message), "api/logs/api_error.log") # nolint
      DT::datatable(data.frame(Error = "Failed to load high-risk students"))
    })
  })
  # nolint
  # Counselor: Export high risk students
  output$download_high_risk <- downloadHandler(
    filename = function() {
      paste("high_risk_students_", Sys.Date(), ".csv", sep = "")
    },
    content = function(file) {
      tryCatch({
        high_risk <- full_data %>% # nolint
          filter(mental_health_risk == "High" | contact_counselor == "Yes") %>% # nolint
          select(student_id, phq_total, gad_total, mental_health_risk, semester, gpa, attendance_rate, mental_health_score = mental_health_battery) %>% # nolint
          write.csv(high_risk, file, row.names = FALSE) # nolint
        logger(sprintf("Combined Dashboard: High-risk students exported by Counselor (%d rows)", nrow(high_risk))) # nolint
      }, error = function(e) {
        logger(sprintf("Combined Dashboard: Error exporting high-risk students: %s", e$message), "api/logs/api_error.log") # nolint
        stop(e)
      })
      } # nolint
    )
  # Counselor: Student details
  observeEvent(input$fetch_btn, {
    req(user_role() == "Counselor")
    output$student_details <- renderTable({
      tryCatch({
        if (is.na(input$student_id) || input$student_id == "") {
          logger("Combined Dashboard: Invalid student ID entered for Counselor")
          return(data.frame(Message = "Please enter a valid Student ID")) # nolint
        }
        student_data <- data %>%
          filter(student_id == input$student_id) %>% # nolint
          select(all_of(intersect(c("student_id", "phq_total", "gad_total", "mental_health_risk", "semester", "gpa", "attendance_rate"), names(data)))) # nolint
        if (nrow(student_data) == 0) {
          logger(sprintf("Combined Dashboard: Student ID not found: %s", input$student_id), "api/logs/api_error.log") # nolint
          return(data.frame(Message = "Student ID not found"))
        }
        message("Fetched details for student ID: ", input$student_id)
        student_data
      }, error = function(e) {
        logger(sprintf("Combined Dashboard: Error fetching student details: %s", e$message), "api/logs/api_error.log") # nolint
        data.frame(Message = paste("Error fetching student details:", e$message)) # nolint
      })
    })
  })
   # nolint
  # Educator: Risk summary boxes
  output$high_risk_box <- renderValueBox({
    req(user_role() == "Educator")
    tryCatch({
      count <- sum(data$mental_health_risk == "High")
      message("Rendering high risk box: ", count)
      valueBox(count, "High Risk", color = "red")
    }, error = function(e) {
      logger(sprintf("Combined Dashboard: Error rendering high risk box: %s", e$message), "api/logs/api_error.log") # nolint
      valueBox("Error", "High Risk", color = "red")
    })
  })
   # nolint
  output$medium_risk_box <- renderValueBox({
    req(user_role() == "Educator")
    tryCatch({
      count <- sum(data$mental_health_risk == "Medium")
      message("Rendering medium risk box: ", count)
      valueBox(count, "Medium Risk", color = "yellow")
    }, error = function(e) {
      logger(sprintf("Combined Dashboard: Error rendering medium risk box: %s", e$message), "api/logs/api_error.log") # nolint
      valueBox("Error", "Medium Risk", color = "yellow")
    })
  })
   # nolint
  output$low_risk_box <- renderValueBox({
    req(user_role() == "Educator")
    tryCatch({
      count <- sum(data$mental_health_risk == "Low")
      message("Rendering low risk box: ", count)
      valueBox(count, "Low Risk", color = "green")
    }, error = function(e) {
      logger(sprintf("Combined Dashboard: Error rendering low risk box: %s", e$message), "api/logs/api_error.log") # nolint
      valueBox("Error", "Low Risk", color = "green")
    })
  })
   # nolint
  # Educator: Risk distribution plot
  output$risk_dist_plot <- renderPlot({
    req(user_role() == "Educator")
    tryCatch({
      message("Rendering risk distribution plot")
      ggplot(data, aes(x = mental_health_risk, fill = mental_health_risk)) + # nolint
        geom_bar() +
        labs(title = "Mental Health Risk Distribution", x = "Risk Level", y = "Count") + # nolint
        scale_fill_manual(values = c("High" = "red", "Medium" = "yellow", "Low" = "green")) + # nolint
        theme_minimal(base_size = 14) +
        theme(plot.title = element_text(hjust = 0.5, face = "bold"))
    }, error = function(e) {
      logger(sprintf("Combined Dashboard: Error rendering risk distribution plot: %s", e$message), "api/logs/api_error.log") # nolint
      plot.new()
      text(0.5, 0.5, "Error rendering plot", col = "red")
    })
  })
   # nolint
  # Educator: Prediction logic
  observeEvent(input$predict_btn, {
    req(user_role() == "Educator")
    output$prediction_result <- renderText({
      tryCatch({
        errors <- c()
        if (input$phq_total < 0 || input$phq_total > 27) errors <- c(errors, "PHQ-9 Total must be between 0 and 27") # nolint
        if (input$gad_total < 0 || input$gad_total > 21) errors <- c(errors, "GAD-7 Total must be between 0 and 21") # nolint
        if (input$self_harm_thoughts == "") errors <- c(errors, "Self-Harm Thoughts must be selected") # nolint
        if (input$mental_health_score < 0) errors <- c(errors, "Mental Health Score must be >= 0") # nolint
        if (input$outcome < 0) errors <- c(errors, "Outcome must be >= 0")
         # nolint
        if (length(errors) > 0) {
          logger(sprintf("Combined Dashboard: Input validation errors: %s", paste(errors, collapse = "; ")), "api/logs/api_error.log") # nolint
          return(paste("Errors:", paste(errors, collapse = "; ")))
        }
         # nolint
        new_data <- data.frame(
          phq_total = input$phq_total,
          gad_total = input$gad_total,
          self_harm_thoughts = input$self_harm_thoughts,
          mental_health_score = input$mental_health_score,
          outcome = input$outcome
        )
         # nolint
        result <- make_prediction(new_data, config)
        if (is.list(result) && !is.null(result$error)) {
          logger(sprintf("Combined Dashboard: Prediction error: %s", result$error), "api/logs/api_error.log") # nolint
          return(paste("Error:", result$error))
        } else {
          message("Prediction result: ", toJSON(result))
          paste("Predicted Risk:", result$prediction, "\nProbabilities:",
                paste(names(result$probabilities), round(unlist(result$probabilities), 3), sep = "=", collapse = ", ")) # nolint
        }
      }, error = function(e) {
        logger(sprintf("Combined Dashboard: Prediction error: %s", e$message), "api/logs/api_error.log") # nolint
        paste("Error:", e$message)
      })
    })
  })
  # Admin: Model Accuracy
  output$model_accuracy <- renderValueBox({
    req(user_role() == "Admin")
    tryCatch({
      predictions <- predict(model, test_data)
      accuracy <- mean(predictions == test_data$mental_health_risk)
      message("Calculated model accuracy: ", sprintf("%.2f%%", accuracy * 100))
      valueBox(sprintf("%.2f%%", accuracy * 100), "Model Accuracy",
               color = if (accuracy >= config$monitoring$accuracy_threshold) "green" else "red") # nolint
    }, error = function(e) {
      logger(sprintf("Combined Dashboard: Error calculating model accuracy: %s", e$message), "api/logs/api_error.log") # nolint
      valueBox("Error", "Model Accuracy", color = "red")
    })
  })
   # nolint
  # Admin: API Status
  output$api_status <- renderValueBox({
    req(user_role() == "Admin")
    tryCatch({
      response <- GET(sprintf("http://%s:%s/health", config$api$host, config$api$port)) # nolint
      status <- if (status_code(response) == 200) "Up" else "Down"
      message("API status checked: ", status)
      valueBox(status, "API Status", color = if (status == "Up") "green" else "red") # nolint
    }, error = function(e) {
      logger(sprintf("Combined Dashboard: Error checking API status: %s", e$message), "api/logs/api_error.log") # nolint
      valueBox("Down", "API Status", color = "red")
    })
  })
   # nolint
  # Admin: Data Quality
  output$data_quality <- renderValueBox({
    req(user_role() == "Admin")
    tryCatch({
      missing_rate <- mean(is.na(data)) * 100
      message("Calculated missing data rate: ", sprintf("%.2f%%", missing_rate))
      valueBox(sprintf("%.2f%%", missing_rate), "Missing Data Rate",
               color = if (missing_rate < 5) "green" else "yellow")
    }, error = function(e) {
      logger(sprintf("Combined Dashboard: Error calculating data quality: %s", e$message), "api/logs/api_error.log") # nolint
      valueBox("Error", "Missing Data Rate", color = "red")
    })
  })
   # nolint
  # Admin: Confusion Matrix
  output$conf_matrix <- renderTable({
    req(user_role() == "Admin")
    tryCatch({
      predictions <- predict(model, test_data)
      cm <- confusionMatrix(predictions, test_data$mental_health_risk)$table
      message("Generated confusion matrix")
      as.data.frame.matrix(cm)
    }, error = function(e) {
      logger(sprintf("Combined Dashboard: Error generating confusion matrix: %s", e$message), "api/logs/api_error.log") # nolint
      data.frame(Error = "Failed to generate confusion matrix")
    })
  })
  # Admin: Variable Importance Plot
     output$var_importance_plot <- renderPlotly({
       req(user_role() == "Admin")
       tryCatch({
         importance <- model$finalModel$variable.importance
         importance_df <- data.frame(
           Variable = names(importance),
           Importance = importance / max(importance) * 100
         ) %>%
           arrange(desc(Importance)) %>% # nolint
           head(10)
         logger(sprintf("Combined Dashboard: Rendering variable importance plot with %d variables", nrow(importance_df)))
         p <- plot_ly(
           data = importance_df,
           x = ~Importance,
           y = ~reorder(Variable, Importance),
           type = "bar",
           marker = list(color = "#007bff"),
           hoverinfo = "text",
           text = ~paste("Variable:", Variable, "<br>Importance:", round(Importance, 3))
         ) %>%
           layout(
             title = "Top Predictors of Mental Health Risk",
             xaxis = list(title = "Importance Score"),
             yaxis = list(title = ""),
             showlegend = FALSE,
             margin = list(l = 150),
             font = list(family = "Arial", size = 12)
           )
         p
       }, error = function(e) {
         logger(sprintf("Combined Dashboard: Error rendering variable importance plot: %s", e$message), "api/logs/api_error.log")
         plot_ly() %>% add_text(x = 0.5, y = 0.5, text = "Error rendering plot", textposition = "middle center")
    })
  })
}