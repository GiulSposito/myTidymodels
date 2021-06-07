library(tidymodels)

##### REGRESSION

# 1. training and testing datasets

# rsample | "prop" for training
cars_split <- initial_split(mtcars, prop = .75)

# <training/test/total)
cars_split

# getting testset
cars_split %>% 
  training()

# 2. transformation steps
# recipe
cars_recipe <- cars_split %>% 
  training() %>%  # dataset template
  recipe(mpg ~ .) %>%  # formula
  step_corr(all_predictors()) %>% 
  step_center(all_predictors()) %>% 
  step_scale(all_predictors()) %>% 
  prep() # calculates the parameters using training data

cars_recipe

# 3. pre-processing
# testing dataset <- apply the recipe (bake) to the test data (testing(split))
cars_testing <- bake(cars_recipe, testing(cars_split))
cars_testing

# the training data is already transformed in the prepared recipe
cars_training <- juice(cars_recipe) 
cars_training

# 4. training a model (parsnip)
cars_lm <- parsnip::linear_reg() %>% # interface to linear model
  set_engine("lm") %>%               # using traditional R's lm
  fit(mpg ~ ., data=cars_training)

# parsnip model
cars_lm

# real model inside (lm)
summary(cars_lm$fit)

# 6. prediction
predict(cars_lm, cars_testing)

# 7. evalution
cars_testing %>% 
  bind_cols(predict(cars_lm, cars_testing)) %>% 
  metrics(truth=mpg, estimate=.pred) #yardstick

# Bonus: testing another model
cars_rf <- rand_forest(trees = 100, mode="regression") %>% 
  set_engine("ranger") %>% 
  fit(mpg ~ ., data=cars_training)

cars_rf

# check if fits better
cars_testing %>% 
  bind_cols(predict(cars_rf, cars_testing)) %>% 
  metrics(truth=mpg, estimate = .pred)


##### Classification
# remotes::install_github("allisonhorst/palmerpenguins")
library(palmerpenguins)
penguins
skimr::skim(penguins)


# 1. train/test sets
penguins_split <- rsample::initial_split(penguins)
penguins_split

# 2. transform/recipe
penguins_rec <- penguins_split %>% 
  training() %>% 
  recipe(species ~ ., data=.) %>% 
  step_knnimpute(sex) %>% 
  step_knnimpute(all_numeric()) %>% 
  step_normalize(all_numeric()) %>% 
  step_mutate(year = factor(year, ordered=T)) %>% 
  step_dummy(c(island, sex)) %>% 
  prep()

# 3. prep testset
penguins_test <- bake(penguins_rec, testing(penguins_split))
penguins_train <- juice(penguins_rec)

# 4. fit the model
penguins_model <- rand_forest(trees = 100, mode="classification") %>% 
  set_engine("ranger") %>% 
  fit(species ~ ., data=penguins_train)

penguins_model

# 5. predict
predict(penguins_model, penguins_test)

# 6. eval
penguins_pred <- predict(penguins_model, penguins_test) %>% 
  bind_cols(predict(penguins_model, penguins_test, type = "prob")) %>% 
  bind_cols(penguins_test) %>% 
  relocate(species, everything())

penguins_pred %>% 
  metrics(truth=species, estimate=.pred_class)


# checking AUC metrics
penguins_pred %>% 
  roc_auc(species, .pred_Adelie:.pred_Gentoo)

penguins_pred %>% 
  roc_curve(species, .pred_Adelie:.pred_Gentoo) %>% 
  autoplot()

# checking gain
penguins_pred %>% 
  gain_curve(species, .pred_Adelie:.pred_Gentoo) %>% 
  autoplot()

##### WORKFLOW
skimr::skim(iris)

# 1. train/test
iris_split <- initial_split(iris)

# 2. transform
iris_rec <- iris_split %>% 
  training() %>% 
  recipe(Species ~ ., data=.) %>% 
  step_normalize(all_predictors())
  
# 3. model
iris_mod <- logistic_reg(mode = "classification") %>% 
  set_engine("glm")

iris_mod <- rand_forest(mode = "classification") %>% 
  set_engine("ranger")

# 4. workflow
iris_wf <- workflow() %>% 
  add_recipe(iris_rec) %>% 
  add_model(iris_mod)

# fit the model
iris_fit <- iris_wf %>% 
  fit(data=training(iris_split))

predict(iris_fit,new_data = testing(iris_split), type="prob") %>% 
  bind_cols(predict(iris_fit,new_data = testing(iris_split))) %>% 
  bind_cols(testing(iris_split)) %>% 
  metrics(truth=Species, estimate=.pred_class)

##### Cross Validation

library(modeldata)

# dataset

data(cells, package="modeldata")
cells

cells %>% 
  count(class) %>% 
  mutate( prop = n/sum(n))

# training/test

cell_split <- initial_split(select(cells,-case), strata = class)

# prepare
skimr::skim(cells)

cell_recipe <-  cell_split %>%
  training() %>% 
  recipe(class ~ .) %>% 
  step_center( all_predictors() ) %>% 
  step_scale( all_predictors() ) %>% 
  prep()

# datasets 

cell_train <- juice(cell_recipe)
cell_test  <- bake(cell_recipe, testing(cell_split))

# model

rf_mod <- rand_forest(trees = 100) %>% 
  set_engine("ranger") %>% 
  set_mode("classification")

rf_fit <- fit(rf_mod, class~., cell_train)

predict(rf_fit, cell_test) %>% 
  bind_cols(cell_test) %>% 
  metrics(truth=class, estimate=.pred_class)

predictions <- predict(rf_fit, cell_test) %>% 
  bind_cols(predict(rf_fit, cell_test, type="prob")) %>% 
  bind_cols(cell_test) %>% 
  select(class, starts_with(".pred"))

metrics(predictions, truth = class, estimate = .pred_class)
roc_auc(predictions, truth = class, .pred_PS)

# CV

folds <- vfold_cv(cell_train, v=10)

folds

# wf

rf_wf <- workflow() %>% 
  add_model(rf_mod) %>% 
  add_formula(class ~ . )

rf_fit <- rf_wf %>% 
  fit_resamples(folds)

rf_fit %>% 
  collect_metrics()
