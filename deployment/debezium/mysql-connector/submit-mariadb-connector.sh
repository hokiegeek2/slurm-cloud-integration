#!/bin/bash

export KAFKA_CONNECTOR_URL=http://ha-kafka-connector.ace-ventura.net:8083

curl -H 'Content-Type: application/json' -X POST $KAFKA_CONNECTOR_URL/connectors \
 -d '{
        "name": "mariadb-kafka-connector",
        "config": {
          "connector.class": "io.debezium.connector.mysql.MySqlConnector",
          "connector.adapter": "mariadb",
          "tasks.max": 1,
          "database.hostname": "slurm-mariadb.kafka",
          "database.port": "3306",
          "database.user": "slurm",
          "database.password": "slurmdbpass",
          "database.dbname": "slurm_acct_db",
          "database.server.id": 11291997,
          "database.server.name": "slurm_maria_db",
          "database.protocol": "jdbc:mariadb",
          "database.jdbc.driver": "org.mariadb.jdbc.Driver",
          "database.history.kafka.bootstrap.servers": "PLAINTEXT://ha-kafka-controller-headless.kafka:9092",
          "database.history.kafka.topic": "database_history_slurm_acct_db",
          "database.include.list": "slurm_acct_db",
          "include.schema.changes": "true",
          "name": "mariadb-kafka-connector",
          "schema.history.internal.kafka.bootstrap.servers": "PLAINTEXT://ha-kafka-controller-headless.kafka:9092", 
          "schema.history.internal.kafka.topic": "schema-history.slurm_acct_db",
          "signal.kafka.bootstrap.servers": "PLAINTEXT://ha-kafka-controller-headless.kafka:9092",
          "topic.prefix": "slurmdb"
        }
     }'