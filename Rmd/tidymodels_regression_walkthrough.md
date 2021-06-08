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

1. training and testing datasets
--------------------------------

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

2. Preprocessing and Feature Eng
--------------------------------

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
    ## Correlation filter removed disp [trained]
    ## Centering for cyl, hp, drat, wt, qsec, vs, am, gear, carb [trained]
    ## Scaling for cyl, hp, drat, wt, qsec, vs, am, gear, carb [trained]

``` r
# we can get the transformed training set using `juice(recipe)`
cars_training <- juice(cars_recipe)
head(cars_training)
```

    ## # A tibble: 6 x 10
    ##     cyl     hp   drat       wt   qsec     vs     am   gear   carb   mpg
    ##   <dbl>  <dbl>  <dbl>    <dbl>  <dbl>  <dbl>  <dbl>  <dbl>  <dbl> <dbl>
    ## 1  0    -0.458  0.605 -0.551   -0.795 -0.900  1.06   0.267  0.683  21  
    ## 2  0    -0.458  0.605 -0.303   -0.506 -0.900  1.06   0.267  0.683  21  
    ## 3  0    -0.458 -1.01   0.0279   0.743  1.06  -0.900 -1.02  -1.01   21.4
    ## 4  1.13  0.481 -0.873  0.247   -0.506 -0.900 -0.900 -1.02  -0.448  18.7
    ## 5  0    -0.530 -1.64   0.266    1.15   1.06  -0.900 -1.02  -1.01   18.1
    ## 6 -1.13 -1.15   0.191  0.00357  1.03   1.06  -0.900  0.267 -0.448  24.4

``` r
# we can apply the transformation on the test set using `bake(recipe, new_data)`
cars_testing <- bake(cars_recipe, tst_cars)
head(cars_testing)
```

    ## # A tibble: 6 x 10
    ##     cyl     hp   drat     wt      qsec     vs     am   gear   carb   mpg
    ##   <dbl>  <dbl>  <dbl>  <dbl>     <dbl>  <dbl>  <dbl>  <dbl>  <dbl> <dbl>
    ## 1 -1.13 -0.703  0.506 -0.843  0.314     1.06   1.06   0.267 -1.01   22.8
    ## 2  1.13  1.49  -0.754  0.373 -1.12     -0.900 -0.900 -1.02   0.683  14.3
    ## 3  0    -0.270  0.644  0.247  0.154     1.06  -0.900  0.267  0.683  19.2
    ## 4  1.13  0.553 -1.03   0.860 -0.310    -0.900 -0.900 -1.02   0.118  16.4
    ## 5  1.13  0.553 -1.03   0.578 -0.000645 -0.900 -0.900 -1.02   0.118  15.2
    ## 6 -1.13 -1.29   2.63  -1.53   0.268     1.06   1.06   0.267 -0.448  30.4

3. Training a model
-------------------

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
    ## (Intercept)          cyl           hp         drat           wt         qsec  
    ##     20.5042      -0.5438      -0.4659      -0.2526      -2.3178       1.5664  
    ##          vs           am         gear         carb  
    ##      0.0555       2.0514       0.8058      -1.4211

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
    ## -4.1758 -1.5428 -0.3907  1.9121  4.2497 
    ## 
    ## Coefficients:
    ##             Estimate Std. Error t value Pr(>|t|)    
    ## (Intercept)  20.5042     0.5881  34.865 5.22e-15 ***
    ## cyl          -0.5438     2.2750  -0.239    0.815    
    ## hp           -0.4659     1.7305  -0.269    0.792    
    ## drat         -0.2526     1.2752  -0.198    0.846    
    ## wt           -2.3178     1.5223  -1.523    0.150    
    ## qsec          1.5664     1.7634   0.888    0.389    
    ## vs            0.0555     1.3789   0.040    0.968    
    ## am            2.0514     1.3774   1.489    0.159    
    ## gear          0.8058     1.6800   0.480    0.639    
    ## carb         -1.4211     1.3304  -1.068    0.304    
    ## ---
    ## Signif. codes:  0 '***' 0.001 '**' 0.01 '*' 0.05 '.' 0.1 ' ' 1
    ## 
    ## Residual standard error: 2.881 on 14 degrees of freedom
    ## Multiple R-squared:  0.8694, Adjusted R-squared:  0.7854 
    ## F-statistic: 10.35 on 9 and 14 DF,  p-value: 8.63e-05

4. Prediction
-------------

``` r
y_hat <- predict(cars_lm, cars_testing)
head(y_hat)
```

    ## # A tibble: 6 x 1
    ##   .pred
    ##   <dbl>
    ## 1  27.7
    ## 2  13.1
    ## 3  17.6
    ## 4  14.5
    ## 5  15.7
    ## 6  28.1

5. Evaluate Model Performance
-----------------------------

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
    ## 1 rmse    standard       2.54 
    ## 2 rsq     standard       0.837
    ## 3 mae     standard       2.17

Bonus: Changing the model and checking for a better performance
---------------------------------------------------------------

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
    ## Fit time:  11ms 
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
    ## OOB prediction error (MSE):       7.511333 
    ## R squared (OOB):                  0.8057886

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
    ## 2 rsq     standard       0.862
    ## 3 mae     standard       1.51

Regression Full Code
--------------------

``` r
## 1. training and testing datasets

# tidymodel package to split datasets (tr/ts, CV,...)
library(rsample) 

# rsample::initial_split
cars_split <- initial_split(mtcars, prop = .75)

# `rsplit` object: <training/test/total>
cars_split

# getting the slices
trn_cars <- training(cars_split)
tst_cars <- testing(cars_split)


## 2. Preprocessing and Feature Eng

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



## 3. Training a model

# tidymodel package the uniforms the machine learnings algorithm interface
library(parsnip) # parsnip is the caret successor

cars_lm <- parsnip::linear_reg() %>% # interface to linear models
  set_engine("lm") %>%               # using traditional R's lm as engine
  fit(mpg ~ ., data=cars_training)   # fit the model using transformed training set

# parsnip object
cars_lm


# getting the real model (lm) inside parsnip
summary(cars_lm$fit)


## 4. Prediction

y_hat <- predict(cars_lm, cars_testing)
head(y_hat)

## 5. Evaluate Model Performance

# tidymodel package for measuring model performances
library(yardstick)

y_hat %>%                               
  bind_cols(cars_testing) %>%        # binds prediction to the real data
  metrics(truth=mpg, estimate=.pred) # use yardstick::metrics to get the evalution metrics


## Bonus: Changing the model and checking for a better performance

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
