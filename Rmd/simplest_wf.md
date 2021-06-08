Intro
=====

This document emulates the simplest steps to make a straightforward ML
using [`{tidyverse}`](https://www.tidymodels.org/) package. These are
the steps:

1.  use [`{rsample}`](https://rsample.tidymodels.org/) to split the
    dataset between training and testing subsets
2.  use [`{recipe}`](https://recipes.tidymodels.org/) to make some data
    preprocessing script
3.  use [`{parnsip}`](https://parsnip.tidymodels.org/) to define a
    **ranger random forest** model
4.  put the recipe and the model in a
    [`{workflow}`](https://workflows.tidymodels.org/) object
5.  fit a model using the training subset
6.  use the fitted model to make a prediction
7.  use [`{yardstick}`](https://yardstick.tidymodels.org/) the check the
    model performance

Packages
========

``` r
library(tidymodels)  
library(mlbench)    # mlbench is a library with several dataset to perform ML trainig
library(skimr)      # to look the dataset

# loading "Boston Housing" dataset
data("BostonHousing")
```

Dataset: Boston Housing Dataset
===============================

Housing data contains 506 census tracts of Boston from the 1970 census.
The dataframe BostonHousing contains the original data by Harrison and
Rubinfeld (1979), the dataframe BostonHousing2 the corrected version
with additional spatial information.

You can include this data by installing mlbench library or download the
dataset. The data has following features, medv being the target
variable:

-   crim - per capita crime rate by town
-   zn - proportion of residential land zoned for lots over 25,000 sq.ft
-   indus - proportion of non-retail business acres per town
-   chas - Charles River dummy variable (= 1 if tract bounds river; 0
    otherwise)
-   nox - nitric oxides concentration (parts per 10 million)
-   rm - average number of rooms per dwelling
-   age - proportion of owner-occupied units built prior to 1940
-   dis - weighted distances to five Boston employment centres
-   rad - index of accessibility to radial highways
-   tax - full-value property-tax rate per USD 10,000
-   ptratio- pupil-teacher ratio by town
-   b 1000(B - 0.63)^2, where B is the proportion of blacks by town
-   lstat - percentage of lower status of the population
-   medv - median value of owner-occupied homes in USD 1000’s

``` r
BostonHousing %>% 
  skim()
```

|                                                  |            |
|:-------------------------------------------------|:-----------|
| Name                                             | Piped data |
| Number of rows                                   | 506        |
| Number of columns                                | 14         |
| \_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_   |            |
| Column type frequency:                           |            |
| factor                                           | 1          |
| numeric                                          | 13         |
| \_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_ |            |
| Group variables                                  | None       |

Data summary

**Variable type: factor**

| skim_variable | n_missing | complete_rate | ordered | n_unique | top_counts    |
|:--------------|----------:|--------------:|:--------|---------:|:--------------|
| chas          |         0 |             1 | FALSE   |        2 | 0: 471, 1: 35 |

**Variable type: numeric**

| skim_variable | n_missing | complete_rate |   mean |     sd |     p0 |    p25 |    p50 |    p75 |   p100 | hist  |
|:--------------|----------:|--------------:|-------:|-------:|-------:|-------:|-------:|-------:|-------:|:------|
| crim          |         0 |             1 |   3.61 |   8.60 |   0.01 |   0.08 |   0.26 |   3.68 |  88.98 | ▇▁▁▁▁ |
| zn            |         0 |             1 |  11.36 |  23.32 |   0.00 |   0.00 |   0.00 |  12.50 | 100.00 | ▇▁▁▁▁ |
| indus         |         0 |             1 |  11.14 |   6.86 |   0.46 |   5.19 |   9.69 |  18.10 |  27.74 | ▇▆▁▇▁ |
| nox           |         0 |             1 |   0.55 |   0.12 |   0.38 |   0.45 |   0.54 |   0.62 |   0.87 | ▇▇▆▅▁ |
| rm            |         0 |             1 |   6.28 |   0.70 |   3.56 |   5.89 |   6.21 |   6.62 |   8.78 | ▁▂▇▂▁ |
| age           |         0 |             1 |  68.57 |  28.15 |   2.90 |  45.02 |  77.50 |  94.07 | 100.00 | ▂▂▂▃▇ |
| dis           |         0 |             1 |   3.80 |   2.11 |   1.13 |   2.10 |   3.21 |   5.19 |  12.13 | ▇▅▂▁▁ |
| rad           |         0 |             1 |   9.55 |   8.71 |   1.00 |   4.00 |   5.00 |  24.00 |  24.00 | ▇▂▁▁▃ |
| tax           |         0 |             1 | 408.24 | 168.54 | 187.00 | 279.00 | 330.00 | 666.00 | 711.00 | ▇▇▃▁▇ |
| ptratio       |         0 |             1 |  18.46 |   2.16 |  12.60 |  17.40 |  19.05 |  20.20 |  22.00 | ▁▃▅▅▇ |
| b             |         0 |             1 | 356.67 |  91.29 |   0.32 | 375.38 | 391.44 | 396.22 | 396.90 | ▁▁▁▁▇ |
| lstat         |         0 |             1 |  12.65 |   7.14 |   1.73 |   6.95 |  11.36 |  16.96 |  37.97 | ▇▇▅▂▁ |
| medv          |         0 |             1 |  22.53 |   9.20 |   5.00 |  17.02 |  21.20 |  25.00 |  50.00 | ▂▇▅▁▁ |

We’ll try to predic **medv** (median value of owner-occupied homes).

Training & Testing Datasets
===========================

``` r
boston_split <- initial_split(BostonHousing)
boston_split
```

    ## <Analysis/Assess/Total>
    ## <380/126/506>

Data Preprocessing
==================

``` r
recp <- BostonHousing %>% 
  recipe(medv~.) %>%                               # formula goes here
  step_nzv(all_predictors(), -all_nominal()) %>%   # remove near zero var
  step_center(all_predictors(),-all_nominal()) %>% # center 
  step_scale(all_predictors(),-all_nominal()) %>%  # scale
  step_BoxCox(all_predictors(), -all_nominal())    # box cox normalization
recp
```

    ## Data Recipe
    ## 
    ## Inputs:
    ## 
    ##       role #variables
    ##    outcome          1
    ##  predictor         13
    ## 
    ## Operations:
    ## 
    ## Sparse, unbalanced variable filter on all_predictors(), -all_nominal()
    ## Centering for all_predictors(), -all_nominal()
    ## Scaling for all_predictors(), -all_nominal()
    ## Box-Cox transformation on all_predictors(), -all_nominal()

Model Specification
===================

``` r
model_eng <- rand_forest(mode="regression") %>% 
  set_engine("ranger")
model_eng
```

    ## Random Forest Model Specification (regression)
    ## 
    ## Computational engine: ranger

Workflow
========

``` r
wf <- workflow() %>% 
  add_recipe(recp) %>%  # preprocessing specifiation (with formula)
  add_model(model_eng)  # model specification
wf
```

    ## == Workflow ====================================================================
    ## Preprocessor: Recipe
    ## Model: rand_forest()
    ## 
    ## -- Preprocessor ----------------------------------------------------------------
    ## 4 Recipe Steps
    ## 
    ## * step_nzv()
    ## * step_center()
    ## * step_scale()
    ## * step_BoxCox()
    ## 
    ## -- Model -----------------------------------------------------------------------
    ## Random Forest Model Specification (regression)
    ## 
    ## Computational engine: ranger

Training the model
==================

``` r
# the workflow do all by itself
# calculates the data preprocessing (recipe)
# apply to the training set
# fit the model using it
model_fit <- fit(wf, training(boston_split)) 
model_fit
```

    ## == Workflow [trained] ==========================================================
    ## Preprocessor: Recipe
    ## Model: rand_forest()
    ## 
    ## -- Preprocessor ----------------------------------------------------------------
    ## 4 Recipe Steps
    ## 
    ## * step_nzv()
    ## * step_center()
    ## * step_scale()
    ## * step_BoxCox()
    ## 
    ## -- Model -----------------------------------------------------------------------
    ## Ranger result
    ## 
    ## Call:
    ##  ranger::ranger(x = maybe_data_frame(x), y = y, num.threads = 1,      verbose = FALSE, seed = sample.int(10^5, 1)) 
    ## 
    ## Type:                             Regression 
    ## Number of trees:                  500 
    ## Sample size:                      380 
    ## Number of independent variables:  13 
    ## Mtry:                             3 
    ## Target node size:                 5 
    ## Variable importance mode:         none 
    ## Splitrule:                        variance 
    ## OOB prediction error (MSE):       12.69973 
    ## R squared (OOB):                  0.8467572

Predict
=======

``` r
# the prediction applied on the fitted workflow automatically
# apply the trained transformation on the new dataset
# and predict the output using the trained model
y_hat <- predict(model_fit, testing(boston_split))
head(y_hat)
```

    ## # A tibble: 6 x 1
    ##   .pred
    ##   <dbl>
    ## 1  18.8
    ## 2  21.4
    ## 3  18.3
    ## 4  17.6
    ## 5  16.7
    ## 6  15.4

Evaluate
========

``` r
y_hat %>% 
  bind_cols(testing(boston_split)) %>% # binds the "true value"
  metrics(truth=medv, estimate=.pred)  # get the estimation metrics (automatically)
```

    ## # A tibble: 3 x 3
    ##   .metric .estimator .estimate
    ##   <chr>   <chr>          <dbl>
    ## 1 rmse    standard       3.38 
    ## 2 rsq     standard       0.889
    ## 3 mae     standard       2.12
