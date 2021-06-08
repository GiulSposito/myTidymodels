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
================================

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
================================

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
    ##      disp     hp   drat      wt   qsec     vs     am   gear   carb   mpg
    ##     <dbl>  <dbl>  <dbl>   <dbl>  <dbl>  <dbl>  <dbl>  <dbl>  <dbl> <dbl>
    ## 1 -0.581  -0.552  0.532 -0.613  -0.831 -0.900  1.26   0.438  0.874  21  
    ## 2  0.169  -0.552 -0.901 -0.0560  1.08   1.06  -0.758 -0.876 -1.30   21.4
    ## 3 -0.0837 -0.630 -1.46   0.173   1.57   1.06  -0.758 -0.876 -1.30   18.1
    ## 4  0.949   1.55  -0.673  0.276  -1.23  -0.900 -0.758 -0.876  0.874  14.3
    ## 5 -0.683  -1.30   0.165 -0.0794  1.43   1.06  -0.758  0.438 -0.573  24.4
    ## 6 -0.523  -0.350  0.567  0.154   0.346  1.06  -0.758  0.438  0.874  19.2

``` r
# we can apply the transformation on the test set using `bake(recipe, new_data)`
cars_testing <- bake(cars_recipe, tst_cars)
head(cars_testing)
```

    ## # A tibble: 6 x 10
    ##     disp     hp   drat     wt   qsec     vs     am   gear   carb   mpg
    ##    <dbl>  <dbl>  <dbl>  <dbl>  <dbl>  <dbl>  <dbl>  <dbl>  <dbl> <dbl>
    ## 1 -0.581 -0.552  0.532 -0.374 -0.473 -0.900  1.26   0.438  0.874  21  
    ## 2 -0.979 -0.817  0.445 -0.893  0.545  1.06   1.26   0.438 -1.30   22.8
    ## 3  0.949  0.460 -0.778  0.154 -0.473 -0.900 -0.758 -0.876 -0.573  18.7
    ## 4 -0.728 -0.786  0.567 -0.117  3.29   1.06  -0.758  0.438 -0.573  22.8
    ## 5  0.305  0.538 -0.918  0.426 -0.102 -0.900 -0.758 -0.876  0.151  17.3
    ## 6 -1.26  -1.25   1.09  -1.35   1.37   1.06   1.26   0.438 -1.30   33.9

3. Training a model
===================

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
    ##     19.8417       0.6019      -2.4685       0.5375      -1.8237      -0.4001  
    ##          vs           am         gear         carb  
    ##      0.5715       0.9899       0.6651      -1.2276

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
    ## -3.2804 -1.4086 -0.1161  1.0699  4.6338 
    ## 
    ## Coefficients:
    ##             Estimate Std. Error t value Pr(>|t|)    
    ## (Intercept)  19.8417     0.5308  37.381 1.99e-15 ***
    ## disp          0.6019     2.5471   0.236    0.817    
    ## hp           -2.4685     1.9302  -1.279    0.222    
    ## drat          0.5375     0.9518   0.565    0.581    
    ## wt           -1.8237     2.8138  -0.648    0.527    
    ## qsec         -0.4001     2.5256  -0.158    0.876    
    ## vs            0.5715     1.5026   0.380    0.709    
    ## am            0.9899     1.1663   0.849    0.410    
    ## gear          0.6651     1.2200   0.545    0.594    
    ## carb         -1.2276     1.3535  -0.907    0.380    
    ## ---
    ## Signif. codes:  0 '***' 0.001 '**' 0.01 '*' 0.05 '.' 0.1 ' ' 1
    ## 
    ## Residual standard error: 2.6 on 14 degrees of freedom
    ## Multiple R-squared:  0.8898, Adjusted R-squared:  0.8189 
    ## F-statistic: 12.56 on 9 and 14 DF,  p-value: 2.817e-05

4. Prediction
=============

``` r
y_hat <- predict(cars_lm, cars_testing)
head(y_hat)
```

    ## # A tibble: 6 x 1
    ##   .pred
    ##   <dbl>
    ## 1  22.0
    ## 2  26.7
    ## 3  17.6
    ## 4  21.4
    ## 5  15.4
    ## 6  28.4

5. Evaluate Model Performance
=============================

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
    ## 1 rmse    standard       3.23 
    ## 2 rsq     standard       0.716
    ## 3 mae     standard       2.79

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
    ## OOB prediction error (MSE):       6.60889 
    ## R squared (OOB):                  0.8230033

``` r
# check if fits better
predict(cars_rf, cars_testing) %>% 
  bind_cols(cars_testing) %>% 
  metrics(truth=mpg, estimate = .pred)
```

    ## # A tibble: 3 x 3
    ##   .metric .estimator .estimate
    ##   <chr>   <chr>          <dbl>
    ## 1 rmse    standard       2.35 
    ## 2 rsq     standard       0.843
    ## 3 mae     standard       1.80

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
