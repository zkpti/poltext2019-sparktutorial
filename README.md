# POLTEXT 2019 Tutorial D: Text Mining and Machine Learning with Apache Spark 

&#8226; <a href="https://github.com/zkpti/poltext2019-sparktutorial/blob/master/presentation_materials/Text_Mining_and_Machine_Learning_with_Apache_Spark.pdf">Introductory presentation</a>

&#8226; <a href="https://github.com/zkpti/poltext2019-sparktutorial/blob/master/cluster_setup/Setting_up_Google_Cloud_Spark_cluster.pdf">Illustrated guide to set up a Google Cloud Dataproc cluster with RStudio Server and sparklyr</a> 

&#8226; <a href="https://github.com/zkpti/poltext2019-sparktutorial/blob/master/cluster_setup/GC_Spark_cluster_withRStudServ_setup.sh">Script for setting up RStudio Server, sparklyr and starting adding 'test' user on a Google Cloud Dataproc cluster</a>
</br><b>And the same script condensed into a one line command, for quick reference:</b></br>
sudo apt-get update && sudo apt-get install -y r-base r-base-dev libcurl4-openssl-dev libssl-dev libxml2-dev gdebi-core && wget https://download2.rstudio.org/server/debian9/x86_64/rstudio-server-1.2.1335-amd64.deb && sudo gdebi --n rstudio-server-1.2.1335-amd64.deb && sudo su - -c "R -e \\"install.packages('sparklyr', repos = 'http://cran.us.r-project.org')\"" && sudo adduser test

&#8226; <a href="https://github.com/zkpti/poltext2019-sparktutorial/blob/master/cluster_setup/ubuntu1804-spark-rstudio-server">Instructions for setting up a Spark cluster in local mode with RStudio Server on an Ubuntu 18.04 system</a>

&#8226; <a href="https://github.com/zkpti/poltext2019-sparktutorial/blob/master/presentation_materials/Hadoop_HDFS_basic_commands">A simple guide to using the most essential commands for the Hadoop Distributed File System (HDFS) on our Spark cluster</a>

&#8226; <a href="https://github.com/zkpti/poltext2019-sparktutorial/tree/master/R_code">An example of using sparklyr for text classification, with information on configuring, starting and stopping the Spark context</a>

&#8226; For source and license information about the data used in this tutorial <a href="https://github.com/zkpti/poltext2019-sparktutorial/tree/master/data">see</a>.

<b>IMPORTANT:</b> When running a Spark cluster in the Google Cloud Dataproc environment for short intervals at a time, and deleting the cluster each time after use, like in this tutorial, or when using Spark in local mode on a secured machine, security will not necessarily be a major issue. However, it is important to understand that <b>"Security in Spark is OFF by default."</b> This means that any serious work with a Spark cluster should include enabling the security features, such as web UI user authentication, see https://spark.apache.org/docs/latest/security.html for details.

&#8226; For further study and reference I would like to recommend the book I wish I had found earlier when preparing for this tutorial: <a href="https://therinspark.com/">Mastering Apache Spark with R</a> by Javier Luraschi, Kevin Kuo, Edgar Ruiz

<i>Acknowledgements:</br>
Thank you to <a href="https://www.poltextconference.org/">POLTEXT 2019</a> and <a href="https://www.waseda.jp/inst/wias/en/">The Waseda Institute for Advanced Study, Waseda University</a> for making this tutorial possible.</br>
A speacial thank you to the team ‒ and especially Enikő Nagy and István Pintye ‒ of the Laboratory of Parallel and Distributed Systems at the Hungarian Academy of Sciences Institute for Computer Science and Control (<a href="https://www.sztaki.hu/en/science/departments/lpds">MTA SZTAKI LPDS</a>) for their generous help and support in setting up and operating an Apache Spark cluster in the <a href="https://cloud.mta.hu/">MTA Cloud</a> using the <a href="http://occopus.lpds.sztaki.hu/">Occopus cluster deployment tool</a>, which has proven invaluable not only for our research, but also for learning about Apache Spark.</i>
