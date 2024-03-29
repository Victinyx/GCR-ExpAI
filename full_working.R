source("scripts/load_packages.R")

GCR <- read.csv('./data/german_credit_data.csv',
                header = TRUE)
GCR <- GCR %>% select(-X, -Age)


set.seed(123)
GCR_split <- initial_split(GCR, strata = Risk)
GCR_train <- training(GCR_split)
GCR_test <- testing(GCR_split)

GCR_recipe <- recipe(Risk ~ ., data = GCR_train) %>%
  step_mutate(Amount.month = Credit.amount / Duration) %>%
  step_string2factor(all_nominal(), -all_outcomes()) %>%
  step_impute_knn(Saving.accounts,  Checking.account) %>%
  step_other(Purpose, threshold = 0.10, other = 'other_value')# is dit wel nodig? van 8 naar 4

rf_model <-
  rand_forest(mtry = 5, trees = 500, min_n = 8) %>%
  set_engine("randomForest") %>%
  set_mode("classification")

rf_workflow <-
  workflow() %>%
  add_recipe(GCR_recipe) %>%
  add_model(rf_model)

model_fitted <- rf_workflow %>%
  fit(data = GCR_train)

model_fitted %>%
  predict(new_data = GCR_test)


source("scripts/explainability/DALEX_functions.R")
make_vars(model_fitted, GCR_train, 'Risk', label = 'RandomForest')
source("scripts/explainability/DALEX_script.R")
