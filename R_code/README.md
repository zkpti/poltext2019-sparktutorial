For the <b>text preprocessing</b> run <a href="https://github.com/zkpti/poltext2019-sparktutorial/blob/master/R_code/quick_and_simple_text_preprocessing.R">quick_and_simple_text_preprocessing.R</a>.

For the <b>text classification with sparklyr</b>:</br>
If you are working on a <b>Google Cloud Dataproc</b> cluster:
You will first have to move the preprocessed dataset to the HDFS. Use the commands from <a href="https://github.com/zkpti/poltext2019-sparktutorial/blob/master/presentation_materials/Hadoop_HDFS_basic_commands">this guide</a> to create the /input folder and then to copy the preprocessed dataset file into the HDFS.
Also create an /eventlog folder on the HDFS for logging purposes.</br>
Go to the terminal tab in the RStudio Server web UI:</br>
```sh
hadoop fs -mkdir /input</br>
hadoop fs -put /home/test/stackexchange_topics_for_poltext2019_preprocessed.csv /input</br>
hadoop fs -mkdir /eventlog</br>
```
You need to use the <a href="https://github.com/zkpti/poltext2019-sparktutorial/blob/master/R_code/sparklyr_example_gc.R">sparklyr_example_gc.R</a> code for the text classification.

If you are working on an <b>Ubuntu 18.04</b> system with a Spark cluster running in local mode:
You can just use the local file system, so you don't have to move stackexchange_topics_for_poltext2019_preprocessed.csv anywhere, but you will also need an eventlog folder for log files. Create one in your spark directory. If you followed the installation instructions form this tutorial then your path is /opt/spark and you need to create the /opt/spark/eventlog folder.
You need to use the <a href="https://github.com/zkpti/poltext2019-sparktutorial/blob/master/R_code/sparklyr_example_ubuntu.R">sparklyr_example_ubuntu.R</a> code for the text classification.

For more on using sparklyr see https://spark.rstudio.com/ (NOTE: while these are very helpful guides, some of the functions are deprecated in the examples, and you will be directed to use the new functions listed in the official R documentation instead: https://cran.r-project.org/web/packages/sparklyr/sparklyr.pdf)

Also, for further study and reference I would like to again recommend <a href="https://therinspark.com/">Mastering Apache Spark with R</a>, which focuses on using sparklyr
