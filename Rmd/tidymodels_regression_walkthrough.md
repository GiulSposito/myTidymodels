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
3.  Train a model ([`{parsnip}`](https://parsnip.tidymodels.org/)) using
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
    ##     disp     hp    drat     wt   qsec     vs     am   gear   carb   mpg
    ##    <dbl>  <dbl>   <dbl>  <dbl>  <dbl>  <dbl>  <dbl>  <dbl>  <dbl> <dbl>
    ## 1 -0.451 -0.517  0.506  -0.520 -0.707 -0.827  0.979  0.219  0.631  21  
    ## 2 -0.451 -0.517  0.506  -0.229 -0.354 -0.827  0.979  0.219  0.631  21  
    ## 3 -0.900 -0.762  0.392  -0.862  0.647  1.16   0.979  0.219 -1.12   22.8
    ## 4  1.28   0.419 -1.20    0.415 -0.354 -0.827 -0.979 -1.09  -0.534  18.7
    ## 5 -0.566 -1.21   0.0275  0.130  1.52   1.16  -0.979  0.219 -0.534  24.4
    ## 6 -0.385 -0.330  0.552   0.415  0.452  1.16  -0.979  0.219  0.631  19.2

``` r
# we can apply the transformation on the test set using `bake(recipe, new_data)`
cars_testing <- bake(cars_recipe, tst_cars)
head(cars_testing)
```

    ## # A tibble: 6 x 10
    ##     disp     hp   drat     wt   qsec     vs     am   gear   carb   mpg
    ##    <dbl>  <dbl>  <dbl>  <dbl>  <dbl>  <dbl>  <dbl>  <dbl>  <dbl> <dbl>
    ## 1  0.395 -0.517 -1.36  0.158   1.17   1.16  -0.979 -1.09  -1.12   21.4
    ## 2  0.110 -0.589 -2.09  0.438   1.66   1.16  -0.979 -1.09  -1.12   18.1
    ## 3  1.28   1.43  -1.07  0.563  -1.10  -0.827 -0.979 -1.09   0.631  14.3
    ## 4 -0.617 -0.733  0.552 0.0842  3.35   1.16  -0.979  0.219 -0.534  22.8
    ## 5  2.24   0.851 -1.70  2.48    0.251 -0.827 -0.979 -1.09   0.631  10.4
    ## 6  1.97   1.21  -1.02  2.59   -0.102 -0.827 -0.979 -1.09   0.631  14.7

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
    ##     20.6375       2.9641      -1.3213      -0.5508      -5.3450       3.4941  
    ##          vs           am         gear         carb  
    ##     -0.4925       0.9195       1.5880       0.3190

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
    ## -3.1863 -1.5903 -0.1359  1.2566  4.3479 
    ## 
    ## Coefficients:
    ##             Estimate Std. Error t value Pr(>|t|)    
    ## (Intercept)  20.6375     0.5325  38.759  1.2e-15 ***
    ## disp          2.9641     2.5566   1.159   0.2657    
    ## hp           -1.3213     1.8164  -0.727   0.4789    
    ## drat         -0.5508     1.0145  -0.543   0.5957    
    ## wt           -5.3450     2.2009  -2.429   0.0292 *  
    ## qsec          3.4941     2.0127   1.736   0.1045    
    ## vs           -0.4925     1.3792  -0.357   0.7263    
    ## am            0.9195     1.1237   0.818   0.4269    
    ## gear          1.5880     1.3457   1.180   0.2576    
    ## carb          0.3190     1.6874   0.189   0.8528    
    ## ---
    ## Signif. codes:  0 '***' 0.001 '**' 0.01 '*' 0.05 '.' 0.1 ' ' 1
    ## 
    ## Residual standard error: 2.609 on 14 degrees of freedom
    ## Multiple R-squared:  0.8841, Adjusted R-squared:  0.8096 
    ## F-statistic: 11.87 on 9 and 14 DF,  p-value: 3.923e-05

(4) Prediction
==============

``` r
y_hat <- predict(cars_lm, cars_testing)
head(y_hat)
```

    ## # A tibble: 6 x 1
    ##   .pred
    ##   <dbl>
    ## 1 22.9 
    ## 2 22.8 
    ## 3 14.2 
    ## 4 29.4 
    ## 5 12.7 
    ## 6  9.22

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
    ## 1 rmse    standard       3.73 
    ## 2 rsq     standard       0.750
    ## 3 mae     standard       3.06

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
    ## Fit time:  10ms 
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
    ## OOB prediction error (MSE):       8.553104 
    ## R squared (OOB):                  0.7606785

``` r
# check if fits better
predict(cars_rf, cars_testing) %>% 
  bind_cols(cars_testing) %>% 
  metrics(truth=mpg, estimate = .pred)
```

    ## # A tibble: 3 x 3
    ##   .metric .estimator .estimate
    ##   <chr>   <chr>          <dbl>
    ## 1 rmse    standard       1.33 
    ## 2 rsq     standard       0.966
    ## 3 mae     standard       1.16

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
