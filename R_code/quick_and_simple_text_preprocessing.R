#### a quick and very simple preprocessing of our text data

# download the starting dataset from https://github.com/zkpti/poltext2019-sparktutorial/blob/master/data/stackexchange_topics_for_poltext2019.csv
# and upload it to your Spark master via the RStudio Server

# load data
data <- read.csv("/home/test/stackexchange_topics_for_poltext2019.csv", sep = ",", stringsAsFactors = FALSE, encoding = "UTF-8")

# let's take a look at the data
View(data)

# we can see we have two text fields "Body" and "Title"
# let's use both for our text classification task
# for that we can create a new column with a concatenation of both
data <- within(data,  text <- paste(Title, Body, sep=" "))
# this produces the same result as calling data$text <- mapply(function(x,y) paste(x, y, sep=" "), x=data$Title, y=data$Body, SIMPLIFY = FALSE)

# keep only columns we need, and rename them
data <- data[,c("text", "Category")]
colnames(data) <- c("text", "cat")

#### clean the text column
# remove html tags
data["text"] <- lapply(data["text"], function(x) gsub("<.*?>", " ", x))
# remove linebreaks
data["text"] <- lapply(data["text"], function(x) gsub("\\n", " ", x))
# remove punctuation
data["text"] <- lapply(data["text"], function(x) gsub("[[:punct:]]", " ", x))
# [:punct:] is the equivalent of [!"\#$%&'()*+,\-./:;<=>?@\[\\\]^_`{|}~] see https://www.regular-expressions.info/posixbrackets.html
# remove numbers
data["text"] <- lapply(data["text"], function(x) gsub("\\d+?", " ", x))
# transformation of text to lowercase and the removal of stopwords will be done with operations in Spark

# save table
write.table(data, file="/home/test/stackexchange_topics_for_poltext2019_preprocessed.csv", sep=";", row.names = FALSE)
