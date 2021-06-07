library(tidymodel)
library(modeldata)
library(vip)

data(cells, package="modeldata")
cells <- select(cells, -case)

# split dataset
cell_split <- initial_split(cells, strata = class)

cell_trn <- training(cell_split)
cell_tst <- testing(cell_split)

# tunning parameters

tune_spec <- decision_tree(
    cost_complexity = tune(), #placeholder to tune
    tree_depth = tune()  #placeholder to tune
  ) %>% 
  set_engine("rpart") %>% 
  set_mode("classification")

# tunning grid
tree_grid <- grid_regular(
  cost_complexity(),
  tree_depth(),
  levels = 5 # select 5 of each (5 x 5 = 25 cases)
)

# 10 CV
cell_folds <- vfold_cv(cell_trn)

# WF to CV with tunnable parameters
tree_wf <- workflow() %>% 
  add_model(tune_spec) %>% 
  add_formula(class ~ .) 

# Run the CV_WF with the tune grid parameters
tree_res <- tree_wf %>% 
  tune_grid(resamples = cell_folds, grid=tree_grid)

# check the results
tree_res %>% 
  collect_metrics() %>% 
  mutate( tree_depth = factor(tree_depth) ) %>% 
  ggplot(aes(cost_complexity, mean, color=tree_depth)) +
  geom_line(size=1.5, alpha=0.6) +
  geom_point(size=2) +
  facet_wrap(~.metric, scales="free", nrow=2) + 
  scale_x_log10(labels=scales::label_number()) + 
  scale_color_viridis_d(option="plasma",begin=.9, end = 0) + 
  theme_light()

# top 5 models (on roc_auc metric)
tree_res %>% 
  show_best("roc_auc")

# best model
tree_res %>% 
  select_best("roc_auc")

# workflow with best parameters
final_wf <- tree_wf %>% 
  finalize_workflow(select_best(tree_res, "roc_auc"))

# fit the model againt all training data
final_tree <- final_wf %>% 
  fit(data=cell_trn)

final_tree

library(vip)

final_tree %>% 
  pull_workflow_fit() %>% 
  vip()


final_fit <-
  final_wf %>% 
  last_fit(cell_split) # run the model on the training set and evaluates in the testset

final_fit %>% 
  collect_metrics()

final_fit %>% 
  collect_predictions() %>% 
  roc_curve(class, .pred_PS) %>% 
  autoplot()
