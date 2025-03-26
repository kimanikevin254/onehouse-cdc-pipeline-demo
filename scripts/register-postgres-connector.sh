#!/bin/bash

curl \
  --location 'http://localhost:8083/connectors/' \
	--header 'Content-Type: application/json' \
	--data '{
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
      "transforms.unwrap.drop.tombstones": false,
      "transforms.unwrap.delete.handling.mode": "rewrite",
      "decimal.handling.mode": "string"
    }
}'