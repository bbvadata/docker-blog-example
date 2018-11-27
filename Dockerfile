FROM debian:jessie

MAINTAINER EDGAR PEREZ SAMPEDRO <edgar.perez.sampedroi.contractor@bbva.com>

#JAVA
# auto validate license
RUN echo oracle-java8-installer shared/accepted-oracle-license-v1-1 select true | /usr/bin/debconf-set-selections

# update repos
RUN echo "deb http://ppa.launchpad.net/webupd8team/java/ubuntu trusty main" | tee /etc/apt/sources.list.d/webupd8team-java.list
RUN echo "deb-src http://ppa.launchpad.net/webupd8team/java/ubuntu trusty main" | tee -a /etc/apt/sources.list.d/webupd8team-java.list
RUN apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys EEA14886
RUN apt-get update

# install java
RUN apt-get install oracle-java8-installer -y

RUN apt-get clean

# ANACONDA3
RUN apt-get update && \
    apt-get install -y curl build-essential libpng12-dev libffi-dev  && \
    apt-get clean && \
    rm -rf /var/tmp /tmp /var/lib/apt/lists/*

ENV CONDA_DIR="/root/anaconda3" 
ENV PATH="$CONDA_DIR/bin:$PATH"
RUN curl -sSL -o installer.sh https://repo.continuum.io/archive/Anaconda3-4.4.0-Linux-x86_64.sh && \
    bash /installer.sh -b -f && \
    rm /installer.sh

ENV PATH "$CONDA_DIR/bin:$PATH"

# SPARK
ARG SPARK_ARCHIVE=https://d3kbcqa49mib13.cloudfront.net/spark-2.2.0-bin-hadoop2.7.tgz
RUN curl -s $SPARK_ARCHIVE | tar -xz -C /usr/local/

ENV SPARK_HOME /usr/local/spark-2.2.0-bin-hadoop2.7
ENV PATH $PATH:$SPARK_HOME/bin

# CUSTOM CONDA-ENV
RUN conda create -n pyspark python=3.5
RUN ["/bin/bash", "-c", "source activate pyspark; apt-get install libstdc++; conda install jupyter;conda install ipykernel; python -m ipykernel install --user --name pyspark --display-name pyspark; source deactivate"]
ENV PATH "$CONDA_DIR/envs/pyspark/bin:$PATH"

# JUPYTER CONFIG
COPY jupyter_notebook_config.py /root/.jupyter/
EXPOSE 8888

# CODE DIR 
COPY notebooks /notebooks

# ENVIRONMENT VARIABLES
ENV JAVA_HOME /usr/lib/jvm/java-8-oracle
ENV PYSPARK_PYTHON /root/anaconda3/envs/pyspark/bin/python 
# ENV PYSPARK_DRIVER_PYTHON_OPTS notebook
# ENV PYSPARK_DRIVER_PYTHON jupyter
ENV PYTHONPATH /usr/local/spark-2.2.0-bin-hadoop2.7/python/lib/py4j-0.10.4-src.zip:/usr/local/spark-2.2.0-bin-hadoop2.7/python:PYSPARK_DRIVER_PYTHON=ipython

WORKDIR "/notebooks"
CMD ["/bin/bash", "-c", "jupyter notebook --allow-root"]
