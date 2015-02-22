# Codebook - Assembled and manipulated data from the UCI HAR Dataset

This information is intended to be supplemental to the data set description for
the original data, which can be found at
http://archive.ics.uci.edu/ml/datasets/Human+Activity+Recognition+Using+Smartphones

### New Data Set Description
The tidySet.txt file, loaded into R using `read.table("tidySet.txt",header=TRUE)`, has 180 observations of 69
variables. This is the result of averaging outcomes of 6 measurements for each of 30 people for a total of 180 average
values. The 69 variables include the subject ID, activity name, set (test or training) and averages of 66 measurement
types.

###### Categorical Variables

`subject`

-integer

The unique identifier given to each study participant. Possible values are 1-30

`activity`

-factor 

The activity being undertaken during measuring. Possible values are:
1. WALKING
2. WALKING_UPSTAIRS
3. WALKING_DOWNSTAIRS
4. SITTING
5. STANDING
6. LAYING

`set`

-factor

The set the observation belongs to: test (54 cases) or training (126 cases)

The features selected for this database come from the accelerometer and gyroscope 3-axial raw signals tAcc-XYZ and tGyro-XYZ. These time domain signals (prefix 't' to denote time) were captured at a constant rate of 50 Hz. Then they were filtered using a median filter and a 3rd order low pass Butterworth filter with a corner frequency of 20 Hz to remove noise. Similarly, the acceleration signal was then separated into body and gravity acceleration signals (tBodyAcc-XYZ and tGravityAcc-XYZ) using another low pass Butterworth filter with a corner frequency of 0.3 Hz. 

Subsequently, the body linear acceleration and angular velocity were derived in time to obtain Jerk signals (tBodyAccJerk-XYZ and tBodyGyroJerk-XYZ). 

Also the magnitude of these three-dimensional signals were calculated using the Euclidean norm (tBodyAccMag, tGravityAccMag, tBodyAccJerkMag, tBodyGyroMag, tBodyGyroJerkMag). 

Finally a Fast Fourier Transform (FFT) was applied to some of these signals producing fBodyAcc-XYZ, fBodyAccJerk-XYZ, fBodyGyro-XYZ, fBodyAccJerkMag, fBodyGyroMag, fBodyGyroJerkMag. (Note the 'f' to indicate frequency domain signals). 


###### Numeric Variables

**All variables are averages across all windows measured for each subject for each activity**

The numeric variables follow a standardized, systematic naming convention.
* The first character (t or f): refers to whether the variable has been Fast Fourier Transformed (f = transformed, t = not transformed)
* BodyAcc or GravityAcc: refers to whether the signal is coming from bodily accelerating or gravitational acceleration
* BodyAccJerk or BodyGyroJerk: values given by contextualize acceleration and gyroscopic measurements in time
* Mag suffix: indicates this value is the Euclidean magnitude of the described measurement
* mean or std: indicates whether this is a mean or std treatment of the data
* X,Y or Z: refers to the axis of movement

tBodyAcc.mean.X  
tBodyAcc.mean.Y  
tBodyAcc.mean.Z  
tBodyAcc.std.X  
tBodyAcc.std.Y  
tBodyAcc.std.Z  
tGravityAcc.mean.X  
tGravityAcc.mean.Y  
tGravityAcc.mean.Z  
tGravityAcc.std.X  
tGravityAcc.std.Y  
tGravityAcc.std.Z  
tBodyAccJerk.mean.X  
tBodyAccJerk.mean.Y  
tBodyAccJerk.mean.Z  
tBodyAccJerk.std.X  
tBodyAccJerk.std.Y  
tBodyAccJerk.std.Z  
tBodyGyro.mean.X  
tBodyGyro.mean.Y  
tBodyGyro.mean.Z  
tBodyGyro.std.X  
tBodyGyro.std.Y  
tBodyGyro.std.Z  
tBodyGyroJerk.mean.X  
tBodyGyroJerk.mean.Y  
tBodyGyroJerk.mean.Z  
tBodyGyroJerk.std.X  
tBodyGyroJerk.std.Y  
tBodyGyroJerk.std.Z  
tBodyAccMag.mean  
tBodyAccMag.std  
tGravityAccMag.mean  
tGravityAccMag.std  
tBodyAccJerkMag.mean  
tBodyAccJerkMag.std  
tBodyGyroMag.mean  
tBodyGyroMag.std  
tBodyGyroJerkMag.mean  
tBodyGyroJerkMag.std  
fBodyAcc.mean.X  
fBodyAcc.mean.Y  
fBodyAcc.mean.Z  
fBodyAcc.std.X  
fBodyAcc.std.Y  
fBodyAcc.std.Z  
