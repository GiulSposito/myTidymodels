library(tidyverse)
library(tidymodels)
library(mlbench)
library(skimr)

data("BostonHousing")

BostonHousing %>% 
  skim()

boston_split <- initial_split(BostonHousing)


recp <- BostonHousing %>% 
  recipe(medv~.) %>% 
  step_nzv(all_predictors(), -all_nominal()) %>% 
  step_center(all_predictors(),-all_nominal()) %>% 
  step_scale(all_predictors(),-all_nominal()) %>% 
  step_BoxCox(all_predictors(), -all_nominal())


# model_eng <- linear_reg(mode="regression") %>% 
#   set_engine("lm")

model_eng <- rand_forest(mode="regression") %>% 
  set_engine("ranger")


wf <- workflow() %>% 
  add_recipe(recp) %>% 
  add_model(model_eng)

model_fit <- fit(wf, training(boston_split))

predict(model_fit, testing(boston_split)) %>% 
  bind_cols(testing(boston_split)) %>% 
  select(.pred, medv) %>% 
  metrics(truth=medv, estimate=.pred)
