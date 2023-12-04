-   [workflow](#workflow)
    -   [workflow basics](#workflow-basics)
    -   [Adding Raw Variables](#adding-raw-variables)
    -   [Creating multiple workflows at
        once](#creating-multiple-workflows-at-once)
-   [Evaluating the test set](#evaluating-the-test-set)
-   [Reference](#reference)

# workflow

    library(tidymodels)

    ## ── Attaching packages ────────────────────────────────────── tidymodels 1.0.0 ──

    ## ✔ broom        1.0.5     ✔ recipes      1.0.6
    ## ✔ dials        1.1.0     ✔ rsample      1.1.1
    ## ✔ dplyr        1.1.3     ✔ tibble       3.2.1
    ## ✔ ggplot2      3.4.0     ✔ tidyr        1.3.0
    ## ✔ infer        1.0.4     ✔ tune         1.1.1
    ## ✔ modeldata    1.0.1     ✔ workflows    1.1.2
    ## ✔ parsnip      1.1.0     ✔ workflowsets 1.0.0
    ## ✔ purrr        1.0.2     ✔ yardstick    1.1.0

    ## ── Conflicts ───────────────────────────────────────── tidymodels_conflicts() ──
    ## ✖ purrr::discard() masks scales::discard()
    ## ✖ dplyr::filter()  masks stats::filter()
    ## ✖ dplyr::lag()     masks stats::lag()
    ## ✖ recipes::step()  masks stats::step()
    ## • Use suppressPackageStartupMessages() to eliminate package startup messages

    data(ames)
    ames <- mutate(ames, Sale_Price = log10(Sale_Price))

    set.seed(502)
    ames_split <- initial_split(ames, prop = 0.80, strata = Sale_Price)
    ames_train <- training(ames_split)
    ames_test  <-  testing(ames_split)

    lm_model <- linear_reg() %>% set_engine("lm")

<figure>
<img src="./Pasted%20image%2020231204145943.png"
alt="Incorrect mental model of where model estimation occurs in the data analysis process" />
<figcaption aria-hidden="true">Incorrect mental model of where model
estimation occurs in the data analysis process</figcaption>
</figure>

<figure>
<img src="./Pasted%20image%2020231204150140.png"
alt="Correct mental model of where model estimation occurs in the data analysis process" />
<figcaption aria-hidden="true">Correct mental model of where model
estimation occurs in the data analysis process</figcaption>
</figure>

## workflow basics

The workflow package allows the user to bind modeling + pre processing
objetcs together. Correct mental model of where model estimation occurs
in the data analysis process

    lm_wflow <- 
      workflow() |> 
      add_model(lm_model)

    lm_wflow

    ## ══ Workflow ════════════════════════════════════════════════════════════════════
    ## Preprocessor: None
    ## Model: linear_reg()
    ## 
    ## ── Model ───────────────────────────────────────────────────────────────────────
    ## Linear Regression Model Specification (regression)
    ## 
    ## Computational engine: lm

Notice that we have not yet specified how this workflow should
preprocess the data (`Preprocessor: None`).

If your model is very simple, a standard R formula can be used as a
`preprocesser`:

    lm_wflow <- 
      lm_wflow |> 
      add_formula(Sale_Price ~ Longitude + Latitude)

    lm_wflow

    ## ══ Workflow ════════════════════════════════════════════════════════════════════
    ## Preprocessor: Formula
    ## Model: linear_reg()
    ## 
    ## ── Preprocessor ────────────────────────────────────────────────────────────────
    ## Sale_Price ~ Longitude + Latitude
    ## 
    ## ── Model ───────────────────────────────────────────────────────────────────────
    ## Linear Regression Model Specification (regression)
    ## 
    ## Computational engine: lm

Workflows have a `fit()` method that can be used to create the model.

    lm_fit <- fit(lm_wflow, ames_train)
    lm_fit

    ## ══ Workflow [trained] ══════════════════════════════════════════════════════════
    ## Preprocessor: Formula
    ## Model: linear_reg()
    ## 
    ## ── Preprocessor ────────────────────────────────────────────────────────────────
    ## Sale_Price ~ Longitude + Latitude
    ## 
    ## ── Model ───────────────────────────────────────────────────────────────────────
    ## 
    ## Call:
    ## stats::lm(formula = ..y ~ ., data = data)
    ## 
    ## Coefficients:
    ## (Intercept)    Longitude     Latitude  
    ##    -302.974       -2.075        2.710

We can also `predict()` on the fitted workflow that follows all of the
same rules and naming conventions that we described for the `parsnip`
package:

    predict(lm_fit, slice_head(ames_test, n=5))

    ## # A tibble: 5 × 1
    ##   .pred
    ##   <dbl>
    ## 1  5.22
    ## 2  5.21
    ## 3  5.28
    ## 4  5.27
    ## 5  5.28

Both the model and preprocessor can be removed or updated:

    lm_fit |> 
      update_formula(Sale_Price ~ Longitude)

    ## ══ Workflow ════════════════════════════════════════════════════════════════════
    ## Preprocessor: Formula
    ## Model: linear_reg()
    ## 
    ## ── Preprocessor ────────────────────────────────────────────────────────────────
    ## Sale_Price ~ Longitude
    ## 
    ## ── Model ───────────────────────────────────────────────────────────────────────
    ## Linear Regression Model Specification (regression)
    ## 
    ## Computational engine: lm

Note that, in this new object, the output shows that the previous fitted
model was removed since the new formula is inconsistent with the
previous model fit.

## Adding Raw Variables

There is another interface for passing data to the model, the
`add_variables()` function, which uses a `dplyr`-like syntax for
choosing variables. The function has two primary arguments: `outcomes`
and `predictors`. These use a selection approach similar to the
tidyselect backend of tidyverse packages to capture multiple selectors
using `c()`.

    lm_wflow <-
      lm_wflow |> 
      remove_formula() |> 
      add_variables(outcomes = Sale_Price, predictors = c(Longitude, Latitude))

    lm_wflow

    ## ══ Workflow ════════════════════════════════════════════════════════════════════
    ## Preprocessor: Variables
    ## Model: linear_reg()
    ## 
    ## ── Preprocessor ────────────────────────────────────────────────────────────────
    ## Outcomes: Sale_Price
    ## Predictors: c(Longitude, Latitude)
    ## 
    ## ── Model ───────────────────────────────────────────────────────────────────────
    ## Linear Regression Model Specification (regression)
    ## 
    ## Computational engine: lm

When the model is fit, the specification assembles these data,
unaltered, into a data frame and passes it to the underlying function:

    fit(lm_wflow, ames_train)

    ## ══ Workflow [trained] ══════════════════════════════════════════════════════════
    ## Preprocessor: Variables
    ## Model: linear_reg()
    ## 
    ## ── Preprocessor ────────────────────────────────────────────────────────────────
    ## Outcomes: Sale_Price
    ## Predictors: c(Longitude, Latitude)
    ## 
    ## ── Model ───────────────────────────────────────────────────────────────────────
    ## 
    ## Call:
    ## stats::lm(formula = ..y ~ ., data = data)
    ## 
    ## Coefficients:
    ## (Intercept)    Longitude     Latitude  
    ##    -302.974       -2.075        2.710

## Creating multiple workflows at once

In some situations, the data require numerous attempts to find an
appropriate model. o address this problem, the workflowset package
creates combinations of workflow components. A list of preprocessors
(e.g., formulas, dplyr selectors, or feature engineering recipe objects
discussed in the next chapter) can be combined with a list of model
specifications, resulting in a set of workflows.

As an example, let’s say that we want to focus on the different ways
that house location is represented in the Ames data. We can create a set
of formulas that capture these predictors:

    # list of possible formules (names = formule)
    locations <- list(
      longitude = Sale_Price ~ Longitude,
      latitude =  Sale_Price ~ Latitude,
      coords =  Sale_Price ~ Latitude + Longitude,
      neighborhood =  Sale_Price ~ Neighborhood
    )

These representations can be crossed with one or more models using the
`workflow_set()`function. We’ll just use the previous linear model
specification to demonstrate:

    library(workflowsets)

    location_models <- workflow_set(preproc = locations, models=list(lm=lm_model))

    location_models

    ## # A workflow set/tibble: 4 × 4
    ##   wflow_id        info             option    result    
    ##   <chr>           <list>           <list>    <list>    
    ## 1 longitude_lm    <tibble [1 × 4]> <opts[0]> <list [0]>
    ## 2 latitude_lm     <tibble [1 × 4]> <opts[0]> <list [0]>
    ## 3 coords_lm       <tibble [1 × 4]> <opts[0]> <list [0]>
    ## 4 neighborhood_lm <tibble [1 × 4]> <opts[0]> <list [0]>

    location_models$info[[1]]

    ## # A tibble: 1 × 4
    ##   workflow   preproc model      comment
    ##   <list>     <chr>   <chr>      <chr>  
    ## 1 <workflow> formula linear_reg ""

    extract_workflow(location_models, id="coords_lm")

    ## ══ Workflow ════════════════════════════════════════════════════════════════════
    ## Preprocessor: Formula
    ## Model: linear_reg()
    ## 
    ## ── Preprocessor ────────────────────────────────────────────────────────────────
    ## Sale_Price ~ Latitude + Longitude
    ## 
    ## ── Model ───────────────────────────────────────────────────────────────────────
    ## Linear Regression Model Specification (regression)
    ## 
    ## Computational engine: lm

Workflow sets are mostly designed to work with resampling. In the
meantime, let’s create model fits for each formula and save them in a
new column called fit. We’ll use basic dplyr and purrr operations:

    location_models <- 
      location_models |> 
      mutate( fit=map(info, ~fit(.x$workflow[[1]], ames_train)) )

    location_models

    ## # A workflow set/tibble: 4 × 5
    ##   wflow_id        info             option    result     fit       
    ##   <chr>           <list>           <list>    <list>     <list>    
    ## 1 longitude_lm    <tibble [1 × 4]> <opts[0]> <list [0]> <workflow>
    ## 2 latitude_lm     <tibble [1 × 4]> <opts[0]> <list [0]> <workflow>
    ## 3 coords_lm       <tibble [1 × 4]> <opts[0]> <list [0]> <workflow>
    ## 4 neighborhood_lm <tibble [1 × 4]> <opts[0]> <list [0]> <workflow>

    location_models$fit[[1]]

    ## ══ Workflow [trained] ══════════════════════════════════════════════════════════
    ## Preprocessor: Formula
    ## Model: linear_reg()
    ## 
    ## ── Preprocessor ────────────────────────────────────────────────────────────────
    ## Sale_Price ~ Longitude
    ## 
    ## ── Model ───────────────────────────────────────────────────────────────────────
    ## 
    ## Call:
    ## stats::lm(formula = ..y ~ ., data = data)
    ## 
    ## Coefficients:
    ## (Intercept)    Longitude  
    ##    -184.396       -2.025

# Evaluating the test set

Once you concluded your model development and have settled on a final
model. There is a convenience function called `last_fit()` that will fit
the model to the entire training set and evaluate id with the testing
set.

    final_lm_res <- lm_wflow |> 
      last_fit(ames_split)

    final_lm_res

    ## # Resampling results
    ## # Manual resampling 
    ## # A tibble: 1 × 6
    ##   splits             id               .metrics .notes   .predictions .workflow 
    ##   <list>             <chr>            <list>   <list>   <list>       <list>    
    ## 1 <split [2342/588]> train/test split <tibble> <tibble> <tibble>     <workflow>

    extract_workflow(final_lm_res)

    ## ══ Workflow [trained] ══════════════════════════════════════════════════════════
    ## Preprocessor: Variables
    ## Model: linear_reg()
    ## 
    ## ── Preprocessor ────────────────────────────────────────────────────────────────
    ## Outcomes: Sale_Price
    ## Predictors: c(Longitude, Latitude)
    ## 
    ## ── Model ───────────────────────────────────────────────────────────────────────
    ## 
    ## Call:
    ## stats::lm(formula = ..y ~ ., data = data)
    ## 
    ## Coefficients:
    ## (Intercept)    Longitude     Latitude  
    ##    -302.974       -2.075        2.710

    collect_metrics(final_lm_res)

    ## # A tibble: 2 × 4
    ##   .metric .estimator .estimate .config             
    ##   <chr>   <chr>          <dbl> <chr>               
    ## 1 rmse    standard       0.164 Preprocessor1_Model1
    ## 2 rsq     standard       0.189 Preprocessor1_Model1

    collect_predictions(final_lm_res) |> slice(1:5)

    ## # A tibble: 5 × 5
    ##   id               .pred  .row Sale_Price .config             
    ##   <chr>            <dbl> <int>      <dbl> <chr>               
    ## 1 train/test split  5.22     2       5.02 Preprocessor1_Model1
    ## 2 train/test split  5.21     4       5.39 Preprocessor1_Model1
    ## 3 train/test split  5.28     5       5.28 Preprocessor1_Model1
    ## 4 train/test split  5.27     8       5.28 Preprocessor1_Model1
    ## 5 train/test split  5.28    10       5.28 Preprocessor1_Model1

# Reference

All code and text came from Max Kuhn and Julia Silge\`s book [Tidy
Modeling with R](https://www.tmwr.org/workflows).
