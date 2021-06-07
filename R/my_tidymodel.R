
# Soybean Database
# Description: Predict problems with soybean crops from crop data.
# Type: Multi-Class Classification
# Dimensions: 683 instances, 26 attributes
# Inputs: Integer (Nominal)
# Output: Categorical, 19 class labels
# UCI Machine Learning Repository: Description

# Soybean Database
library(mlbench)
data(Sonar)

# EDA e ML
library(tidymodels)
library(skimr)

# overview
skim(Sonar)

# 1. split
sonar_split <- initial_split(Sonar)

# 2. simple fit

# glm
glm_fit <- parsnip::logistic_reg(mode="classification") %>% 
  set_engine("glmnet", family="binomial") %>% 
  fit(Class ~. , data=training(sonar_split))

# eval
predict(glm_fit, new_data = testing(sonar_split), penalty = 0) %>% 
  bind_cols(select(testing(sonar_split),Class)) %>%
  metrics(truth=Class, estimate=.pred_class) 
  conf_mat(Class, .pred_class)

# 3. Tunning
  
  
# tunnig the penalty
glm_fit_tune <- logistic_reg(mode = "classification", penalty=tune()) %>% 
  set_engine("glmnet", family="binomial")

# range to test
glm_grid <- grid_regular(penalty(), levels = 10)

# CV
sonar_cv <- vfold_cv(training(sonar_split))

# workflow with model (tunnable) and formula
sonar_wf <- workflow() %>% 
  add_model(glm_fit_tune) %>% 
  add_formula(Class ~ . )

# fit CV with Tune Grid
sonar_res <- sonar_wf %>% 
  tune_grid(resamples=sonar_cv, grid=glm_grid)

# check the performances
sonar_res %>% 
  collect_metrics()

# show top 5 
sonar_res %>% 
  show_best()

# melhor modelo
sonar_wf <- sonar_wf %>% 
  # modify workflow to fit with the best parameters
  finalize_workflow(select_best(sonar_res, "roc_auc"))
  
sonar_final_fit <- sonar_wf %>% 
  # fit the training set
  fit(data=training(sonar_split))

# 
predict(sonar_final_fit, new_data = testing(sonar_split)) %>% 
  bind_cols(select(testing(sonar_split), Class)) %>% 
  metrics(Class, .pred_class)
 
########### rand forest

rf_mod <- rand_forest( 
    mode = "classification", 
    trees = tune(), 
    min_n = tune()
  ) %>% 
  set_engine("ranger")

rf_grid <- grid_regular(
  trees(),
  min_n(),
  levels=5)

rf_wf <- workflow() %>% 
  add_model(rf_mod) %>% 
  add_formula(Class ~ .)

rf_res <- rf_wf %>% 
  tune_grid(resamples=sonar_cv, grid=rf_grid)

rf_res %>% 
  collect_metrics()

rf_wf_best <- rf_wf %>% 
  finalize_workflow(select_best(rf_res, "roc_auc"))

rf_best_fit <- rf_wf_best %>% 
  fit(training(sonar_split))

predict(rf_best_fit, new_data = testing(sonar_split)) %>% 
  bind_cols(select(testing(sonar_split), Class)) %>% 
  metrics(truth=Class, estimate=.pred_class)

##### XGB with Normalizatino

# 1. split
# 2. feature eng
# 3. tunning
# 4. final fit
# 5. eval

# 1. split

sonar_split <- initial_split(Sonar)
sonar_trn <- training(sonar_split)
sonar_tst <- testing(sonar_split)

# 2. feat eng
skim(sonar_trn)

sonar_recip <- recipe(sonar_trn, Class ~ .) %>%
  step_nzv(all_predictors()) %>% 
  step_center(all_predictors()) %>% 
  step_scale(all_predictors()) %>% 
  prep()

# 3 tuning

# 3.1 model tunable
xgb_tune_eng <- boost_tree(
    mode = "classification", 
    trees = tune(),
    min_n = tune(),
    tree_depth = tune(),
    learn_rate = tune(),
    loss_reduction = tune()
  ) %>% 
  set_engine("xgboost")

# 3.2 tune grid
xgb_grid <- grid_max_entropy(
  trees(), min_n(), tree_depth(), learn_rate(), loss_reduction(),
  size=60
)

# 3.3 CV
sonar_cv <- sonar_recip %>% 
  juice() %>% 
  vfold_cv(v=5)


# speed up computation with parrallel processing (optional)
library(doParallel)
all_cores <- parallel::detectCores(logical = FALSE)
registerDoParallel(cores = all_cores)

# 3.4 tunning
xgb_tune_wf <- workflow() %>% 
  add_model(xgb_tune_eng) %>% 
  add_formula(Class ~ .)

xgb_tune_res <- xgb_tune_wf %>% 
  tune_grid(resamples=sonar_cv, grid=xgb_grid)

xgb_tune_res %>% 
  collect_metrics()

xgb_tune_res %>% 
  show_best(metric = "roc_auc")

# 4 fit the best
xgb_wf <- xgb_tune_wf %>% 
  finalize_workflow(select_best(xgb_tune_res,"roc_auc")) 

# 4.1 final fit
xgb_fit <- xgb_wf %>% 
  fit(juice(sonar_recip))
  
# 5 predict
xgb_pred <- predict(xgb_fit, bake(sonar_recip, sonar_tst)) %>% 
  bind_cols(select(sonar_tst, Class))

xgb_pred %>% 
  conf_mat(truth=Class, estimate=.pred_class)

xgb_pred %>% 
  metrics(truth=Class, estimate=.pred_class)


predict(xgb_fit, bake(sonar_recip, sonar_tst), type="prob") %>% 
  bind_cols(select(sonar_tst, Class)) %>% 
  roc_auc(truth=Class, .pred_M )
  
predict(xgb_fit, bake(sonar_recip, sonar_tst), type="prob") %>% 
  bind_cols(select(sonar_tst, Class)) %>% 
  roc_curve(truth=Class, .pred_M ) %>% 
  autoplot()
