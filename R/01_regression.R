getwd()

file.exists(
  "data/processed/student_employment_panel.csv"
)

install.packages(c(
  "tidyverse",
  "fixest",
  "modelsummary"
))

install.packages("dplyr")
library(dplyr)

library(tidyverse)
library(fixest)
library(modelsummary)

panel <- readr::read_csv(
  "data/processed/student_employment_panel.csv",
  show_col_types = FALSE
)

glimpse(panel)

list.files()
list.files("data/processed")

model_df <- panel %>%
  filter(
    visa_group %in% c(
      "Temporary Student",
      "Temporary Graduate"
    ),
    applicant_status == "Total",
    sex == "Persons",
    state != "Australia",
    industry != "Total",
    !is.na(jobs)
  ) %>%
  mutate(
    year = factor(
      year,
      levels = c(
        "2018-19",
        "2019-20",
        "2020-21",
        "2021-22",
        "2022-23"
      )
    ),
    visa_group = factor(
      visa_group,
      levels = c(
        "Temporary Graduate",
        "Temporary Student"
      )
    ),
    jobs = as.numeric(jobs)
  )

dim(model_df)

model_df %>%
  count(year, visa_group)

model_df %>%
  select(
    state,
    industry,
    visa_group,
    year,
    jobs
  ) %>%
  head(10)

duplicates <- model_df %>%
  count(
    state,
    industry,
    visa_group,
    year
  ) %>%
  filter(n > 1)

duplicates

model_df %>%
  group_by(year, visa_group) %>%
  summarise(
    observations = n(),
    mean_jobs = mean(jobs),
    median_jobs = median(jobs),
    min_jobs = min(jobs),
    max_jobs = max(jobs),
    .groups = "drop"
  )

install.packages("fixest")
library(fixest)

m_ols <- feols(
  log1p(jobs) ~ year * visa_group |
    state^industry,
  vcov = ~ state^industry,
  data = model_df
)

summary(m_ols)
names(coef(m_ols))
100 * (exp(0.20) - 1)
coef(m_ols)

m_ppml <- fepois(
  jobs ~ year * visa_group |
    state^industry,
  vcov = ~ state^industry,
  data = model_df
)

etable(
  m_ols,
  m_ppml,
  headers = c(
    "Log OLS",
    "PPML"
  )
)

install.packages("modelsummary")
library(modelsummary)

modelsummary::modelsummary(
  list(
    "Log OLS" = m_ols,
    "PPML" = m_ppml
  ),
  output = "outputs/tables/regression_results.html",
  stars = TRUE
)

fixest::coeftable(m_ols)

coef(m_ols)[
  grepl(
    "year.*visa_group|visa_group.*year",
    names(coef(m_ols))
  )
]

fixest::etable(
  m_ols,
  m_ppml,
  headers = c("Log OLS", "PPML"),
  keep = "year|visa_group",
  digits = 3
)

png(
  "outputs/figures/ols_coefficient_plot.png",
  width = 1800,
  height = 1200,
  res = 200
)

fixest::coefplot(
  m_ols,
  keep = "year.*visa_group",
  main = "Differential Change in Jobs: Student vs Graduate Visa",
  xlab = "Log coefficient with 95% confidence interval"
)

abline(v = 0, lty = 2, col = "grey")

dev.off()

install.packages("ggplot2")
library(ggplot2)

diagnostics <- tibble(
  fitted_value = fitted(m_ols),
  residual = resid(m_ols)
)

diagnostic_plot <- ggplot(
  diagnostics,
  aes(x = fitted_value, y = residual)
) +
  geom_point(alpha = 0.35) +
  geom_hline(
    yintercept = 0,
    linetype = "dashed",
    colour = "red"
  ) +
  theme_minimal() +
  labs(
    title = "Residuals versus Fitted Values",
    x = "Fitted value",
    y = "Residual"
  )

diagnostic_plot

ggsave(
  "outputs/figures/ols_residual_diagnostics.png",
  diagnostic_plot,
  width = 8,
  height = 5,
  dpi = 300
)

file.exists(
  "outputs/figures/ols_residual_diagnostics.png"
)



ct <- fixest::coeftable(m_ols)

term_names <- rownames(ct)


interaction_index <-
  grepl("year", term_names) &
  grepl("Temporary Student", term_names)


print(sum(interaction_index))


interaction_results <- data.frame(
  term = term_names[interaction_index],
  estimate = as.numeric(
    ct[interaction_index, 1]
  ),
  std_error = as.numeric(
    ct[interaction_index, 2]
  ),
  statistic = as.numeric(
    ct[interaction_index, 3]
  ),
  p_value = as.numeric(
    ct[interaction_index, 4]
  ),
  row.names = NULL
)


interaction_results$year <- sub(
  ".*(20[0-9]{2}-[0-9]{2}).*",
  "\\1",
  interaction_results$term
)


interaction_results$percent_change <-
  100 * (
    exp(interaction_results$estimate) - 1
  )


interaction_results$ci_lower <-
  100 * (
    exp(
      interaction_results$estimate -
        1.96 * interaction_results$std_error
    ) - 1
  )

interaction_results$ci_upper <-
  100 * (
    exp(
      interaction_results$estimate +
        1.96 * interaction_results$std_error
    ) - 1
  )


interaction_results$significance <- ifelse(
  interaction_results$p_value < 0.001,
  "***",
  ifelse(
    interaction_results$p_value < 0.01,
    "**",
    ifelse(
      interaction_results$p_value < 0.05,
      "*",
      "Not significant"
    )
  )
)


year_order <- c(
  "2019-20",
  "2020-21",
  "2021-22",
  "2022-23"
)

interaction_results <- interaction_results[
  match(
    year_order,
    interaction_results$year
  ),
  c(
    "year",
    "estimate",
    "std_error",
    "p_value",
    "percent_change",
    "ci_lower",
    "ci_upper",
    "significance"
  )
]


print(
  interaction_results,
  digits = 3,
  row.names = FALSE
)

readr::write_csv(
  interaction_results,
  "outputs/tables/interaction_results.csv"
)

file.exists(
  "outputs/tables/interaction_results.csv"
)
