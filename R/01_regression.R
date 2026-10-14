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


getwd()
list.files()
list.files("data/processed")

panel <- read_csv(
  "data/processed/student_employment_panel.csv",
  show_col_types = FALSE
)

glimpse(panel)


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



coefficient_table <- as.data.frame(
  fixest::coeftable(m_ols)
)

coefficient_table$term <- rownames(
  coefficient_table
)

interaction_results <- coefficient_table[
  grepl(":", coefficient_table$term),
]

interaction_results$percent_change <- 
  100 * (exp(interaction_results$Estimate) - 1)

interaction_results
100 * (exp(-0.439) - 1)
100 * (exp(-0.387) - 1)
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

abline(v = 0, lty = 2, col = "grey40")

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

ggplot2::ggsave(
  "outputs/figures/ols_residual_diagnostics.png",
  plot = diagnostic_plot,
  width = 8,
  height = 5,
  dpi = 300
)

file.exists(
  "outputs/figures/ols_residual_diagnostics.png"
)
nrow(interaction_results)
rownames(
  fixest::coeftable(m_ols)
)
# 获取原始回归系数表
ct <- fixest::coeftable(m_ols)

# 获取真实系数名称
term_names <- rownames(ct)

# 同时包含year和Temporary Student的行就是交互项
interaction_index <-
  grepl("year", term_names) &
  grepl("Temporary Student", term_names)

# 检查匹配到了几行
print(sum(interaction_index))

# 建立新的交互项结果表
interaction_results <- data.frame(
  term = term_names[interaction_index],
  estimate = ct[interaction_index, 1],
  std_error = ct[interaction_index, 2],
  statistic = ct[interaction_index, 3],
  p_value = ct[interaction_index, 4],
  row.names = NULL
)

# 对数系数转换为近似百分比
interaction_results$percent_change <-
  100 * (
    exp(interaction_results$estimate) - 1
  )

interaction_results
print(sum(interaction_index))
nrow(interaction_results)
readr::write_csv(
  interaction_results,
  "outputs/tables/interaction_results.csv"
)


# 1. 提取OLS回归系数表
ct <- fixest::coeftable(m_ols)

term_names <- rownames(ct)

# 2. 找出年份 × Temporary Student交互项
interaction_index <-
  grepl("year", term_names) &
  grepl("Temporary Student", term_names)

# 应该等于4
print(sum(interaction_index))

# 3. 整理成数据框
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

# 4. 从系数名称提取年份
interaction_results$year <- sub(
  ".*(20[0-9]{2}-[0-9]{2}).*",
  "\\1",
  interaction_results$term
)

# 5. 将对数系数换算为百分比
interaction_results$percent_change <-
  100 * (
    exp(interaction_results$estimate) - 1
  )

# 6. 计算95%置信区间
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

# 7. 添加显著性标记
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

# 8. 按年份排列并保留关键列
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

# 9. 显示最终4行表格
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
print(
  interaction_results,
  digits = 3,
  row.names = FALSE
)
