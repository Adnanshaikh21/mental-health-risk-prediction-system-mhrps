FROM rocker/shiny:4.5.1
RUN R -e "install.packages(c('shiny', 'shinydashboard', 'shinymanager', 'RSQLite', 'dplyr', 'ggplot2', 'DT', 'httr', 'jsonlite', 'caret', 'config', 'shinyjs', 'sendmailR', 'knitr', 'jose'))"
COPY dashboards /srv/shiny-server/
COPY config /srv/shiny-server/config/
COPY data /srv/shiny-server/data/
COPY model /srv/shiny-server/model/
COPY api /srv/shiny-server/api/
COPY interventions /srv/shiny-server/interventions/
COPY automation /srv/shiny-server/automation/
COPY security /srv/shiny-server/security/
EXPOSE 3838
CMD ["R", "-e", "shiny::runApp('/srv/shiny-server', port=3838, host='0.0.0.0')"]