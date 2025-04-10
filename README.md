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
-   [Hive Metastore](https://hive.apache.org/docs/latest/adminmanual-metastore-3-0-administration_75978150/) and [HIveServer2](https://hive.apache.org/docs/latest/hiveserver2-overview_65147648/) to manage metadata and support queries to the data lake.

Here is a rough architecture diagram of the CDC:

![Rough architecture diagram](https://i.imgur.com/lCevhii.png)

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

    ```
    CONTAINER ID   IMAGE                               	COMMAND              	CREATED      	STATUS      	PORTS                                                         	NAMES
    038a3f8aea79   confluentinc/cp-schema-registry:7.9.0   "/etc/confluent/dock…"   36 seconds ago   Up 36 seconds   8081/tcp, 0.0.0.0:8181->8181/tcp, [::]:8181->8181/tcp         	schema-registry
    3ad5503ef435   confluentinc/cp-kafka:latest        	"/etc/confluent/dock…"   36 seconds ago   Up 36 seconds   9092/tcp                                                      	kafka
    e823ac4ea104   confluentinc/cp-zookeeper:latest    	"/etc/confluent/dock…"   36 seconds ago   Up 36 seconds   2888/tcp, 0.0.0.0:2181->2181/tcp, [::]:2181->2181/tcp, 3888/tcp   zookeeper
    64e7f9372e01   postgres:17                         	"docker-entrypoint.s…"   36 seconds ago   Up 36 seconds   0.0.0.0:5432->5432/tcp, [::]:5432->5432/tcp                   	source_db
    ```

6.  Run the datalake infrastructure. This will launch Hadoop HDFS, Hive Metastore, Spark and HiveServer2 which are needed to process, store, and query the data once it is captured from the source database:

    ```bash
    docker compose -f datalake-docker-compose.yml up -d
    ```

7.  Verify that all your CDC components up and running by executing the command `docker ps`. Your output should look similar to the following:

    ```
    CONTAINER ID   IMAGE                               	COMMAND              	CREATED      	STATUS                	PORTS                                                                                                    	NAMES
    ade465cb0370   kimanikevin254/hiveserver2:4.0.1    	"sh -c /entrypoint.sh"   50 seconds ago   Up 17 seconds         	0.0.0.0:10000->10000/tcp, [::]:10000->10000/tcp, 9083/tcp, 0.0.0.0:10002->10002/tcp, [::]:10002->10002/tcp   hiveserver2-standalone
    1b11f9812422   apache/hadoop:3.4                   	"/usr/local/bin/dumb…"   50 seconds ago   Up 48 seconds                                                                                                                      	hdfs-datanode1
    d23b29258f58   kimanikevin254/hive-metastore:4.0.0 	"/entrypoint.sh"     	50 seconds ago   Up 17 seconds         	10000/tcp, 0.0.0.0:9083->9083/tcp, [::]:9083->9083/tcp, 10002/tcp                                        	hive-metastore
    621deff23a5d   apache/hadoop:3.4                   	"/bin/bash /namenode…"   50 seconds ago   Up 49 seconds (healthy)   0.0.0.0:9870->9870/tcp, [::]:9870->9870/tcp                                                              	hdfs-namenode
    9d712d0ce380   kimanikevin254/spark:3.5            	"/opt/bitnami/script…"   50 seconds ago   Up 49 seconds         	0.0.0.0:7077->7077/tcp, [::]:7077->7077/tcp, 0.0.0.0:8080->8080/tcp, [::]:8080->8080/tcp                 	spark
    1d7d0bf48a09   mysql:8.0                           	"docker-entrypoint.s…"   50 seconds ago   Up 49 seconds (healthy)   3306/tcp, 33060/tcp                                                                                      	hive-metastore-db
    038a3f8aea79   confluentinc/cp-schema-registry:7.9.0   "/etc/confluent/dock…"   4 minutes ago	Up 4 minutes          	8081/tcp, 0.0.0.0:8181->8181/tcp, [::]:8181->8181/tcp                                                    	schema-registry
    3ad5503ef435   confluentinc/cp-kafka:latest        	"/etc/confluent/dock…"   4 minutes ago	Up 4 minutes          	9092/tcp                                                                                                 	kafka
    e823ac4ea104   confluentinc/cp-zookeeper:latest    	"/etc/confluent/dock…"   4 minutes ago	Up 4 minutes          	2888/tcp, 0.0.0.0:2181->2181/tcp, [::]:2181->2181/tcp, 3888/tcp                                          	zookeeper
    64e7f9372e01   postgres:17                         	"docker-entrypoint.s…"   4 minutes ago	Up 4 minutes          	0.0.0.0:5432->5432/tcp, [::]:5432->5432/tcp
    ```

8.  Create the Debezium Postgres Kafka Connect connector:

    ```bash
    chmod +x scripts/register-postgres-connector.sh && ./scripts/register-postgres-connector.sh
    ```

    Your output should look like this:

    ```json
    {
        "name": "debezium-postgres-connector",
        "config": {
            "connector.class": "io.debezium.connector.postgresql.PostgresConnector",
            "database.hostname": "source_db",
            "database.port": "5432",
            "database.user": "debezium_user",
            "database.password": "debezium_password",
            "database.dbname": "cdc_db",
            "plugin.name": "pgoutput",
            "publication.name": "debezium_pub",
            "table.include.list": "public.orders",
            "topic.prefix": "postgres",
            "key.converter": "io.confluent.connect.avro.AvroConverter",
            "key.converter.schema.registry.url": "http://schema-registry:8081",
            "value.converter": "io.confluent.connect.avro.AvroConverter",
            "value.converter.schema.registry.url": "http://schema-registry:8081",
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

9.  To start ingesting the CDC data into Hudi:

    -   Open a shell inside the `spark` container:

        ```bash
        docker exec -it spark bash
        ```

    -   Execute the following Spark command inside the shell:

        ```bash
        spark-submit \
        --jars $(echo $SPARK_HOME/jars/*.jar | tr ' ' ',') \
        --class org.apache.hudi.utilities.streamer.HoodieStreamer /opt/bitnami/spark/jars/hudi-utilities-slim-bundle_2.12-1.0.1.jar \
        --table-type COPY_ON_WRITE \
        --target-base-path hdfs://hdfs-namenode:9000/warehouse/my-data-lake \
        --target-table orders \
        --source-class org.apache.hudi.utilities.sources.AvroKafkaSource \
        --source-ordering-field id \
        --payload-class org.apache.hudi.common.model.OverwriteWithLatestAvroPayload \
        --schemaprovider-class org.apache.hudi.utilities.schema.SchemaRegistryProvider \
        --min-sync-interval-seconds 10 \
        --op UPSERT \
        --continuous \
        --enable-sync \
        --hoodie-conf bootstrap.servers=kafka:29092 \
        --hoodie-conf schema.registry.url=http://schema-registry:8081 \
        --hoodie-conf hoodie.streamer.schemaprovider.registry.url=http://schema-registry:8081/subjects/postgres.public.orders-value/versions/latest \
        --hoodie-conf hoodie.streamer.source.kafka.topic=postgres.public.orders \
        --hoodie-conf auto.offset.reset=earliest \
        --hoodie-conf hoodie.datasource.write.recordkey.field=id \
        --hoodie-conf hoodie.datasource.write.schema.allow.auto.evolution=true \
        --hoodie-conf hoodie.datasource.hive_sync.mode=hms \
        --hoodie-conf hoodie.datasource.hive_sync.enable=true \
        --hoodie-conf hoodie.datasource.hive_sync.metastore.uris=thrift://hive-metastore:9083 \
        --hoodie-conf hoodie.datasource.meta.sync.enable=true \
        --hoodie-conf hoodie.datasource.hive_sync.auto_create_database=true
        ```

10. To query the data lake using Apache Hive:

    -   Open a shell inside the `hiveserver2-standalone` container:

        ```bash
        docker exec -it hiveserver2-standalone bash
        ```

    -   Launch the `beeline` CLI inside the container:

        ```bash
        beeline -u 'jdbc:hive2://localhost:10000/'
        ```

    -   View all the tables inside the data lake:

        ```bash
        SHOW TABLES;
        ```

        -   You should get the following output::

        ```bash
        +-----------+
        | tab_name  |
        +-----------+
        | orders	|
        +-----------+
        ```

    -   You can also view the actual data in the data lake using the command `SELECT * FROM ORDERS;`:

        ```
        ...
        +-----------------------------+------------------------------+----------------------------+--------------------------------+----------------------------------------------------+------------+---------------------+----------------------+------------------+---------------+----------------+------------------------------+------------------------------+-------------------+
        | orders._hoodie_commit_time  | orders._hoodie_commit_seqno  | orders._hoodie_record_key  | orders._hoodie_partition_path  |              orders._hoodie_file_name              | orders.id  | orders.customer_id  | orders.product_name  | orders.quantity  | orders.price  | orders.status  |      orders.created_at       |      orders.updated_at       | orders.__deleted  |
        +-----------------------------+------------------------------+----------------------------+--------------------------------+----------------------------------------------------+------------+---------------------+----------------------+------------------+---------------+----------------+------------------------------+------------------------------+-------------------+
        | 20250310185706700           | 20250310185706700_0_0        | 1                          |                                | a1ee3e20-0b76-4a02-a5e4-e8bd5fec37e6-0_0-26-22_20250310185706700.parquet | 1          | 1                   | Laptop               | 1                | 1200.00       | confirmed      | 2025-03-10T18:55:37.675526Z  | 2025-03-10T18:55:37.675526Z  | false             |
        | 20250310185706700           | 20250310185706700_0_1        | 2                          |                                | a1ee3e20-0b76-4a02-a5e4-e8bd5fec37e6-0_0-26-22_20250310185706700.parquet | 2          | 2                   | Smartphone           | 2                | 800.00        | shipped        | 2025-03-10T18:55:37.675526Z  | 2025-03-10T18:55:37.675526Z  | false             |
        | 20250310185706700           | 20250310185706700_0_2        | 4                          |                                | a1ee3e20-0b76-4a02-a5e4-e8bd5fec37e6-0_0-26-22_20250310185706700.parquet | 4          | 4                   | Monitor              | 1                | 300.00        | delivered      | 2025-03-10T18:55:37.675526Z  | 2025-03-10T18:55:37.675526Z  | false             |
        | 20250310185706700           | 20250310185706700_0_3        | 3                          |                                | a1ee3e20-0b76-4a02-a5e4-e8bd5fec37e6-0_0-26-22_20250310185706700.parquet | 3          | 3                   | Headphones           | 3                | 150.00        | pending        | 2025-03-10T18:55:37.675526Z  | 2025-03-10T18:55:37.675526Z  | false             |
        | 20250310185706700           | 20250310185706700_0_4        | 5                          |                                | a1ee3e20-0b76-4a02-a5e4-e8bd5fec37e6-0_0-26-22_20250310185706700.parquet | 5          | 5                   | Keyboard             | 2                | 100.00        | canceled       | 2025-03-10T18:55:37.675526Z  | 2025-03-10T18:55:37.675526Z  | false             |
        +-----------------------------+------------------------------+----------------------------+--------------------------------+----------------------------------------------------+------------+---------------------+----------------------+------------------+---------------+----------------+------------------------------+------------------------------+-------------------+
        5 rows selected (6.097 seconds)
        ```

11. You can now make any changes to the data in the source Postgres database and they will always be reflected in the datalake after every 10 seconds.

12. To stop and remove the containers, execute the commands:

    ```bash
    docker compose -f datalake-docker-compose.yml down
    docker compose -f cdc-source-docker-compose.yml down
    ```

13. To remove the network:

    ```bash
    docker network rm cdc-network
    ```
