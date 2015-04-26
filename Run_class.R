library(jsonlite)
library(curl)
library(gzip)
require(curl)
library(reshape2)
library(dplyr)
#1 connect to the zipped file and download data, then close connection
fileurl ="https://d396qusza40orc.cloudfront.net/getdata%2Fprojectfiles%2FUCI%20HAR%20Dataset.zip" 
download.file(fileurl, destfile="projectfile.zip", method="curl")

zipfile ="projectfile.zip"
unzip(zipfile, compressed = 'gzip',  exdir="./Rclass/DataClass/Project")
topdir= "/Users/priyasarathy/Documents/Rclass/DataClass/UCI HAR Dataset"
list.files(topdir)                                                         # checking for the unsipped files within the folder
 
 
#2  read in the Common data files File 1, File 2
dir_act="/Users/priyasarathy/Documents/Rclass/DataClass/UCI HAR Dataset/activity_labels.txt"
dir_fea="/Users/priyasarathy/Documents/Rclass/DataClass/UCI HAR Dataset/features.txt"

activityLabels = read.table(dir_act, col.names= c("ActivityID", "Activity"))
Features = read.table(dir_fea, col.names= c("FeatureNum","Feature"),stringsAsFactors=FALSE)  
#Do not want the character variables to be treated as factors so use stringsAsFactors

#Reformat Features set up is applied to create the final tidy data variable selection.
# Selecting Features associated with a 'mean' or a 'std' measure. In addition reformating the feature names.
Feature_reformat= function(cols) {
  cols= gsub("-mean\\(\\)",".Mean",cols)
  cols=gsub ("-std\\(\\)", ".Std",cols)
  cols=gsub ("-Y", ".Y",cols)
  cols=gsub ("-X", ".X",cols)
  cols=gsub ("-Z", ".Z",cols)
}

#3 Reading "test"  Files  5,6, 7b
test_sub="/Users/priyasarathy/Documents/Rclass/DataClass/UCI HAR Dataset/test/subject_test.txt"
test_x="/Users/priyasarathy/Documents/Rclass/DataClass/UCI HAR Dataset/test/X_test.txt"
test_y="/Users/priyasarathy/Documents/Rclass/DataClass/UCI HAR Dataset/test/y_test.txt"

subjecTest = read.table(test_sub, col.names="Subject")          # Subjects range between 1-30 refer to the experiment participants
Xtest = read.table(test_x)                                       # matrix table of measures of the 561 features, for Test subjects, across 6 different activities
testLabel = read.table(test_y,col.names="ActivityType")          # activity corresponding to row in Xtest
Sample= c("Test")                                                      # created an additional factor variable to ensure that we can distinguish test and train sources. 
                                                                       # appended to each row of the Test Data Table.
XYtest_subject = cbind(Sample,testLabel,subjecTest,Xtest)              # 2947 x (561 +1 +1) Created a data frame for the test sample.

#4 Reading the Train Files 3,4,7a
train_sub="/Users/priyasarathy/Documents/Rclass/DataClass/UCI HAR Dataset/train/subject_train.txt"
train_x="/Users/priyasarathy/Documents/Rclass/DataClass/UCI HAR Dataset/train/X_train.txt"
train_y="/Users/priyasarathy/Documents/Rclass/DataClass/UCI HAR Dataset/train/y_train.txt"


subjecTrain = read.table(train_sub, col.names="Subject")                # Dim[7352,1] 
  
Xtrain = read.table(train_x)                                            # Dim[7352,561]
trainLabel = read.table(train_y,col.names="ActivityType")               # Dim[7352,1]
Sample= c("Train")                                                      # add test and train flag before adding the data together.
XYtrain_subject = cbind(Sample,trainLabel,subjecTrain,Xtrain)           #Dim[7352,1+2+ 561]


#4 Check dimensions, nrows, tables or summary to understand the components of each table noted against each file read
# used nrow(filename), head(filename), tail(filename) table() to validate each file structure and distribution

#5  Merge Test and train
Test_Train = rbind(XYtest_subject,XYtrain_subject)                             # str()  10299x 564
subTestTrain= Test_Train[, 4:564]                                              # subsetting the last 561 variables to apply the mean and std subset
names(subTestTrain)=NULL                                                       # resetting the default labels (V1:V561) to null
# creating an Index vector to subset the required columns 
# the filter index vector is created using pattern match 'grep()'  
automatic= grep("std\\(|mean\\(", Features$Feature)
subTestTrain=subTestTrain[ ,automatic]
 
#6 Applying the Mean and Std filter and description reformats. Project Requirement #2
# Reduced dimensionality from 564 columns to Dim(10299x 66)
  
names(subTestTrain) =
  Feature_reformat(Features$Feature[grep("std\\(|mean\\(", Features$Feature)])
TidyData= cbind(Test_Train[, 1:3],subTestTrain)  
# dim returned 10299x 69  
#( in the discussion forum the typical number of columns is 68 - I have an extra column for retaining the ability to distinguish train vs test records.)

#7 Replacing activity names in the dataset - Project Requirement #3 & #4
add_TidyLabel= merge(TidyData,activityLabels,by.x="ActivityType",by.y="ActivityID")
add_TidyLabel$Activity=gsub("(\\w)(\\w*)","\\U\\1\\L\\2",add_TidyLabel$Activity,perl=TRUE ) # creating a mixed case activity description

TidyData= "/Users/priyasarathy/Documents/Rclass/DataClass/UCI HAR Dataset/TidyData.txt"
write.table(add_TidyLabel,TidyData,sep="\t", row.names=FALSE)


#8 calculating Average values by activities - Project Requirement #5
names(add_TidyLabel)=tolower(names(add_TidyLabel))                         #dim(add_TidyLabel) (10299,70)


# Mixed case is not accepted by melt procedure so revert to lower case
Tidytemp= melt(add_TidyLabel,id=c("sample","subject","activitytype","activity"),na.rm=TRUE)
#'data.frame':  679734 obs. of  6 variables:
# I have used the Wide format to create the final TIDY data, 
# since the focus of the analysis are the 30 Subjects and the activities they have been measured against.
# Visually it is easy to read across and use it to create graphs by column selection.
TidyAvg= dcast(Tidytemp,subject+activity ~ variable, mean)
##  Dim(180,68) Variables ( retained activitytype, sample )

#9 writing out Text file 

TidyAvg= "/Users/priyasarathy/Documents/Rclass/DataClass/UCI HAR Dataset/TidyAvg.txt"
write.table(TidyAvg,TidyAvg,sep="\t", row.names=FALSE)

