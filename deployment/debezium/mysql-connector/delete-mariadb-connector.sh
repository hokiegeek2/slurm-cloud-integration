#!/bin/bash

export KAFKA_CONNECT_URL=http://ha-kafka-connector.ace-ventura.net:8083
export KAFKA_CONNECTOR=mariadb-kafka-connector

curl -v -X DELETE $KAFKA_CONNECT_URL/connectors/$KAFKA_CONNECTOR
