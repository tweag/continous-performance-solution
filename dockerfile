# Use an official OpenJDK base image
FROM openjdk:17.0.2-jdk-slim

# Set environment variables
ARG JMETER_VERSION=5.6.2
ARG JMETER_HOME="/opt/jmeter/apache-jmeter-${JMETER_VERSION}" 
ARG CURL_OPTS="--connect-timeout 10 --retry 5 --retry-delay 1 --retry-max-time 60" 
ARG JMETER_CMD_RUNNER_PATH="${JMETER_HOME}/lib/cmdrunner-2.3.jar" 
ARG JMETER_CMD_RUNNER_URL="http://search.maven.org/remotecontent?filepath=kg/apc/cmdrunner/2.3/cmdrunner-2.3.jar"
ARG JMETER_PLUGINS_DOWNLOAD_URL="https://repo1.maven.org/maven2"
ARG JMETER_PLUGINS_FOLDER="${JMETER_HOME}/lib/ext"
ARG JMETER_BIN="${JMETER_HOME}/bin"

#java env variables
ENV GC_ALGO="-XX:+UseG1GC -XX:MaxGCPauseMillis=50 -XX:G1ReservePercent=10"
ENV JVM_ARGS="-Xms1g -Xmx1g -verbose:gc -Xloggc:${JMETER_HOME}/jmeter_GC.log"

# Install necessary packages
RUN apt-get update && \
    apt-get upgrade -y && \
    apt-get install -y wget coreutils unzip bash curl apt-utils zip jq && \
    apt-get update && apt-get install -y procps && rm -rf /var/lib/apt/lists/*

# Download and install JMeter
RUN mkdir -p ${JMETER_HOME} && \
    wget -O /tmp/apache-jmeter-${JMETER_VERSION}.zip https://archive.apache.org/dist/jmeter/binaries/apache-jmeter-${JMETER_VERSION}.zip && \
    unzip -oq /tmp/apache-jmeter-${JMETER_VERSION}.zip -d /opt/jmeter && \
    rm /tmp/apache-jmeter-${JMETER_VERSION}.zip

# Add JMeter Plugins Manager - Manages installation of additional plugins
RUN wget -O ${JMETER_PLUGINS_FOLDER}/jmeter-plugins-manager-1.10.jar \
    ${JMETER_PLUGINS_DOWNLOAD_URL}/kg/apc/jmeter-plugins-manager/1.10/jmeter-plugins-manager-1.10.jar

# Download and install JMeter Command-Line Runner
RUN wget -O ${JMETER_CMD_RUNNER_PATH} ${JMETER_CMD_RUNNER_URL}

# Set environment variables for JMeter and JMeter Plugins Manager
ENV CMD_RUNNER_PATH=${JMETER_CMD_RUNNER_PATH}
#ENV JMETER_HOME=${JMETER_HOME}

# Set the working directory
WORKDIR ${JMETER_HOME}

# Install Jmeter Plugins
# Download the Dummy Sampler Plugin JAR file and place it in the lib/ext directory
RUN wget -O ${JMETER_PLUGINS_FOLDER}/dummy-sampler-0.2.jar \
    ${JMETER_PLUGINS_DOWNLOAD_URL}/kg/apc/jmeter-plugins-dummy/0.2/jmeter-plugins-dummy-0.2.jar

# JMeter Plugins Functions - Provides additional functions for scripting
RUN wget -O ${JMETER_PLUGINS_FOLDER}/jmeter-plugins-functions-2.2.jar \
    ${JMETER_PLUGINS_DOWNLOAD_URL}/kg/apc/jmeter-plugins-functions/2.2/jmeter-plugins-functions-2.2.jar
# JMeter Plugins Custom Thread Groups - Adds custom thread groups to JMeter
RUN wget -O ${JMETER_PLUGINS_FOLDER}/jmeter-plugins-casutg-2.10.jar \
    ${JMETER_PLUGINS_DOWNLOAD_URL}/kg/apc/jmeter-plugins-casutg/2.10/jmeter-plugins-casutg-2.10.jar 
# JMeter Plugins Throughput Shaping Timer - Adds throughput shaping timer to JMeter
RUN wget -O ${JMETER_PLUGINS_FOLDER}/jmeter-plugins-tst-2.6.jar \
    ${JMETER_PLUGINS_DOWNLOAD_URL}/kg/apc/jmeter-plugins-tst/2.6/jmeter-plugins-tst-2.6.jar  
# JMeter Plugins Random CSV Data Set - Allows using random data from CSV files
RUN wget -O ${JMETER_PLUGINS_FOLDER}/jmeter-plugins-random-csv-data-set-0.8.jar \
    ${JMETER_PLUGINS_DOWNLOAD_URL}/com/blazemeter/jmeter-plugins-random-csv-data-set/0.8/jmeter-plugins-random-csv-data-set-0.8.jar
# MySQL Connector Java - JDBC driver for connecting to MySQL databases
RUN wget -O ${JMETER_HOME}/lib/mysql-connector-java-5.1.49.jar \
    ${JMETER_PLUGINS_DOWNLOAD_URL}/mysql/mysql-connector-java/5.1.49/mysql-connector-java-5.1.49.jar 
# JMeter Plugins Functions (ZIP) - Additional functions for scripting
RUN wget -O ${JMETER_HOME}/jpgc-functions-2.1.zip \
    https://jmeter-plugins.org/files/packages/jpgc-functions-2.1.zip
RUN unzip -o ${JMETER_HOME}/jpgc-functions-2.1.zip \
    && rm ${JMETER_HOME}/jpgc-functions-2.1.zip

# Add JMeter and JMeter Plugins Manager to the PATH
ENV PATH ${JMETER_BIN}:${PATH}

#modify user.properties
#sets the default delimiter for saving services in JMeter to a tab
RUN printf '\njmeter.save.saveservice.default_delimiter=%s\n' "\t" >> ${JMETER_BIN}/user.properties
#sets the exit check pause in JMeter to 30,000 milliseconds
RUN printf '\njmeter.exit.check.pause=30000\n' >> ${JMETER_BIN}/user.properties
#enables the saving of cookies in the Cookie Manager
RUN printf '\nCookieManager.save.cookies=true\n' >> ${JMETER_BIN}/user.properties
#disables the checking of cookies in the Cookie Manager
RUN printf '\nCookieManager.check.cookies=false\n' >> ${JMETER_BIN}/user.properties
#sets various properties related to the Apache HttpClient
RUN printf '\nhttpclient.reset_state_on_thread_group_iteration=false\nhttpclient4.validate_after_inactivity=66600\nhttpclient4.time_to_live=70000\nhttpclient4.idletimeout=15000\nhttpclient4.retrycount=1\nhttps.default.protocol=TLSv1.3\n' "\t" >> ${JMETER_BIN}/jmeter.properties

# Print JMeter version for verification
RUN jmeter -v

# Create a directory for JMeter test plan files
RUN mkdir -p /jmeter-scripts

