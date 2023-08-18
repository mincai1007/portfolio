###############################
# clear the environment
###############################
rm(list = ls())

###############################
# load libraries
###############################
library(stats)

###############################
# Get the combined data
###############################
bop <- read.csv("./Data/BOP.csv")


###############################
# Calculate "daily" velocity
###############################
# We will segment the data by velocity.
# The idea is to target SKU's that similar to each other for the analysis
# This is the same idea as targeted marketing to specific customer segments
# We are using targeted analysis for specific SKU velocity classes

# Initially we used sales_1_month to calculate velocity.
# We decided to pivot to sales_9_month to calculate velocity after reviewing the results
#     when calculating velocity based on sales_1_month.
# Our reasoning includes:
#     1. Most of this company's SKU's are "slow movers", thus more zero values for sales_1_month vs. sales_9_month
#            which leads to less data to calculate velocity
#     3. Typically, velocity is calculated with the largest time value data available (source)


#x <- as.matrix(bop$sales_1_month / 30)
x <- as.matrix(bop$sales_9_month / (30 * 9)) # denominator: thirty days for each of nine months
summary(x)

# scale and center
x <- scale(x)
summary(x)

# create empty matrix to store results
results <- matrix(data = NA, nrow = 0, ncol = 2, dimnames = list (NULL, c("k", "WCSS")))

# run kmeans; try eight clusters
for (k in 1:8) {
  # fit model
  #x_kmeans <- kmeans(x, centers = k, nstart = 25)
  
  # using sales_9_month resulted in warning: Quick-TRANSfer stage steps exceeded maximum
  # set iter.max hyperparameter; set to 20. No more warning
  # Default is 10. Suggests it took more than ten, but less than 20 iterations to converge
  x_kmeans <- kmeans(x, centers = k, nstart = 25, iter.max = 20)
  
  # store the results
  results <- rbind(results, c(k, x_kmeans$tot.withinss))
}

# inspect results
results

# plot results (elbow plot)
plot(results, type="o", main="Elbow-plot", xlab="k", ylab="Total Distance")

# optimal # of clusters is four

# set optimal k
optimal_k = 4

# build optimal kmeans model
#optimal_x_kmeans <- kmeans(x, centers = optimal_k, nstart = 25)
optimal_x_kmeans <- kmeans(x, centers = optimal_k, nstart = 25, iter.max = 20)
optimal_x_kmeans
optimal_x_kmeans$centers

# Sort velocity clusters in decending order by centroid, and assign velocity class
velocity_cluster <- order(optimal_x_kmeans$centers, decreasing = TRUE)
velocity_class <- head(LETTERS, n = optimal_k)
velocity_xwalk <- data.frame(cluster = velocity_cluster,
                             class = velocity_class
                             )

# map velocity class to cluster
map

# copy data
bop2 <- bop

# add cluster vector back to data set
bop2$velocity <- optimal_x_kmeans$cluster
bop2$velocity_val <- optimal_x_kmeans$cluster


# translate velocity
for (i in 1:optimal_k) {
  print(i)

  bop2$velocity <- ifelse(bop2$velocity == i, velocity_xwalk[velocity_xwalk$cluster == i, "class"], bop2$velocity)
  
}


# visual check
optimal_x_kmeans$centers
table(bop2$velocity)
table(bop2$velocity_val)


# Manual assignment
# bop2$velocity <- ifelse(bop2$velocity == 1, "B",
#                         ifelse(bop2$velocity == 2, "C",
#                                ifelse(bop2$velocity == 3, "A",
#                                       ifelse(bop2$velocity == 4, "D","UNK")
#                                )
#                         )
# )


# drop velocity_val col
bop2$velocity_val <- NULL
str(bop2)


# Get sales_9_month means for each velocity class
round(mean(bop2[bop2$velocity == "A", "sales_9_month"]))
round(mean(bop2[bop2$velocity == "B", "sales_9_month"]))
round(mean(bop2[bop2$velocity == "C", "sales_9_month"]))
round(mean(bop2[bop2$velocity == "D", "sales_9_month"]))

# Get number of SKU's for each velocity class
table(bop2$velocity)

# Get backorder flag for each velocity class
table(bop2[bop2$velocity == "A", "went_on_backorder"])
table(bop2[bop2$velocity == "B", "went_on_backorder"])
table(bop2[bop2$velocity == "C", "went_on_backorder"])
table(bop2[bop2$velocity == "D", "went_on_backorder"])









###############################
# SKU
###############################
# SKU's are identifiers that may not have real effect on modeling
# we will omit this for modeling, but we will keep it in the data set
# otherwise, there will be no way for us to know which items to order more
# inventory for


#############################################
# Missing data - lead_time
#############################################
# remove the data points with missing values for lead_time
# according to 5% rule-of-thumb
bop2 <- bop2[!(is.na(bop$lead_time)),]

# confirm (should be 0)
sum(is.na(bop2$lead_time))

#############################################
# Negative values - perf_12_month_avg
#############################################
# Remove data points with a negative perf_12_month_avg
# We will use perf_12_month_avg over perf_6_month_avg because:
#    1. perf_6_month_avg and perf_12_month_avg are highly correlated
#    2. Less data points with negative values for perf_12_month_avg (more usable data)
bop2 <- bop2[bop2$perf_12_month_avg >= 0,]

# confirm (should be 0)
sum(bop2$perf_12_month_avg < 0)


#############################################
# total number of data points removed
#############################################
nrow(bop) - nrow(bop2)
# 140,025

# We are left with ~ 1.8M data points for modeling.

# Done.



# export to csv file
write.csv(x = bop2, 
          file = "./Data/BOP_Velocity.csv",
          quote = FALSE,
          sep = ",",
          na = "",
          row.names = FALSE)


# Confirm Export
export_test <- read.csv("./Data/BOP_Velocity.csv")

# Get sales_9_month means for each velocity class
round(mean(export_test[export_test$velocity == "A", "sales_9_month"]))
round(mean(export_test[export_test$velocity == "B", "sales_9_month"]))
round(mean(export_test[export_test$velocity == "C", "sales_9_month"]))
round(mean(export_test[export_test$velocity == "D", "sales_9_month"]))

# Get number of SKU's for each velocity class
table(export_test$velocity)

# Get backorder flag for each velocity class
table(export_test[export_test$velocity == "A", "went_on_backorder"])
table(export_test[export_test$velocity == "B", "went_on_backorder"])
table(export_test[export_test$velocity == "C", "went_on_backorder"])
table(export_test[export_test$velocity == "D", "went_on_backorder"])



##########################################
# Sample data - for project purposes
##########################################

# create sample data
bop_sample <- head(bop2, n = 2000)


# export to csv file
write.csv(x = bop_sample, 
          file = "./Sample_BOP.csv",
          append = FALSE,
          quote = FALSE,
          sep = ",",
          na = "",
          row.names = FALSE,
          col.names = TRUE,
          qmethod = "double")



