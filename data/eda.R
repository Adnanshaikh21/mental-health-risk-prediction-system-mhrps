library(dplyr)
library(ggplot2)
library(corrplot)

setwd("C:/Project/Second")
config <- config::get(file = "config/config.yaml")
data <- readRDS(config$data$features)

cat("Summary Statistics:\n")
print(summary(data))

numerical_cols <- names(data)[sapply(data, is.numeric) & names(data) != "student_id"] # nolint
if (length(numerical_cols) > 1) {
  corr_matrix <- cor(data[, numerical_cols], use = "complete.obs")
  png("data/output/correlation_matrix.jpeg", width = 800, height = 800)
  corrplot(corr_matrix, method = "color", addCoef.col = "black", tl.cex = 0.8)
  dev.off()
}

if ("mental_health_score" %in% names(data)) {
  ggplot(data, aes(x = mental_health_score)) +
    geom_histogram(binwidth = 0.5, fill = "blue", color = "black") +
    labs(title = "Mental Health Score Distribution", x = "Mental Health Score", y = "Count") + # nolint
    theme_minimal()
  ggsave("data/output/mental_health_score_distribution.jpeg")
}

if ("phq_total" %in% names(data)) {
  ggplot(data, aes(x = mental_health_risk, y = phq_total)) +
    geom_boxplot(fill = "lightgreen") +
    labs(title = "PHQ-9 Total Score by Mental Health Risk", x = "Risk Level", y = "PHQ-9 Score") + # nolint
    theme_minimal()
  ggsave("data/output/phq_total_by_risk.jpeg")
}

ggplot(data, aes(x = mental_health_risk, fill = mental_health_risk)) +
  geom_bar() +
  labs(title = "Mental Health Risk Distribution", x = "Risk Level", y = "Count") + # nolint
  scale_fill_manual(values = c("High" = "red", "Medium" = "yellow", "Low" = "green")) + # nolint
  theme_minimal()
ggsave("data/output/risk_distribution.jpeg")

cat("EDA completed. Visualizations saved in data/ directory.\n")
print("Done with EDA.")