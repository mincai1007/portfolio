###############################
# clear the environment
###############################
rm(list = ls())

###############################
# load libraries
###############################
library(caret)
library(ROCR)
library(dplyr)

###############################
# Get the cleaned data
###############################
data <- read.csv("BOP_Velocity.csv")

# visual check
View(head(data, n = 100))
sum(is.na(data$lead_time))
sum(data$perf_12_month_avg < 0)
summary(data)



###############################
# Filter the data
###############################
# We will target the analysis for the "very slow" velocity (class D) SKU's
# These are the SKU's with which this company appears to have a problem with back orders

# copy the data
data_vel_D <- data

# filter on velocity column
data_vel_D <- data[data$velocity == "D", ]

# confirm filter worked as intended
unique(data_vel_D$velocity)


######################################
# Convert response variable to factor
######################################
data_vel_D$went_on_backorder <- ifelse(data_vel_D$went_on_backorder == "Yes", 1, 0)
data_vel_D$went_on_backorder <- as.factor(data_vel_D$went_on_backorder)

###############################
# Split the unscaled data
###############################
#Set the random number generator seed so that our results are reproducible
set.seed(1)

#Split data into train/validation/test data set 60:20:20
#train
mask_train <- sample(nrow(data_vel_D), size=floor(nrow(data_vel_D)*0.6))
train <- data_vel_D[mask_train, ]

#validation & test
val_test <- data_vel_D[-mask_train, ]
mask_val <- sample(nrow(val_test), size=floor(nrow(val_test)*0.5))
val <- val_test[mask_val, ]
test <- val_test[-mask_val, ]

# The resulting three data sets: train, val, test
# confirm number of data points in each split sums up to original data set
(nrow(train) + nrow(val) + nrow(test)) == nrow(data_vel_D)


# Confirm proportion of SKU's on back order in each split is roughly the same
# as the orignal data

prop.table(table(train$went_on_backorder))        #went_on_backorder 1: 0.75% imbalance data

prop.table(table(val$went_on_backorder))          #went_on_backorder 1: 0.76% imbalance data

prop.table(table(test$went_on_backorder))         #went_on_backorder 1: 0.75% imbalance data

prop.table(table(data_vel_D$went_on_backorder))   #went_on_backorder 1: 0.75% imbalance data

# each of our splits appears to be a good representation of the original data



###############################
# Feature selection
###############################


## forecast_n_month and sales_n_month: highly correlated with each other
## In_transit_qty and min_bank are correlated with each other, as well as with forecast_n_month and sales_n_month.
## perf_6_month_avg, perf_12_month_avg: highly correlated

## Keep perf_12_month_avg (based on reasons discussed in data prep steps)

## Keep one forecast_n_month (a demand factor), drop remaining numerical variables

## Reasoning:  
## national_inv >= forecast_n_month ----> no backorder (supply meets demand)
## national_inv <  forecast_n_month ----> backorder    (supply does not meet demand)

# Out of 23 features, we will proceed with 12 features for modeling:
# national_inv
# lead_time
# forecast_9_month
# potential_issue
# pieces_past_due
# perf_12_month_avg
# local_bo_qty
# deck_risk
# oe_constraint
# ppap_risk
# stop_auto_buy
# rev_stop


###############################
# Fit models
###############################

# Model_A

#Benchmark model: logistic regression for train without standardization
model_0 <- glm(went_on_backorder ~ national_inv + lead_time + 
                 forecast_9_month + potential_issue + pieces_past_due +
                 perf_12_month_avg + local_bo_qty + deck_risk + oe_constraint +
                 ppap_risk + stop_auto_buy + rev_stop,
               data=train, family='binomial')

summary(model_0)


# Using Backward Elimination, we remove features that are not statistically significant
# Remove any feature where p-value p-value > 0.1: rev_stop

model_1 <- glm(went_on_backorder ~ national_inv + lead_time + 
                 forecast_9_month + potential_issue + pieces_past_due +
                 perf_12_month_avg + local_bo_qty + deck_risk + oe_constraint +
                 ppap_risk + stop_auto_buy,
               data=train, family='binomial')

summary(model_1)

# All features now statistically significant

#Make predictions for val with 0.5 as a cutoff
prob_pred <- predict(model_1, val, type='response')
class_pred <- as.factor(ifelse(prob_pred>=0.5, 1, 0))

#Confusion matrix
confusionMatrix(data=class_pred, 
                reference=val$went_on_backorder, 
                positive='1')

#               Reference:
#Prediction     0        1
#0              355026   2704
#1              6        0
##Accuracy : 0.9924, sensitivity/recall : 0, Pos Pred Value/precison: 0


pred <- prediction(prob_pred, val$went_on_backorder)
auc.perf <-  performance(pred, measure = "auc")
auc.perf@y.values
#auc=0.6871678


#-----------------------------------------------------------------------
# Model_B

#Standardize data by scale(): scaled = (original - mean)/sd
# do not scale sku; add sku back in later

train2 <- train[,-1] %>% mutate( across( where(is.numeric) , scale))
summary(train2)

val2 <- val[,-1] %>% mutate( across( where(is.numeric) , scale) )
summary(val2)

test2 <- test[, -1] %>% mutate(across(where(is.numeric), scale))
summary(test2)

#model with standardization
model_s <- glm(went_on_backorder ~ national_inv + lead_time + 
                 forecast_9_month + potential_issue + pieces_past_due +
                 perf_12_month_avg + local_bo_qty + deck_risk + oe_constraint +
                 ppap_risk + stop_auto_buy,
               data=train2, family='binomial')

summary(model_s)

# All features statistically significant

#Make predictions for val with 0.5 as a cutoff
prob_pred <- predict(model_s, val2, type='response')
class_pred <- as.factor(ifelse(prob_pred>=0.5, 1, 0))

#Confusion matrix
confusionMatrix(data=class_pred, 
                reference=val2$went_on_backorder, 
                positive='1')

#               Reference:
#Prediction     0        1
#0              355027   2704
#1              5        0
##Accuracy : 0.9924, sensitivity/recall : 0, Pos Pred Value/precison: 0


pred <- prediction(prob_pred, val2$went_on_backorder)
auc.perf <-  performance(pred, measure = "auc")
auc.perf@y.values
#auc=0.6941933


#-------------------------------------------------
#Deal with imbalanced data

# Model_C

#Upsample the minority class for train
set.seed(1)

train_up <- upSample(x=train[,-ncol(train)], 
                     y=train$went_on_backorder)
table(train_up$Class)  #After upsampling, went_on_backorder -> Class

#Standardize data
train_up2 <- train_up[,-1] %>% mutate(across(where(is.numeric), scale))
summary(train_up2)


model_up <- glm(went_on_backorder ~ national_inv + lead_time + 
                 forecast_9_month + potential_issue + pieces_past_due +
                 perf_12_month_avg + local_bo_qty + deck_risk + oe_constraint +
                 ppap_risk + stop_auto_buy,
               data=train_up2, family='binomial')

summary(model_up)

# All features statistically significant

#Make predictions for val with 0.5 as a cutoff
prob_pred <- predict(model_up, val2, type='response')
class_pred <- as.factor(ifelse(prob_pred>=0.5, 1, 0))

#Confusion matrix
confusionMatrix(data=class_pred, 
                reference=val2$went_on_backorder, 
                positive='1')

#               Reference:
#Prediction     0        1
#0              74448    55
#1              280584   2649
##Accuracy : 0.2155, sensitivity/recall : 0.979660, Pos Pred Value/precison: 0.009353


pred <- prediction(prob_pred, val2$went_on_backorder)
auc.perf <-  performance(pred, measure = "auc")
auc.perf@y.values
#auc=0.7171368


#----------------------------------------------------------------------
# Model_D

#Downsample the majority class for train
set.seed(1)

train_down <- downSample(x=train[,-ncol(train)], 
                         y=train$went_on_backorder)

table(train_down$Class)  #After upsampling, went_on_backorder -> Class

#Standardize data
train_down2 <- train_down[,-1] %>% mutate(across(where(is.numeric), scale))


model_down <- glm(went_on_backorder ~ national_inv + lead_time + 
                  forecast_9_month + potential_issue + pieces_past_due +
                  perf_12_month_avg + local_bo_qty + deck_risk + oe_constraint +
                  ppap_risk + stop_auto_buy,
                data=train_down2, family='binomial')

summary(model_down)

# Remove statistically insignificant features: p-value > 0.1: oe_constraint

model_down2 <- glm(went_on_backorder ~ national_inv + lead_time + 
                    forecast_9_month + potential_issue + pieces_past_due +
                    perf_12_month_avg + local_bo_qty + deck_risk +
                    ppap_risk + stop_auto_buy,
                  data=train_down2, family='binomial')

summary(model_down2)


# All features statistically significant

#Make predictions for val with 0.5 as a cutoff
prob_pred <- predict(model_down2, val2, type='response')
class_pred <- as.factor(ifelse(prob_pred>=0.5, 1, 0))

#Confusion matrix
confusionMatrix(data=class_pred, 
                reference=val2$went_on_backorder, 
                positive='1')

#               Reference:
#Prediction     0        1
#0              102255  147
#1              252777  2557
##Accuracy : 0.293, sensitivity/recall : 0.945636, Pos Pred Value/precison: 0.010014


pred <- prediction(prob_pred, val2$went_on_backorder)
auc.perf <-  performance(pred, measure = "auc")
auc.perf@y.values
#auc=0.7215234


###############################
# Model selection
###############################

# The goal is to produce a model that reliably predicts true positives and avoids false negatives,
# while also minimizing false positives as much as possible. 
# Modeling will focus on a producing high sensitivity (TP/(TP+FN)) and acceptable levels of precision (TP/(TP+FP)).

# So the best model so far we choose is the Model_C with a sensitivity/recall of 0.979660, 

model_optimal <- glm(went_on_backorder ~ national_inv + lead_time + 
                  forecast_9_month + potential_issue + pieces_past_due +
                  perf_12_month_avg + local_bo_qty + deck_risk + oe_constraint +
                  ppap_risk + stop_auto_buy,
                data=train_up2, family='binomial')

summary(model_optimal)

# All features statistically significant

#Make predictions for val with 0.5 as a cutoff
prob_pred <- predict(model_optimal, val2, type='response')

class_pred <- as.factor(ifelse(prob_pred>=0.5, 1, 0))
confusionMatrix(data=class_pred, 
                reference=val2$went_on_backorder, 
                positive='1')

#               Reference:
#Prediction     0        1
#0              74448    55
#1              280584   2649
##Accuracy : 0.2155, sensitivity/recall : 0.979660, Pos Pred Value/precison: 0.009353

#Make predictions for val with 0.6 as a cutoff

class_pred <- as.factor(ifelse(prob_pred>=0.6, 1, 0))
confusionMatrix(data=class_pred, 
                reference=val2$went_on_backorder, 
                positive='1')
##Accuracy : 0.5645, sensitivity/recall: 0.730769, Pos Pred Value/precison: 0.012583

#Make predictions for val with 0.7 as a cutoff

class_pred <- as.factor(ifelse(prob_pred>=0.7, 1, 0))
confusionMatrix(data=class_pred, 
                reference=val2$went_on_backorder, 
                positive='1')
##Accuracy : 0.882, sensitivity/recall: 0.299926, Pos Pred Value/precison: 0.019715

###############################
# Model assessment
###############################

prob_pred <- predict(model_optimal, test2, type='response')

class_pred <- as.factor(ifelse(prob_pred>=0.5, 1, 0))
confusionMatrix(data=class_pred, 
                reference=test2$went_on_backorder, 
                positive='1')

#               Reference:
#Prediction     0        1
#0              140506    309
#1              214538   2383
##Accuracy : 0.3994, sensitivity/recall : 0.885215, Pos Pred Value/precison: 0.010986

#ROC
#Create a prediction object
pred_test_up <- prediction(prob_pred, test2$went_on_backorder)
perf <- performance(pred, 'tpr', 'fpr')
plot(perf, colorize = T)

#Calculate AUC
auc.perf <-  performance(pred_test_up, measure = "auc")
auc.perf@y.values
#auc=0.7061277



###############################
# Post-analysis
###############################

coef <- coef(model_optimal)
coef

ind <- order(abs(model_optimal$coefficients), decreasing=FALSE)
model_optimal$coefficients[ind]

#Top 5 important features: national_inv(-), potential_issue, oe_constraint, forecast_9_month, deck_risk(-)

Importance <- model_optimal$coefficients[ind]
feature_imp <- as.data.frame(Importance)
feature_imp
Feature <- row.names(feature_imp)
Feature

par(mar=c(6,10,2,2))
barplot(height=feature_imp$Importance, names.arg=Feature, las=1, horiz=TRUE, xlab='Importance')


#--------------------------------------------------------------------End
