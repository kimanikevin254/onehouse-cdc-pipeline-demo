# Implementing CDC with Apache Hudi for Real-Time Data Lake Updates

This repository demonstrates how to implement Change Data Capture (CDC) with Apache Hudi to enable real-time updates in a data lake.

## Architecture Overview

The CDC pipeline includes the following components:

-   [PostgreSQL](https://www.postgresql.org/) as the transactional source database
-   [Debezium](https://debezium.io/) to capture real-time changes from the source database
-   [Kafka](https://kafka.apache.org/) as the message broker for streaming change events
-   [Hadoop Distributed File System HDFS (HDFS)](https://hadoop.apache.org/docs/r1.2.1/hdfs_design.html) as the destination data lake storage
-   [Apache Spark](https://spark.apache.org/) to process and write data into the data lake using Hudi Streamer
-   [Apache Hudi](https://hudi.apache.org/) to manage incremental data updates
-   [Hive Metastore](https://hive.apache.org/docs/latest/adminmanual-metastore-3-0-administration_75978150/) to manage metadata.
-   [Spark SQL](https://spark.apache.org/sql/) to query the datalake

Here is an architecture diagram of the CDC pipeline:

![Architecture diagram](https://i.imgur.com/ijASYFL.png)

## Prerequisites

To run this project locally, you need to have the following:

-   [Docker](https://docs.docker.com/engine/install/) and [Docker Compose](https://docs.docker.com/compose/install/) installed on your local machine
-   [Git CLI](https://git-scm.com/downloads) installed on your local machine

## Getting Started

1.  Clone the project:

    ```bash
    git clone --single-branch -b solution https://github.com/kimanikevin254/onehouse-cdc-pipeline-demo.git
    ```

2.  `cd` into the project directory:

    ```bash
    cd onehouse-cdc-pipeline-demo
    ```

3.  Create a Docker network that your containers will use to communicate:

    ```bash
    docker network create cdc-network
    ```

4.  Run the CDC source infrastructure. This includes source PostgreSQL database (where the transactional data is stored), along with Kafka, Zookeeper, and Schema Registry:

    ```bash
    docker compose -f cdc-source-docker-compose.yml up -d
    ```

5.  Verify your CDC source components are up running by executing the command `docker ps`. Your output should look similar to the following:

    ```bash
    CONTAINER ID   IMAGE                                   COMMAND                  CREATED          STATUS          PORTS                                                             NAMES
    ab780e51b0c2   confluentinc/cp-kafka:7.3.2             "/etc/confluent/dock…"   23 minutes ago   Up 23 minutes   0.0.0.0:9092->9092/tcp, [::]:9092->9092/tcp                       hudi-cdc-kafka
    96f23539cbc6   confluentinc/cp-schema-registry:7.9.0   "/etc/confluent/dock…"   23 minutes ago   Up 23 minutes   8081/tcp, 0.0.0.0:8181->8181/tcp, [::]:8181->8181/tcp             hudi-cdc-schema-registry
    2076f34dacf7   confluentinc/cp-zookeeper:latest        "/etc/confluent/dock…"   23 minutes ago   Up 23 minutes   2888/tcp, 0.0.0.0:2181->2181/tcp, [::]:2181->2181/tcp, 3888/tcp   hudi-cdc-zookeeper
    bb47bce4e6a0   postgres:17                             "docker-entrypoint.s…"   23 minutes ago   Up 23 minutes   0.0.0.0:5432->5432/tcp, [::]:5432->5432/tcp                       hudi-cdc-source-db
    ```

6.  Run the datalake infrastructure. This will launch Hadoop HDFS, Hive Metastore and Spark which are needed to process, store, and query the data once it is captured from the source database:

    ```bash
    docker compose -f datalake-docker-compose.yml up -d
    ```

    If you have run this before and your Hive Metastore has some data, use the commands below instead to avoid running into any issues (such as the Hive Metastore not starting properly):

    ```bash
    chmod +x ./scripts/reset-hive-metastore-db.sh && ./scripts/reset-hive-metastore-db.sh
    ```

7.  Verify that all your CDC components up and running by executing the command `docker ps`. Your output should look similar to the following:

    ```bash
    CONTAINER ID   IMAGE                                       COMMAND                  CREATED          STATUS                    PORTS                                                                                      NAMES
    81dc5a23aa7a   onehouse-cdc-pipeline-demo-hive-metastore   "/entrypoint.sh"         29 seconds ago   Up 7 seconds              10000/tcp, 0.0.0.0:9083->9083/tcp, [::]:9083->9083/tcp, 10002/tcp                          hudi-cdc-hive-metastore
    22fea1242bd4   apache/hadoop:3.4                           "/usr/local/bin/dumb…"   29 seconds ago   Up 28 seconds                                                                                                        hudi-cdc-hdfs-datanode1
    5b01c1f0ee45   mysql:8.0                                   "docker-entrypoint.s…"   29 seconds ago   Up 28 seconds (healthy)   3306/tcp, 33060/tcp                                                                        hudi-cdc-hive-metastore-db
    e61498fba83e   apache/hadoop:3.4                           "/bin/bash /namenode…"   29 seconds ago   Up 28 seconds (healthy)   0.0.0.0:9000->9000/tcp, [::]:9000->9000/tcp, 0.0.0.0:9870->9870/tcp, [::]:9870->9870/tcp   hudi-cdc-hdfs-namenode
    a38fa43dac25   onehouse-cdc-pipeline-demo-spark            "/opt/entrypoint.sh …"   29 seconds ago   Up 28 seconds             0.0.0.0:7077->7077/tcp, [::]:7077->7077/tcp, 0.0.0.0:8080->8080/tcp, [::]:8080->8080/tcp   hudi-cdc-spark
    ab780e51b0c2   confluentinc/cp-kafka:7.3.2                 "/etc/confluent/dock…"   12 minutes ago   Up 12 minutes             0.0.0.0:9092->9092/tcp, [::]:9092->9092/tcp                                                hudi-cdc-kafka
    96f23539cbc6   confluentinc/cp-schema-registry:7.9.0       "/etc/confluent/dock…"   12 minutes ago   Up 12 minutes             8081/tcp, 0.0.0.0:8181->8181/tcp, [::]:8181->8181/tcp                                      hudi-cdc-schema-registry
    2076f34dacf7   confluentinc/cp-zookeeper:latest            "/etc/confluent/dock…"   12 minutes ago   Up 12 minutes             2888/tcp, 0.0.0.0:2181->2181/tcp, [::]:2181->2181/tcp, 3888/tcp                            hudi-cdc-zookeeper
    bb47bce4e6a0   postgres:17                                 "docker-entrypoint.s…"   12 minutes ago   Up 12 minutes             0.0.0.0:5432->5432/tcp, [::]:5432->5432/tcp                                                hudi-cdc-source-db
    ```

8.  Building a Kafka Connect image for Debezium and run the container:

    ```bash
    docker build -t my-debezium-connect:3.0 ./debezium-connect

    docker run -it --rm --name connect \
        --network cdc-network \
        -e GROUP_ID=1 \
        -e CONFIG_STORAGE_TOPIC=my_connect_configs \
        -e OFFSET_STORAGE_TOPIC=my_connect_offsets \
        -e KEY_CONVERTER=io.confluent.connect.avro.AvroConverter \
        -e VALUE_CONVERTER=io.confluent.connect.avro.AvroConverter \
        -e CONNECT_KEY_CONVERTER_SCHEMA_REGISTRY_URL=http://hudi-cdc-schema-registry:8081 \
        -e CONNECT_VALUE_CONVERTER_SCHEMA_REGISTRY_URL=http://hudi-cdc-schema-registry:8081 \
        -e BOOTSTRAP_SERVERS=hudi-cdc-kafka:29092 \
        -p 8083:8083 my-debezium-connect:3.0
    ```

9.  Create the Debezium Postgres Kafka Connect connector:

    ```bash
    curl \
        --location 'http://localhost:8083/connectors/' \
        --header 'Content-Type: application/json' \
        --data '{
            "name": "debezium-postgres-connector",
            "config": {
                "connector.class": "io.debezium.connector.postgresql.PostgresConnector",
                "database.hostname": "hudi-cdc-source-db",
                "database.port": "5432",
                "database.user": "debezium_user",
                "database.password": "debezium_password",
                "database.dbname": "cdc_db",
                "plugin.name": "pgoutput",
                "publication.name": "debezium_pub",
                "table.include.list": "public.orders",
                "topic.prefix": "postgres",
                "key.converter": "io.confluent.connect.avro.AvroConverter",
                "key.converter.schema.registry.url": "http://hudi-cdc-schema-registry:8081",
                "value.converter": "io.confluent.connect.avro.AvroConverter",
                "value.converter.schema.registry.url": "http://hudi-cdc-schema-registry:8081",
                "transforms": "unwrap",
                "transforms.unwrap.type": "io.debezium.transforms.ExtractNewRecordState",
                "transforms.unwrap.drop.tombstones": false,
                "transforms.unwrap.delete.handling.mode": "rewrite",
                "decimal.handling.mode": "string"
            }
        }'
    ```

    Your output should look like this:

    ```json
    {
        "name": "debezium-postgres-connector",
        "config": {
            "connector.class": "io.debezium.connector.postgresql.PostgresConnector",
            "database.hostname": "hudi-cdc-source-db",
            "database.port": "5432",
            "database.user": "debezium_user",
            "database.password": "debezium_password",
            "database.dbname": "cdc_db",
            "plugin.name": "pgoutput",
            "publication.name": "debezium_pub",
            "table.include.list": "public.orders",
            "topic.prefix": "postgres",
            "key.converter": "io.confluent.connect.avro.AvroConverter",
            "key.converter.schema.registry.url": "http://hudi-cdc-schema-registry:8081",
            "value.converter": "io.confluent.connect.avro.AvroConverter",
            "value.converter.schema.registry.url": "http://hudi-cdc-schema-registry:8081",
            "transforms": "unwrap",
            "transforms.unwrap.type": "io.debezium.transforms.ExtractNewRecordState",
            "transforms.unwrap.drop.tombstones": "false",
            "transforms.unwrap.delete.handling.mode": "rewrite",
            "decimal.handling.mode": "string",
            "name": "debezium-postgres-connector"
        },
        "tasks": [],
        "type": "source"
    }
    ```

10. Start ingesting the CDC data into Hudi:

    ```bash
    docker exec -it hudi-cdc-spark /opt/spark/bin/spark-submit \
        --class org.apache.hudi.utilities.streamer.HoodieStreamer \
        /opt/spark/jars/hudi-utilities-bundle_2.12-1.0.2.jar \
        --table-type COPY_ON_WRITE \
        --target-base-path hdfs://hudi-cdc-hdfs-namenode:9000/warehouse/my-data-lake \
        --target-table orders \
        --source-class org.apache.hudi.utilities.sources.AvroKafkaSource \
        --source-ordering-field updated_at \
        --schemaprovider-class org.apache.hudi.utilities.schema.SchemaRegistryProvider \
        --min-sync-interval-seconds 10 \
        --op UPSERT \
        --continuous \
        --enable-sync \
        --hoodie-conf bootstrap.servers=hudi-cdc-kafka:29092 \
        --hoodie-conf schema.registry.url=http://hudi-cdc-schema-registry:8081 \
        --hoodie-conf hoodie.streamer.schemaprovider.registry.url=http://hudi-cdc-schema-registry:8081/subjects/postgres.public.orders-value/versions/latest \
        --hoodie-conf hoodie.streamer.source.kafka.topic=postgres.public.orders \
        --hoodie-conf auto.offset.reset=earliest \
        --hoodie-conf hoodie.datasource.write.recordkey.field=id \
        --hoodie-conf hoodie.datasource.write.schema.allow.auto.evolution.column.drop=true \
        --hoodie-conf hoodie.datasource.hive_sync.mode=hms \
        --hoodie-conf hoodie.datasource.hive_sync.enable=true \
        --hoodie-conf hoodie.datasource.hive_sync.metastore.uris=thrift://hudi-cdc-hive-metastore:9083 \
        --hoodie-conf hoodie.datasource.meta.sync.enable=true \
        --hoodie-conf hoodie.datasource.hive_sync.auto_create_database=true
    ```

11. To query the data lake using Spark SQL:

    -   Launch the Spark SQL CLI:

        ```bash
        docker exec -it hudi-cdc-spark /opt/spark/bin/spark-sql --conf spark.sql.cli.print.header=true
        ```

    -   View all the tables inside the data lake:

        ```bash
        SHOW TABLES;
        ```

        -   You should get the following output::

        ```
        namespace       tableName       isTemporary
        orders
        ```

    -   You can also view the actual data in the data lake using the command `SELECT id, product_name, quantity, price, status, updated_at FROM orders;`:

        ```
        id      product_name    quantity        price   status  updated_at
        1       Laptop  1       1200.00 confirmed       2025-08-06T19:08:14.247179Z
        2       Smartphone      2       800.00  shipped 2025-08-06T19:08:14.247179Z
        4       Monitor 1       300.00  delivered       2025-08-06T19:08:14.247179Z
        3       Headphones      3       150.00  pending 2025-08-06T19:08:14.247179Z
        5       Keyboard        2       100.00  canceled        2025-08-06T19:08:14.247179Z
        ```

12. You can now make any changes to the data in the source Postgres database and they will always be reflected in the datalake after every 10 seconds.

13. To stop and remove the containers, execute the commands:

    ```bash
    docker compose -f datalake-docker-compose.yml down
    docker compose -f cdc-source-docker-compose.yml down
    ```

14. To remove the network:

    ```bash
    docker network rm cdc-network
    ```
