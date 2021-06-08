Intro
=====

This notebook tells the basic steps to ML pipeline using
[`{tidymodels}`](https://www.tidymodels.org/) packages, we’ll do a
regression case and a classification case.

The traditional (without tunning) step for a ML pipeline are:

1.  Split the dataset between Training and Testing subsets
    ([`{rsample}`](https://rsample.tidymodels.org/))
2.  Preprocessing and Feature Eng
    [`{recipes}`](https://recipes.tidymodels.org/)
3.  Train a model ([`{parnsip}`](https://parsnip.tidymodels.org/)) using
    training dataset
4.  Predict the outcome using the test dataset
5.  Eval the model performance
    ([`{yardstick}`](https://yardstick.tidymodels.org/))

In this notebook we won’t use the
[`{workflow}`](https://workflows.tidymodels.org/) package, to understand
the building blocks of [`{tidymodels}`](https://www.tidymodels.org/).

Regression Example
==================

(1) training and testing datasets
=================================

``` r
# tidymodel package to split datasets (tr/ts, CV,...)
library(rsample) 

# rsample::initial_split
cars_split <- initial_split(mtcars, prop = .75)

# `rsplit` object: <training/test/total>
cars_split
```

    ## <Analysis/Assess/Total>
    ## <24/8/32>

``` r
# getting the slices
trn_cars <- training(cars_split)
tst_cars <- testing(cars_split)
```

(2) Preprocessing and Feature Eng
=================================

``` r
# tidymodel package to specify a sequence of transformation steps
library(recipes)

# recipe
cars_recipe <- trn_cars %>%         # base dataset
  recipe(mpg ~ .) %>%               # recipe with formula
  step_corr(all_predictors()) %>%   # remove variables with large correlations 
  step_center(all_predictors()) %>% # normalize numeric data to have a mean of zero
  step_scale(all_predictors()) %>%  # normalize data to have a standard deviation of one
  # estimate the required parameters from a training set
  # that can be later applied to other data sets.
  prep()


# recipe object
cars_recipe
```

    ## Data Recipe
    ## 
    ## Inputs:
    ## 
    ##       role #variables
    ##    outcome          1
    ##  predictor         10
    ## 
    ## Training data contained 24 data points and no missing data.
    ## 
    ## Operations:
    ## 
    ## Correlation filter removed cyl [trained]
    ## Centering for disp, hp, drat, wt, qsec, vs, am, gear, carb [trained]
    ## Scaling for disp, hp, drat, wt, qsec, vs, am, gear, carb [trained]

``` r
# we can get the transformed training set using `juice(recipe)`
cars_training <- juice(cars_recipe)
head(cars_training)
```

    ## # A tibble: 6 x 10
    ##      disp     hp   drat       wt   qsec     vs     am   gear   carb   mpg
    ##     <dbl>  <dbl>  <dbl>    <dbl>  <dbl>  <dbl>  <dbl>  <dbl>  <dbl> <dbl>
    ## 1 -0.564  -0.515  0.504 -0.548   -0.730 -0.900  1.06   0.267  0.672  21  
    ## 2 -0.956  -0.747  0.414 -0.826    0.396  1.06   1.06   0.267 -1.06   22.8
    ## 3  0.174  -0.515 -0.968  0.00224  0.831  1.06  -0.900 -1.02  -1.06   21.4
    ## 4  0.942   0.374 -0.842  0.210   -0.437 -0.900 -0.900 -1.02  -0.480  18.7
    ## 5 -0.0744 -0.583 -1.54   0.229    1.24   1.06  -0.900 -1.02  -1.06   18.1
    ## 6  0.942   1.33  -0.735  0.331   -1.05  -0.900 -0.900 -1.02   0.672  14.3

``` r
# we can apply the transformation on the test set using `bake(recipe, new_data)`
cars_testing <- bake(cars_recipe, tst_cars)
head(cars_testing)
```

    ## # A tibble: 6 x 10
    ##     disp     hp   drat     wt    qsec     vs     am   gear    carb   mpg
    ##    <dbl>  <dbl>  <dbl>  <dbl>   <dbl>  <dbl>  <dbl>  <dbl>   <dbl> <dbl>
    ## 1 -0.564 -0.515  0.504 -0.312 -0.437  -0.900  1.06   0.267  0.672   21  
    ## 2 -0.507 -0.337  0.540  0.210  0.234   1.06  -0.900  0.267  0.672   19.2
    ## 3  0.308  0.443 -0.986  0.479 -0.133  -0.900 -0.900 -1.02   0.0960  17.3
    ## 4  0.308  0.443 -0.986  0.525  0.0768 -0.900 -0.900 -1.02   0.0960  15.2
    ## 5 -1.18  -1.12   0.827 -0.937  0.847   1.06   1.06   0.267 -1.06    32.4
    ## 6 -0.864 -0.692  0.145 -0.692  1.13    1.06  -0.900 -1.02  -1.06    21.5

(3) Training a model
====================

``` r
# tidymodel package the uniforms the machine learnings algorithm interface
library(parsnip) # parsnip is the caret successor

cars_lm <- parsnip::linear_reg() %>% # interface to linear models
  set_engine("lm") %>%               # using traditional R's lm as engine
  fit(mpg ~ ., data=cars_training)   # fit the model using transformed training set

# parsnip object
cars_lm
```

    ## parsnip model object
    ## 
    ## Fit time:  0ms 
    ## 
    ## Call:
    ## stats::lm(formula = mpg ~ ., data = data)
    ## 
    ## Coefficients:
    ## (Intercept)         disp           hp         drat           wt         qsec  
    ##    20.31250      1.98525     -1.81620      0.43214     -4.76702      1.53861  
    ##          vs           am         gear         carb  
    ##     0.03287      0.72571      0.45356      0.02379

``` r
# getting the real model (lm) inside parsnip
summary(cars_lm$fit)
```

    ## 
    ## Call:
    ## stats::lm(formula = mpg ~ ., data = data)
    ## 
    ## Residuals:
    ##     Min      1Q  Median      3Q     Max 
    ## -3.1402 -1.7124 -0.1737  1.2988  4.8865 
    ## 
    ## Coefficients:
    ##             Estimate Std. Error t value Pr(>|t|)    
    ## (Intercept) 20.31250    0.57565  35.286 4.42e-15 ***
    ## disp         1.98525    2.89407   0.686   0.5039    
    ## hp          -1.81620    2.09170  -0.868   0.3999    
    ## drat         0.43214    1.13669   0.380   0.7095    
    ## wt          -4.76702    2.26835  -2.102   0.0542 .  
    ## qsec         1.53861    1.66829   0.922   0.3720    
    ## vs           0.03287    1.30186   0.025   0.9802    
    ## am           0.72571    1.36347   0.532   0.6029    
    ## gear         0.45356    1.32902   0.341   0.7380    
    ## carb         0.02379    1.62035   0.015   0.9885    
    ## ---
    ## Signif. codes:  0 '***' 0.001 '**' 0.01 '*' 0.05 '.' 0.1 ' ' 1
    ## 
    ## Residual standard error: 2.82 on 14 degrees of freedom
    ## Multiple R-squared:  0.8721, Adjusted R-squared:   0.79 
    ## F-statistic: 10.61 on 9 and 14 DF,  p-value: 7.493e-05

(4) Prediction
==============

``` r
y_hat <- predict(cars_lm, cars_testing)
head(y_hat)
```

    ## # A tibble: 6 x 1
    ##   .pred
    ##   <dbl>
    ## 1  22.0
    ## 2  19.0
    ## 3  16.1
    ## 4  16.2
    ## 5  27.0
    ## 6  23.8

(5) Evaluate Model Performance
==============================

``` r
# tidymodel package for measuring model performances
library(yardstick)

y_hat %>%                               
  bind_cols(cars_testing) %>%        # binds prediction to the real data
  metrics(truth=mpg, estimate=.pred) # use yardstick::metrics to get the evalution metrics
```

    ## # A tibble: 3 x 3
    ##   .metric .estimator .estimate
    ##   <chr>   <chr>          <dbl>
    ## 1 rmse    standard       2.30 
    ## 2 rsq     standard       0.863
    ## 3 mae     standard       1.71

Bonus: Changing the model and checking for a better performance
===============================================================

``` r
# Bonus: testing another model
cars_rf <- rand_forest(trees = 100, mode="regression") %>% # random forest
  set_engine("ranger") %>%                                 # ranger algo
  fit(mpg ~ ., data=cars_training)                         # fit the model  

# parsnip object
cars_rf
```

    ## parsnip model object
    ## 
    ## Fit time:  0ms 
    ## Ranger result
    ## 
    ## Call:
    ##  ranger::ranger(x = maybe_data_frame(x), y = y, num.trees = ~100,      num.threads = 1, verbose = FALSE, seed = sample.int(10^5,          1)) 
    ## 
    ## Type:                             Regression 
    ## Number of trees:                  100 
    ## Sample size:                      24 
    ## Number of independent variables:  9 
    ## Mtry:                             3 
    ## Target node size:                 5 
    ## Variable importance mode:         none 
    ## Splitrule:                        variance 
    ## OOB prediction error (MSE):       7.422913 
    ## R squared (OOB):                  0.8039528

``` r
# check if fits better
predict(cars_rf, cars_testing) %>% 
  bind_cols(cars_testing) %>% 
  metrics(truth=mpg, estimate = .pred)
```

    ## # A tibble: 3 x 3
    ##   .metric .estimator .estimate
    ##   <chr>   <chr>          <dbl>
    ## 1 rmse    standard       2.04 
    ## 2 rsq     standard       0.925
    ## 3 mae     standard       1.49

Regression Full Code
====================

``` r
# 1. training and testing datasets

# tidymodel package to split datasets (tr/ts, CV,...)
library(rsample) 

# rsample::initial_split
cars_split <- initial_split(mtcars, prop = .75)

# `rsplit` object: <training/test/total>
cars_split

# getting the slices
trn_cars <- training(cars_split)
tst_cars <- testing(cars_split)


# 2. Preprocessing and Feature Eng

# tidymodel package to specify a sequence of transformation steps
library(recipes)

# recipe
cars_recipe <- trn_cars %>%         # base dataset
  recipe(mpg ~ .) %>%               # recipe with formula
  step_corr(all_predictors()) %>%   # remove variables with large correlations 
  step_center(all_predictors()) %>% # normalize numeric data to have a mean of zero
  step_scale(all_predictors()) %>%  # normalize data to have a standard deviation of one
  # estimate the required parameters from a training set
  # that can be later applied to other data sets.
  prep()


# recipe object
cars_recipe


# we can get the transformed training set using `juice(recipe)`
cars_training <- juice(cars_recipe)
head(cars_training)

# we can apply the transformation on the test set using `bake(recipe, new_data)`
cars_testing <- bake(cars_recipe, tst_cars)
head(cars_testing)



# 3. Training a model

# tidymodel package the uniforms the machine learnings algorithm interface
library(parsnip) # parsnip is the caret successor

cars_lm <- parsnip::linear_reg() %>% # interface to linear models
  set_engine("lm") %>%               # using traditional R's lm as engine
  fit(mpg ~ ., data=cars_training)   # fit the model using transformed training set

# parsnip object
cars_lm


# getting the real model (lm) inside parsnip
summary(cars_lm$fit)


# 4. Prediction

y_hat <- predict(cars_lm, cars_testing)
head(y_hat)

# 5. Evaluate Model Performance

# tidymodel package for measuring model performances
library(yardstick)

y_hat %>%                               
  bind_cols(cars_testing) %>%        # binds prediction to the real data
  metrics(truth=mpg, estimate=.pred) # use yardstick::metrics to get the evalution metrics


# Bonus: Changing the model and checking for a better performance

# Bonus: testing another model
cars_rf <- rand_forest(trees = 100, mode="regression") %>% # random forest
  set_engine("ranger") %>%                                 # ranger algo
  fit(mpg ~ ., data=cars_training)                         # fit the model  

# parsnip object
cars_rf

# check if fits better
predict(cars_rf, cars_testing) %>% 
  bind_cols(cars_testing) %>% 
  metrics(truth=mpg, estimate = .pred)
```
