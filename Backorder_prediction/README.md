## What the project does
The objective of our project is to build a model that predicts which items are likely to go on backorder using this (or similar) data.

## Why this is useful
By leveraging these predictions, the retailer can implement a targeted replenishment strategy for the items that have a high likelihood of going on backorder.

## Data Source

The data was obtained from Kaggle.

It is the *Back Order Prediction Dataset*  

Source URL: https://www.kaggle.com/datasets/gowthammiryala/back-order-prediction-dataset

## Data Files

The original data set from Kaggle consists of two files:
* *Training_BOP.csv* - the training set
* *Testing_BOP.csv* - the testing set

### Combining the data files

These two datasets (the training set and testing set) were combined into one data set, called *BOP.csv*.

R was used to combine the two data sets.

The code used can be found in the file *bop_combine_datasets.R*.

### Feature Engineering

The project team decided to segment the SKU's into classes based on sales velocity.

SKU's were classified into one of four groups: fast, medium, slow, and super-slow (represented by the letters A, B, C, D, respectively)

A data set with this new *velocity* variable was created called *BOP_Velocity.csv.*

It consists of the exact same data as found in the file *BOP.csv*, with the addition of the *velocity* variable.

### Dropbox Links to Full Data Sets

[Training_BOP.csv](https://www.dropbox.com/s/7u0c6epkyf9mpn0/Training_BOP.csv?dl=0)  
[Testing_BOP.csv](https://www.dropbox.com/s/dit6n70ai1srzgc/Testing_BOP.csv?dl=0)  
[BOP.csv](https://www.dropbox.com/s/n0fnz5xwgrtzl5i/BOP.csv?dl=0)  
[BOP_Velocity.csv](https://www.dropbox.com/scl/fi/iw7rtm15gyiinkyez4p67/BOP_Velocity.csv?rlkey=4lo1zudte61eo93qk7v7x3k0y&dl=0)

## File Contents

The original training data file consists of 1,687,860 data points.

The original testing data file contains 242,075 data points.

The combined data file contains 1,929,935 data points.

The number, order, and names of the variables are the same in all three files.

There are 24 variables total: 23 predictor variables and 1 response variable.

The variable *velocity* was created and added by this project team; is is not found in the original data sets

The meta data is as follows:

| Name               | Data Type | Description                                                                                    | Notes             |
|--------------------|-----------|------------------------------------------------------------------------------------------------|-------------------|
| sku                | chr       | stock keeping unit code                                                                        |                   |
| national_inv       | int       | current inventory level of component                                                           |                   |
| lead_time          | int       | time from replenishment order placement to delivery                                            |                   |
| in_transit_qty     | int       | quantity in transit                                                                            |                   |
| forecast_3_month   | int       | forecast sales for the next 3 months                                                           |                   |
| forecast_6_month   | int       | forecast sales for the next 6 months                                                           |                   |
| forecast_9_month   | int       | forecast sales for the next 9 months                                                           |                   |
| sales_1_month      | int       | sales quantity for the prior 1 months                                                          |                   |
| sales_3_month      | int       | sales quantity for the prior 3 months                                                          |                   |
| sales_6_month      | int       | sales quantity for the prior 6 months                                                          |                   |
| sales_9_month      | int       | sales quantity for the prior 9 months                                                          |                   |
| min_bank           | int       | minimum recommended amount in stock                                                            | safety stock      |
| potential_issue    | chr       | indictor variable noting potential issue with item                                             |                   |
| pieces_past_due    | int       | parts overdue from source                                                                      |                   |
| perf_6_month_avg   | dbl       | source performance in the last 6 months                                                        |                   |
| perf_12_month_avg  | dbl       | source performance in the last 12 months                                                       |                   |
| local_bo_qty       | int       | amount of stock orders overdue                                                                 |                   |
| deck_risk          | chr       | indicates if there is risk associated with item being stored in open area                      |                   |
| oe_constraint      | chr       | indicates if there is order engineering constraint for item                                    |                   |
| ppap_risk          | chr       | indicates if item requires Production Part Approval Process (PPAP)                             |                   |
| stop_auto_buy      | chr       | indicates if inventory reaches specific quantity, generate replenishment order                 |                   |
| rev_stop           | chr       | indicates if the item has had its revenue stopped                                              |                   |
| went_on_back_order | chr       | indicates if item went on backorder                                                            | response variable |
| velocity           | chr       | indicates the velocity class of item                                                           | not in original data |

### Instructions to run code

R version 4.3.0 (2023-04-21 ucrt) -- "Already Tomorrow"

R Libraries used:
- caret
- corrplot
- DataExplorer
- dplyr (also included in tidyverse)
- ggthemes
- psych
- ROCR
- stats
- tidyverse

Steps:

1. Retreive the data files _Training_BOP.csv_ and _Testing_BOP.csv_. ([Dropbox Links to Full Data Sets](https://github.gatech.edu/MGT-6203-Summer-2023-Canvas/Team-27/tree/main/Data#dropbox-links-to-full-data-sets))
2. Run the R script [bop_combine_datasets.R](<Final Code/bop_combine_datasets.R>).  Use the two files from Step 1 as the inputs.
3. The output of _bop_combine_datasets.R_ will be a combined data set called _BOP.csv_.
4. Run the R script [bop_eda.R](<Final Code/bop_eda.R>).  Use the file _BOP.csv_ from Step 3 as the input.
5. Insights gained from exploratory data analysis guide data preparation; these steps are carried out in _bop_data_prep.R_ script.
6. Run the R script [bop_data_prep.R](<Final Code/bop_data_prep.R>).  Use the file _BOP.csv_ from Step 3 as the input.
7. The output of _bop_data_prep.R_ will be a data file called _BOP_Velocity.csv_.
8. Run the R script [bop_modeling.R](<Final Code/bop_modeling.R>).  Use the file _BOP_Velocity.csv_ from Step 7 as the input.
