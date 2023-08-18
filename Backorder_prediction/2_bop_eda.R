###############################
# clear the environment
###############################
rm(list = ls())

###############################
# Load libraries
###############################
library(tidyverse)
library(DataExplorer)
library(ggthemes)
library(corrplot)
library(psych) # tetrachoric correlation



#library(GGally)
#library(ROCR)
#library(caret)
#library(DMwR)
#library(ROSE)


###############################
# Get the combined data
###############################
bop <- read.csv("./Data/BOP.csv")


########################################################
# initial examination data - what are we working with
########################################################
dim(bop)
# 1,929,935 data point and 23 variables/features

# visual inspection
View(head(bop, n=100))
# lead_time has missing values
# per_x_month_avg has negative values
# other than that data looks fairly clean

str(bop)
# 7 qualitative variables and 16 quantitative variables

summary(bop)
# national_inv has negative values
# possible influential points (predictors with abnormal values) - there are several
#    quantitative values whose maximum values are a lot higher than the mean

# Quick visual check for missing values using DataExplorer
# Note: double-check by using summary() or str() function
bop %>% plot_missing()

# confirm pct missing values for lead_time
round(( nrow(bop[is.na(bop$lead_time), ]) / nrow(bop)) * 100, digits = 2)
# 5.99% have missing lead_time

# ~6% too much for imputation (5% rule of thumb)
# if lead_time significant, we can revisit how to handle (impute, dummy variable, etc.)

# confirm pct negative values for perf_x_month_avg
round(( nrow(bop[bop$perf_6_month_avg < 0, ]) / nrow(bop)) * 100, digits = 2)
# 7.7% have negative perf_6_month_avg

round(( nrow(bop[bop$perf_12_month_avg < 0, ]) / nrow(bop)) * 100, digits = 2)
# 7.26% have negative perf_12_month_avg

# how many data points with negative perf_6_month_avg have positive perf_12_month_avg
nrow(bop[bop$perf_6_month_avg < 0 & bop$perf_12_month_avg >= 0,])
# 8554 data points

# do same thing with perf_12_month_avg
nrow(bop[bop$perf_12_month_avg < 0 & bop$perf_6_month_avg >= 0,])
# 0 data points


########################################################
# Univariate analysis
########################################################

# does sku contain any duplicated values?
n_distinct(bop$sku) == nrow(bop)
# No, all SKU's appear to be unique.  Each data point is a unique SKU


#Separate numerical and categorical variables
#num_lst <- c(1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 13, 14, 15, 16)
#cat_lst <- c(12, 17, 18, 19, 20, 21, 22)

#Histogram for numerical variables
bop %>% plot_histogram(ggtheme = theme_economist_white(), nrow = 2, ncol = 2)  #only for num features

##Numerical variables: are not normally distributed, e.g.right skewed, left skewed
# Possible influential points, choose models that are robust to these

#Bar plot for categorical variables
bop %>% plot_bar(ggtheme = theme_economist_white(), nrow = 2, ncol = 2)
# Categorical variables: imbalanced data (including response)
# Categorical variables: all are binary categories (Yes, No)



########################################################
# Bivariate analysis
########################################################

# matrix of Pearson correlation coefficients for numeric columns
# Note: Remove SKU column and data points with missing lead_time
cor(  bop[!is.na(bop$lead_time), -1]   %>% select(where(is.numeric)))
corrplot(cor(  bop[!is.na(bop$lead_time), -1]   %>% select(where(is.numeric))))

# perf_6_month_avg and perf_12_month_avg are highly correlated
# In_transit_qty, forecast_n_month, sales_n_month, min_bank: highly correlated with each other



# Tetrachoric Correlation: Used to calculate the correlation between binary categorical variables.
xy <- table(bop$potential_issue, bop$deck_risk) # 0.043
xy <- table(bop$potential_issue, bop$oe_constraint) # 0.39
xy <- table(bop$potential_issue, bop$ppap_risk) # 0.13
xy <- table(bop$potential_issue, bop$stop_auto_buy) # 0.1
xy <- table(bop$potential_issue, bop$rev_stop) # 0.012
xy <- table(bop$deck_risk, bop$oe_constraint) # 0.0062
xy <- table(bop$deck_risk, bop$ppap_risk) # 0.082
xy <- table(bop$deck_risk, bop$stop_auto_buy) # -0.38
xy <- table(bop$deck_risk, bop$rev_stop) # -0.23
xy <- table(bop$oe_constraint, bop$ppap_risk) # 0.11
xy <- table(bop$oe_constraint, bop$stop_auto_buy) # 0.27
xy <- table(bop$oe_constraint, bop$rev_stop) # 0.11
xy <- table(bop$ppap_risk, bop$stop_auto_buy) # -0.11
xy <- table(bop$ppap_risk, bop$rev_stop) # 0.28
xy <- table(bop$stop_auto_buy, bop$rev_stop) # 0.49

tetrachoric(xy)

# no highly correlated categorical values











