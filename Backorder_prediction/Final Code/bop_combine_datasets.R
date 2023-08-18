###############################
# clear the environment
###############################

rm(list = ls())


###############################
# Training data set
###############################

# load the training data
bop_train <- read.csv("./Training_BOP.csv")

# remove the last row (this is row number indicator, not a data point)
bop_train <- bop_train[-nrow(bop_train),]



###############################
# Testing data set
###############################

# load the testing data
bop_test <- read.csv("./Testing_BOP.csv")

# remove the last row (this is row number indicator, not a data point)
bop_test <- bop_test[-nrow(bop_test),]



##########################################
# Combine training and testing data sets
##########################################

bop_all <- rbind(bop_train, bop_test)



##########################################
# Export data
##########################################

# export to csv file
write.csv(x = bop_all, 
          file = "./BOP.csv",
          append = FALSE,
          quote = FALSE,
          sep = ",",
          na = "",
          row.names = FALSE,
          col.names = TRUE,
          qmethod = "double")
