require(dplyr)

# Read in all of the files
y_test <- readLines("./test/y_test.txt")
x_test <- read.table("./test/X_test.txt")
subject_test <- readLines("./test/subject_test.txt")
y_train <- readLines("./train/y_train.txt")
x_train <- read.table("./train/X_train.txt")
subject_train <- readLines("./train/subject_train.txt")
activity_labs <- read.table("activity_labels.txt")
features <- read.table("features.txt")

testlabs <- rbind(set = rep("test",length(y_test)), subject = subject_test, activity=y_test)
# create a "set" variable and bind all of the per observation variables together
labnum <- 1:nrow(testlabs)
# store the number of column names that will not come from measurement variables
test.df <- cbind(t(testlabs), x_test)
# bind observation labels as row descriptors to the measurement information
colnames(test.df) <- c(colnames(test.df)[labnum], make.names(features[,2]))
# label all columns appropriately

trainlabs <- rbind(set = rep("train",length(y_train)), subject = subject_train, activity=y_train)
train.df <- cbind(t(trainlabs), x_train)
colnames(train.df) <- c(colnames(train.df)[labnum], make.names(features[,2]))
# do the same for the training set

complete.df <- rbind(test.df, train.df)
# combine test and training sets
extMeanStd <- grep("\\.mean\\.|\\.std.\\.", colnames(complete.df))
# identify variables which have mean or std dev values
SamsungMeanStd <- complete.df[,c(labnum, extMeanStd)]
# subset to create a data set of only mean and std dev values
SamsungMeanStd$activity <- factor(SamsungMeanStd$activity, labels=activity_labs[,2])
# replace activity numbers with meaningful labels

colnames(SamsungMeanStd) <- sub("\\.\\.|\\.\\.\\.", "\\.", colnames(SamsungMeanStd))
colnames(SamsungMeanStd) <- sub("\\.$", "", colnames(SamsungMeanStd))
colnames(SamsungMeanStd) <- sub("BodyBody","Body", colnames(SamsungMeanStd))
# improve variable label readability by removing multiple periods, trailing
# periods and typos

tidyMeansSet <- SamsungMeanStd %>% group_by(subject,activity, set) %>% summarise_each(funs(mean))
write.table(tidyMeansSet, "tidySet.txt", row.name=F)
