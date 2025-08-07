FROM apache/spark:3.5.0-scala2.12-java11-ubuntu

# Set the SPARK_HOME environment variable
ENV SPARK_HOME=/opt/spark

# Download the necessary JARs and place them in the Spark jars directory
RUN wget -P ${SPARK_HOME}/jars https://repo1.maven.org/maven2/org/apache/hudi/hudi-utilities-slim-bundle_2.12/1.0.2/hudi-utilities-slim-bundle_2.12-1.0.2.jar \
    && wget -P ${SPARK_HOME}/jars https://repo1.maven.org/maven2/org/apache/hudi/hudi-spark3.5-bundle_2.12/1.0.2/hudi-spark3.5-bundle_2.12-1.0.2.jar \
    && wget -P ${SPARK_HOME}/jars https://packages.confluent.io/maven/io/confluent/kafka-avro-serializer/7.8.0/kafka-avro-serializer-7.8.0.jar \
    && wget -P ${SPARK_HOME}/jars https://repo1.maven.org/maven2/org/apache/hudi/hudi-hive-sync/1.0.1/hudi-hive-sync-1.0.1.jar \
    && wget -P ${SPARK_HOME}/jars https://packages.confluent.io/maven/io/confluent/kafka-schema-registry-client/7.9.0/kafka-schema-registry-client-7.9.0.jar \
    && wget -P ${SPARK_HOME}/jars https://packages.confluent.io/maven/io/confluent/kafka-protobuf-provider/7.9.0/kafka-protobuf-provider-7.9.0.jar \
    && wget -P ${SPARK_HOME}/jars https://packages.confluent.io/maven/io/confluent/kafka-schema-serializer/7.9.0/kafka-schema-serializer-7.9.0.jar \
    && wget -P ${SPARK_HOME}/jars https://packages.confluent.io/maven/io/confluent/kafka-json-schema-provider/7.9.0/kafka-json-schema-provider-7.9.0.jar