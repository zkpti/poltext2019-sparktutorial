# load necessary packages
# sparklyr allows for the use of dplyr commands in the Spark context, however, they are actually translated into SQL commands to be executed in Spark
# keep in mind that our executors might not even have R installed on them, they are going to execute everything in Spark
library(sparklyr)
library(dplyr)

###############################################################################
# setting up the Spark context 
###############################################################################

# set system environment variables
Sys.setenv(SPARK_HOME = "/opt/spark")
# only need to set JAVA_HOME if you have more than one Java version on your system 
Sys.setenv(JAVA_HOME = "/usr/lib/jvm/java-8-openjdk-amd64")

# create Spark config
# this config list allows us to append further configuration options to the default ones
conf <- spark_config()

# populate Spark config with further settings
# remember these numbers can and should change based on your machines' resources
# the amount of RAM to allocate to the Spark context, remember to leave some memory for the OS itself and other services running on the executor machines
# as a rule of thumb you can allow the Spark context to have somewhere between 0.66-0.75 of the available resources
# in the present case everything is on one local machine, so we are just allocating the available resources from that machine 
conf$spark.executor.memory <- "2GB"
conf$spark.driver.memory <- "2GB"
# same applies to cores/cpus/vcpus, leave some for the OS and other programs too 
conf$spark.executor.cores <- 4
conf$spark.driver.cores <- 1
# this is a setting that is required by some operations to avoid crashing
conf$spark.serializer <- "org.apache.spark.serializer.KryoSerializer"
conf$spark.kryoserializer.buffer <- "256m"
conf$spark.kryoserializer.buffer.max <- "256m" 
# default parallelism based on our executors' cores
conf$spark.default.parallelism <- 4
# you have to create an /eventlog folder in the HDFS for the following settings (for necessary HDFS commands see: https://github.com/zkpti/poltext2019-sparktutorial/blob/master/presentation_materials/Hadoop_HDFS_basic_commands)
conf$spark.eventLog.enabled <- "true"
conf$spark.eventLog.dir <- "<PATH TO YOUR SPARK LIBRARY>/eventlog" # if you followed the cluster setup in this tutorial, this is /opt/spark/eventlog 
conf$spark.history.fs.logDirectory <- "<PATH TO YOUR SPARK LIBRARY>/eventlog" # like above
# this might need to be set to higher values for certain operations
conf$spark.driver.maxResultSize <- "1g"
# we are statically assigning our resources to the Spark context
conf$spark.dynamicAllocation.enabled <- "false"
# when starting the Spark context in local mode from an RStudio Server (as opposed to a simple RStudio) the time to establish the connection takes too long
conf$spark.gateway.start.timeout <- 120

# create the Spark context
# we have to define the master, which points to the Spark cluster manager
# remember we know the address of our master from the initial logfile, see: https://github.com/zkpti/poltext2019-sparktutorial/blob/master/cluster_setup/ubuntu1804-spark-rstudio-server 
# setting the app_name is not necessary, but helps when later checking the logfiles or when taking a look at the Spark web UI
# we pass our list of configurations to the Spark context creator, we can start the Spark context without this as well, in which case it just uses the default values
sc <- spark_connect(master="spark://<name based on your system>:7077",
                    app_name = "sparklyr-test-poltext",
                    config = conf)

# let's see if the Spark context is indeed running
# we can also open the Spark web UI from inside RStudio
spark_web(sc)

###############################################################################
# actual operations start here
###############################################################################

# loading data into the Spark context from the HDFS is the best practice, but in local mode we don't need a HDFS, so we will just load the data from our local file system
stackex_data <- spark_read_csv(sc,
                               "stackex_data",
                               "<PATH WHERE YOU SAVED THIS FILE>/stackexchange_topics_for_poltext2019_preprocessed.csv",
                               header = TRUE, 
                               infer_schema = FALSE, 
                               delimiter = ";",
                               memory = FALSE) # the default is true, meaning the table will be automatically cached, but the table might be too big, or we might just need a few columns, so let's set this to false and cache the table ourselves, if we need to

# to cache the table we can use tbl_cache(sc, <name of table>)
tbl_cache(sc, "stackex_data")

# you can also use the copy_to command (see https://cran.r-project.org/web/packages/sparklyr/sparklyr.pdf) to move a table from the R session to the Spark context
# it is important to keep track of where our different data elements are: they can be on the local disk (of the Spark master/NameNode), the HDFS, the R Session or the Spark context

# check the data
sdf_nrow(stackex_data)
sdf_schema(stackex_data)
head(stackex_data, 
     n=2)

stackex_data %>% 
  group_by(cat) %>%
  summarise(n = n())

# setting up the text preprocessing pipeline
# NOTE: all the ft_ functions correspond to and are wrappers for Spark MLlib functions
preproc_pipeline <- ml_pipeline(sc) %>%
  # tokenize on white space and transform to lowercase, also drop single characters
  ft_regex_tokenizer(input_col = "text",
                     output_col = "words",
                     min_token_length = 2,
                     to_lower_case = TRUE) %>%
  # remove stopwords
  ft_stop_words_remover(input_col = "words", 
                        output_col = "words2",
                        stop_words = ml_default_stop_words(sc, 
                                                           language = "english")) %>%
  # create term frequency vector (drop word if document frequency is less than 5)
  ft_count_vectorizer(input_col = "words2",
                      output_col = "raw_features",
                      min_df = 5) %>%
  # create term frequency weighted by inverse document frequency vector
  ft_idf(input_col = "raw_features",
         output_col = "features")

# call pipeline to transform the data
stackex_data <- ml_fit_and_transform(preproc_pipeline, 
                                     stackex_data)

# check the data again
sdf_nrow(stackex_data)
sdf_schema(stackex_data)
head(stackex_data,
     n=2)

# pipeline for naive bayes multiclass text classification
# NOTE: all the ml_ functions correspond to and are wrappers for Spark MLlib functions, just like the ft_ functions
nb_pipeline <- ml_pipeline(sc) %>%
  # have to change the text labels to numeric for the classifier to be able to handle it
  ft_string_indexer(input_col = "cat",
                    output_col = "label") %>%
  # add the naive bayes classifier to the pipeline
  ml_naive_bayes()

# parameter grid for parameter tuning (this is very small and simple on purpose for the tutorial)
# the name of the list element that corresponds to a pipeline element (in this case "naive_bayes") has to correspond to the element's name from the pipeline, if unsure, check the pipeline contents after setting it up by calling its name, it will print out the pipeline details
# you can add more than one parameter to tune at the same time, note how the parameter name corresponds to the parameter name from the function (check the function documentation, if you are unsure what parameters are available and what they are called: https://cran.r-project.org/web/packages/sparklyr/sparklyr.pdf)
param_grid <- list(
                   naive_bayes = list(
                                      smoothing = c(1.0,
                                                    0.5)
                                     )
                  )

# set up cross validator for parameter tuning
# note: the default metric for ml_multiclass_classification_evaluator is f1, we could also have set metric_name = weightedPrecision, weightedRecall or accuracy
# see https://cran.r-project.org/web/packages/sparklyr/sparklyr.pdf
cv <- ml_cross_validator(sc, 
                         estimator = nb_pipeline,
                         estimator_param_maps = param_grid,
                         evaluator = ml_multiclass_classification_evaluator(sc),
                         num_folds = 3,
                         parallelism = 4 # this is based on the number of cores/cpus/vcpus we have at the disposal of our Spark context
                        )

# create train-test split
split_data <- sdf_random_split(stackex_data,
                               training = 0.7,
                               test = 0.3)

# train the models on the training set
# remember previously we had ml_fit_and_transform, but here we just need our model, so we call ml_fit without transform
cv_model <- ml_fit(cv, 
                   split_data$training)

# check the metrics of the parameter tuning results
ml_validation_metrics(cv_model)

# apply model to the test set (now we call only ml_transform, since our model is already fit)
test_with_pred <- ml_transform(cv_model,
                               split_data$test)

# check evaluation metrics for the test set
ml_multiclass_classification_evaluator(test_with_pred, 
                                       label_col = "label",
                                       prediction_col = "prediction", 
                                       metric_name = "f1")

# create confusion matrix
# first let's create a new column with the numeric predictions translated back to text labels for better readability
# the labels should be extractable with ml_labels(model), but I couldn't get it to work, so I just looked up the path manually
test_with_pred <- ft_index_to_string(test_with_pred,
                                     input_col = "prediction",
                                     output_col = "pred_cat",
                                     labels = cv_model$best_model$stages[[1]]$labels)

# the problem is we can only access the information we want in list form from the Spark dataframe
test_with_pred %>% 
  group_by(cat, 
           pred_cat) %>%
  summarise(n = n()) %>%
  tbl_df %>% 
  print(n = Inf)
# we would need the table function from base or the spread function from tidyr to easily create the table we want, but base or tidyr do not work in the Spark context like dplyr does 

# first we will get our data from the Spark context into the R session running on the Spark master
# there are various ways of moving the data out of the Spark context, the most straightforward is to have the data collected into the R session
# test_df <- sdf_collect(test_with_pred) # this unfortunately might be too big to fit unaltered in the available memory of the Spark master 
# since this can be too much to handle, let's just collect the columns we need for now
test_with_pred_redux <- select(test_with_pred, 
                               cat, 
                               pred_cat)
test_df <- sdf_collect(test_with_pred_redux)

install.packages("tidyr") # we need this for the spread function
library(tidyr)

# now we can use the spread function on our dataframe in the R session to create the confusion matrix 
test_df %>% 
  group_by(cat, 
           pred_cat) %>%
  summarise(n = n()) %>%
  spread(key = cat, 
         value = n)

# now that we are in the R session we could also have just used: table(test_df$cat, test_df$pred_cat)

# but there's an easier way to this, we can include collect() in our pipeline
# so the first part of our pipeline will be executed in the Spark context and the final step in the R session
# (just as it is important to keep track of where our data is, it is also important to keep in mind where we are executing our operations)
test_with_pred %>% 
  group_by(cat, 
           pred_cat) %>%  # this happens in the Spark context
  summarise(n = n()) %>%  # this happens in the Spark context
  collect() %>%           # this is where we move our data from the Spark context to the R session
  spread(key = cat, 
         value = n)       # this happens in the R session

# hmmm, maybe we should check our metrics without the gardening category
test_with_pred %>%
  filter(label != 0) %>%
  ml_multiclass_classification_evaluator(label_col = "label",
                                         prediction_col = "prediction",
                                         metric_name = "f1")

# let's try the linear SVC model
# this model only takes binary classification problems
# let's create a new Spark dataframe and cache it to the Spark context's memory with the compute command
# check the Spark web UI to see that it is really cached
stackex_data_dummy <- stackex_data %>%
  mutate(label = ifelse(cat %in% c("gardening"), 1 , 0)) %>%
  compute("stackex_data_dummy")

# we can also uncache tables if we want to with: tbl_uncache(sc, "name of table to uncache")

# create train-test split for this Spark dataframe (sdf)
split_data_dummy <- sdf_random_split(stackex_data_dummy, 
                                     training = 0.7, 
                                     test = 0.3)

# no fancy pipeline, let's just quickly fit the model
svc_model <- ml_linear_svc(split_data_dummy$training)
# get the predictions for the test set
svc_pred <- ml_transform(svc_model, 
                         split_data_dummy$test)
# and check our metrics
ml_multiclass_classification_evaluator(svc_pred, 
                                       label_col = "label",
                                       prediction_col = "prediction", 
                                       metric_name = "f1")


#### finishing steps ####

# we can also save the data directly from the Spark context to various formats like csv, json, parquet
# NOTE: the default for Spark is to write to distributed storage, so you need a HDFS for these write operations
# if we plan on working with our dataset in a Spark context it is a good idea to use the parquet format instead of csv 
# spark_write_parquet(stackex_data, 
#                     "hdfs://cluster-<THIS NEEDS TO BE CHANGED BASED ON YOUR CLUSTER MASTER NAME>-m:8020/input/stackexchange_topics_for_poltext2019_preproc_TFIDF.parquet",
#                     mode="overwrite")

# to load the same file from parquet format later
# load_parquet_example <- spark_read_parquet(sc, 
#                                            "load_parquet_example", 
#                                            path = "hdfs://cluster-<THIS NEEDS TO BE CHANGED BASED ON YOUR CLUSTER MASTER NAME>-m:8020/input/stackexchange_topics_for_poltext2019_preproc_TFIDF.parquet")

# we can also save and load pipelines and fitted models with ml_save and ml_load
# if we only used sparklyr and dplyr commands in our pipelines, these pipelines and models are going to be language independent and can be loaded into Python and Scala too
# ml_save(nb_pipeline,
#         "/pipelines/nb_pipeline") # this writes to the HDFS and also creates the path in the process if it does not exist yet
# ml_save(cv_model$best_model,
#         "/fitted_models/nb_fitted_model")

# finally, after we finished all our operations we need to close the Spark context
spark_disconnect(sc)
