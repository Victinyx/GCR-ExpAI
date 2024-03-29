
xgboost_model <- 
  boost_tree(
    mtry = tune(),
    trees = 500,
    min_n = tune(),
  ) %>%
  set_engine("xgboost") %>%
  set_mode('classification')


xg_workflow <-
  workflow() %>%
  add_recipe(GCR_recipe) %>%
  add_model(xgboost_model)


ctrl <- control_resamples(save_pred = TRUE)
folds <- vfold_cv(GCR_train, v = 5)
grid <-  expand.grid(mtry = 5:16 , min_n = 1:8)



doParallel::registerDoParallel()

tuned_xg <- 
  xg_workflow %>%
  tune_grid(resamples = folds, grid = grid)
  
  
tuned_xg %>% collect_metrics()


xgboost_best_params <- tuned_xg %>%
  tune::select_best("accuracy")


final_xg <- xgboost_model %>% 
  finalize_model(xgboost_best_params)

final_xg_wf <- 
  workflow() %>%
  add_recipe(GCR_recipe) %>%
  add_model(final_xg)

final_xg_fitted <- final_xg_wf %>%
  fit(data = GCR_train)


final_xg_fitted %>%
  predict(new_data = GCR_test)



# mtry 6 , min n 4