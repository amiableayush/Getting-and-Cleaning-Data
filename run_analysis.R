# Download the dataset in commpressed form
# unzip it 
# create a directory called"project" in your working directory
# put the unzipped file inside the project directory
library(data.table)# assuming u have the package installed
library(reshape2)

# store the path to the dateset in the variable called pathin
pathin<-file.path(getwd(),"project","UCI HAR Dataset")

# read the subject_train.txt and subject_test.txt
subjecttrain<-read.table(file.path(pathin,"train","subject_train.txt"))
subjecttest<-read.table(file.path(pathin,"test","subject_test.txt"))

# read the activity_train and activity_test.txt data
activitytrain<-read.table(file.path(pathin,"train","y_train.txt"))
activitytest<-read.table(file.path(pathin,"test","y_test.txt"))

# read the x_test.txt and x_train.txt data
x_test<-data.table(read.table(file.path(pathin,"test","X_test.txt")))
x_train<-data.table(read.table(file.path(pathin,"train","X_train.txt")))
# merge the rows of the subjecttrain and subjecttest data
subject<-rbind(subjecttrain,subjecttest)

#merge the rows of the activitytrain and activitytest data
activity<-rbind(activitytrain,activitytest)

#merge the rows of the x_train and x_test data
readings<-rbind(x_train,x_test)

# combine the columns of the above 3 tables to form a unified table
# i have given the name of the table as "merge"
merge<-cbind(subject,activity,readings)

#changing the names of the first two columns of merge to make it more descriptive
colnames(merge)[1:2]<-c("subject_id","activity_id")

# converting the dataframe into data.table class to allow easier manipulations
merge<-data.table(merge)


# reading the features.txt into a datatable 
features<-fread(file.path(pathin,"features.txt"))

#changing the names of the columns to make it more descriptive
names(features)<-c("sr_no","name")

# filtering the rows of the features table with "name" column having regex mean() or std()
features<-features[grep("mean\\(\\)|std\\(\\)",features$name),]

# prefixing the letter V to sr_no so that they can match column names in merge table
# it will help in subsetting as shown in the following comments
features$sr_no<-paste0("V",features$sr_no)
merge<-merge[,c("subject_id","activity_id",features$sr_no),with=F]

#reading the labels of six activities 
activity_labels<-fread(file.path(pathin,"activity_labels.txt"))
#changing columnames to more descriptive ones and to create a common column
names(activity_labels)<-c("activity_id","activity_name")

#merging merge table and activity_labels table by activity_id
merge<-merge(merge,activity_labels,by="activity_id")

#setting key as subject_id,activiy_id,activity_name
setkey(merge,subject_id,activity_id,activity_name)

#melting the merge table to convert it into tall and narrow form
# this will also help in finding out mean with respect to different feature_id in variable
merge<-melt(merge,id=key(merge))
merge<-data.table(merge)

#setting proper names for establishing common names between tables merge and features
setnames(features,"sr_no","feature_id")
setnames(merge,"variable","feature_id")

#merging by feature_id so as to label feature_id in merge table with feature_name in feature table
merge<-merge(merge,features,by="feature_id")
setnames(merge,"name","feature_name")
setkey(merge,subject_id,activity_name,feature_name)

#creating tidy data  
tidy<-merge[,list(count=.N,average=mean(value)),by=key(merge)]
View(tidy)

# writing the dataset into a tab delimited text file
path<-file.path(pathin,"tidydataset.txt")
write.table(tidy,path,quote=FALSE,sep="\t",row.names=FALSE)
