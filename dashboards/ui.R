library(shiny)
library(shinydashboard)
library(shinymanager)
library(DT) # nolint
library(shinyjs)  # Added for JavaScript functionality
library(plotly)
# Define the UI with a custom theme
ui <- secure_app(
  dashboardPage( # nolint
    skin = "blue", # nolint
    dashboardHeader(
      title = tags$div(
        # tags$img(src = "logo.png", height = 30, style = "margin-right: 10px;"), # nolint
        "Mental Health Prediction Dashboard"
      ),
      titleWidth = 300
    ),
    dashboardSidebar(
      sidebarMenu(id = "tabs", uiOutput("sidebar_menu"))
    ),
    dashboardBody(
      useShinyjs(),  # Initialize shinyjs  # nolint
      tags$head(
        tags$style(HTML("
          /* Existing Dashboard Styles */
          .content-wrapper, .right-side {
            background-color: #f4f6f9;
          }
          .box {
            border-radius: 8px;
            box-shadow: 0 2px 4px rgba(0,0,0,0.1);
            background-color: #ffffff;
          }
          .main-header .logo {
            font-family: 'Arial', sans-serif;
            font-weight: bold;
            font-size: 18px;
            color: #ffffff;
          }
          .sidebar-menu li a {
            font-family: 'Arial', sans-serif;
            font-size: 16px;
            color: #333333;
          }
          .sidebar-menu li.active a {
            background-color: #007bff;
            color: #ffffff;
          }
          .shiny-plot-output, .shiny-table-output {
            margin: 20px 0;
          }
          .btn {
            border-radius: 4px;
            font-family: 'Arial', sans-serif;
          }
          .debug-message {
            font-size: 16px;
            color: #d9534f;
            margin: 20px;
            transition: opacity 0.5s ease-out; /* Fade-out effect */
          }
          .debug-message.fade-out {
            opacity: 0;
          }
          .shinymanager-login, .shinymanager-logout {
            font-family: 'Arial', sans-serif !important;
          }
          /* Login Page Styles */
          .shinymanager-login {
            background-color: #e9ecef;
            display: flex;
            justify-content: center;
            align-items: center;
            height: 100vh;
            margin: 0;
          }
          .panel-default {
            background-color: #ffffff;
            border-radius: 10px;
            box-shadow: 0 4px 8px rgba(0,0,0,0.2);
            padding: 20px;
            width: 350px;
            text-align: center;
          }
          .panel-default > .panel-heading {
            background-color: #007bff;
            color: #ffffff;
            font-size: 20px;
            font-weight: bold;
            border-radius: 8px 8px 0 0;
            padding: 15px;
          }
          .shinymanager-login .form-group {
            margin-bottom: 15px;
          }
          .shinymanager-login .form-control {
            border-radius: 5px;
            border: 1px solid #ced4da;
            padding: 10px;
            font-size: 16px;
          }
          .shinymanager-login .btn-primary {
            background-color: #007bff;
            border-color: #007bff;
            border-radius: 5px;
            padding: 10px 20px;
            font-size: 16px;
            transition: background-color 0.3s;
          }
          .shinymanager-login .btn-primary:hover {
            background-color: #0056b3;
            border-color: #0056b3;
          }
          .shinymanager-login label {
            font-size: 14px;
            color: #333333;
            font-weight: bold;
          }
          /* Download Button Styling */
          .download-btn {
            margin: 10px 0;
            background-color: #28a745;
            border-color: #28a745;
            color: #ffffff;
          }
          .download-btn:hover {
            background-color: #218838;
            border-color: #1e7e34;
          }
        "))
      ),
      uiOutput("debug_message"),
      tabItems(
        tabItem(tabName = "alerts",
                fluidRow(
                  box(
                    title = "High-Risk Students",
                    DT::dataTableOutput("alert_table"),
                    downloadButton("download_high_risk", "Download High-Risk List", class = "download-btn"), # nolint
                    width = 12, status = "primary", solidHeader = TRUE
                  )
                )),
        tabItem(tabName = "details",
                fluidRow(
                  box(
                    textInput("student_id", "Student ID", value = ""), # nolint
                    actionButton("fetch_btn", "Fetch Details"),
                    tableOutput("student_details"),
                    width = 12, status = "primary", solidHeader = TRUE
                  )
                )),
        tabItem(tabName = "overview",
                fluidRow(
                  valueBoxOutput("high_risk_box", width = 4),
                  valueBoxOutput("medium_risk_box", width = 4),
                  valueBoxOutput("low_risk_box", width = 4)
                ),
                fluidRow(
                  box(title = "Risk Distribution", plotOutput("risk_dist_plot"),  # nolint
                      width = 12, status = "primary", solidHeader = TRUE)
                )),
        tabItem(tabName = "input",
                fluidRow(
                  box(
                    numericInput("phq_total", "PHQ-9 Total", value = 10, min = 0, max = 27), # nolint
                    numericInput("gad_total", "GAD-7 Total", value = 8, min = 0, max = 21), # nolint
                    selectInput("self_harm_thoughts", "Self-Harm Thoughts", choices = c("Yes", "No")), # nolint
                    numericInput("mental_health_score", "Mental Health Score", value = 10, min = 0, max = 100), # nolint
                    numericInput("outcome", "Outcome", value = 10, min = 0, max = 100), # nolint
                    actionButton("predict_btn", "Predict"),
                    width = 6, status = "primary", solidHeader = TRUE
                  ),
                  box(title = "Prediction", verbatimTextOutput("prediction_result"),  # nolint
                      width = 6, status = "primary", solidHeader = TRUE)
                )),
        tabItem(tabName = "system_overview",
                fluidRow(
                  valueBoxOutput("model_accuracy", width = 4),
                  valueBoxOutput("api_status", width = 4),
                  valueBoxOutput("data_quality", width = 4)
                )),
        tabItem(tabName = "metrics",
                fluidRow(
                  box(title = "Confusion Matrix", tableOutput("conf_matrix"),
                      width = 12, status = "primary", solidHeader = TRUE)
                )),
        tabItem(tabName = "var_importance", # nolint
                fluidRow( # nolint
                  box(title = "Variable Importance", plotlyOutput("var_importance_plot"),
                      width = 12, status = "primary", solidHeader = TRUE)
                )) # nolint
      )
    )
  ),
  language_input = FALSE
)