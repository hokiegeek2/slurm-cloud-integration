# MySqlConnector for MariaDB Change Data Capture (CDC)

## Scope of MariaDB Change Data Control

MariaDB writes row-level changes and DDL statements to its binlog, which the MySQLConnector subsequently reads to parse and update the in-memory representation of each table’s schema. This is used to understand the table structure at the time of each operation, which produces row-level database events.

## MySqlConnector Resiliency

Importantly, MySqlConnector records all DDL statements along with their position in the binlog in a separate database history. Consequently, when the MySqlConnector restarts (after a possible crash or graceful shutdown), it continues reading the binlog from that specific point in time.

## Initial CDC Snapshot

When the Debezium MySqlConnector is first started, it performs an initial consistent snapshot of the targe database. Note, If the MySqlConnector fails, stops, or is rebalanced while making the initial snapshot, it creates a new snapshot once restarted. Once that intial snapshot is complete, the Debezium MySqlConnector restarts from the same position in the binlog so it does not miss any updates.

# Prepare MySQL/MariaDB for CDC

As detailed in this excellent [MySqlConnecter User Guide](https://access.redhat.com/documentation/en-us/red_hat_integration/2020.q1/html/debezium_user_guide/debezium-connector-for-mysql#binlog-configuration-properties-mysql-connector), here are the instructions for preparing MySQL or MariaDB for CDC.

## Create User with Required Permissions

Importantly, the MySqlConnector user (for example, slurm) must have permissions to access from within the host Kubernetes cluster. Accordingly, at a minimum, the slurm user _cannot have just permissions from localhost_. The example below uses the slurm user:

```
# Create MySql/MariaDB if non-slurm user 
CREATE USER 'slurm'@'%' IDENTIFIED BY 'password';

# Grant permissions required for CDC via binlog reads
GRANT SELECT, RELOAD, SHOW DATABASES, REPLICATION SLAVE, REPLICATION CLIENT ON *.* TO slurm@'%' IDENTIFIED BY '<user password>';

# Finalize user permissions
FLUSH PRIVILEGES;
```

## Enable MySQL/MariaDB binlog for Debezium

### Check log-bin Status

```
SELECT variable_value as "BINARY LOGGING STATUS (log-bin) ::"
FROM information_schema.global_variables WHERE variable_name='log_bin';
```

If it reads OFF, the MySQL/MariaDB configuration needs to be updated:

```
SELECT variable_value as "BINARY LOGGING STATUS (log-bin) ::"
    -> FROM information_schema.global_variables WHERE variable_name='log_bin';
+------------------------------------+
| BINARY LOGGING STATUS (log-bin) :: |
+------------------------------------+
| OFF                                |
+------------------------------------+
```

### Configuring MySQL/MariaDB for binlog Access

Update the /etc/mysql/mysql.conf or /etc/mysql/mariadb.conf as follows:

```
bind_address      = <Slurm MariaDB host IP>
server_id         = <unique number>
log_bin           = mysql-bin
binlog_format     = ROW
binlog_row_image  = FULL
expire_logs_days  = 10
```

Restart the MySQL service and re-run the following SQL query to ensure log-bin is on:

```
SELECT variable_value as "BINARY LOGGING STATUS (log-bin) ::"
    -> FROM information_schema.global_variables WHERE variable_name='log_bin';
+------------------------------------+
| BINARY LOGGING STATUS (log-bin) :: |
+------------------------------------+
| ON                                |
+------------------------------------+
```

# Deploy Debezium Kafka Connect

## Helm Chart

The snapp-incubator [debezezium-chart](https://github.com/snapp-incubator/debezium-chart) is an excellent open-source Helm chart for deploying the Debezium Kafka Connect server to Kubernetes. 

Since the snapp-incubator Helm chart is not in any Helm repository, the chart github repo must be cloned to enable Helm deployment via local directory.

## values.yaml

An example debezium-chart values.yaml file is as follows:

```
connect:
  replicaCount: 1

  image:
    repository: quay.io/debezium/connect
    pullPolicy: Always
    tag: "1.9"

  service:
    type: LoadBalancer
    port: 8083
    protocol: TCP
    name: http

  ingress:
    enabled: false

  autoscaling:
    enabled: false

  resources:
    limits:
      cpu: 4000m
      memory: 4Gi
    requests:
      cpu: 2000m
      memory: 2Gi

  env:
    - name: BOOTSTRAP_SERVERS
      value: "PLAINTEXT://ha-kafka-controller-headless.kafka:9092"
    - name: GROUP_ID
      value: "1"
    - name: CONFIG_STORAGE_TOPIC
      value: debezium_connect_configs
    - name: OFFSET_STORAGE_TOPIC
      value: debezium_connect_offsets
    - name: STATUS_STORAGE_TOPIC
      value: debezium_connect_statuses

ui:
  enabled: true
  replicaCount: 1
  imagePullSecrets: [ ]

  image:
    repository: debezium/debezium-ui
    pullPolicy: Always
    tag: "1.9"

  service:
    type: LoadBalancer
    port: 8080
    protocol: TCP
    name: http

  ingress:
    enabled: false
    router: private
    host: DEBEZIUM_UI_HOST_ADDRESS

  autoscaling:
    enabled: false

  resources:
    limits:
      cpu: 2000m
      memory: 2Gi
    requests:
      cpu: 1000m
      memory: 1Gi

  env:
    - name: KAFKA_CONNECT_URIS
      value: "http://ha-connector-debezium-connect.kafka:8083"
```

## Important Configuration Details

### KAFKA_CONNECT_URIS

The KAFKA_CONNECT_URIS env variable must be set to the name of Helm deployment, the value of which is generated from the Helm install name plus 'debezium-connect'. In this example, the Helm install name is ha-connector, so the KAFKA_CONNECT_URIS value is ha-connector-debezium-connect.

# Prepare Kubernetes for MySqlConnector CDC

## Background

Since the Slurm MariaDB instance is hosted outside of Kubernetes, a Kubernetes external service which is composed of a Kubernetes [Service](https://kubernetes.io/docs/concepts/services-networking/service/) and either an [Endpoints](https://kubernetes.io/docs/concepts/services-networking/service/#endpoints) or [EndpointSlices](https://kubernetes.io/docs/concepts/services-networking/service/#endpointslices) object. 

## Examples

The [mariadb-service-endpointslice.yaml](mariadb-service-endpointslice.yaml) and [mariadb-service-endpoints.yaml](mariadb-service-endpoints.yaml) files provide examples for Service-EndpointSlices and ServiceEndpoints, respectively.

# Deploy MySqlConnector for MariaDB CDC

The example submit script [submit-fds-mariadb-connector.sh](submit-fds-mariadb-connector.sh) is as follows. Note, in this example the external mariadb service is named slurm-mariadb and is deployed in the kafka namespace.

```
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
```

# Delete MySqlConnector for MariaDB CDC

The example delete script [delete-fds-mariadb-connector.sh](delete-fds-mariadb-connector.sh) is as follows:

```
#!/bin/bash

export KAFKA_CONNECT_URL=http://ha-kafka-connector.ace-ventura.net:8083
export KAFKA_CONNECTOR=mariadb-kafka-connector

curl -v -X DELETE $KAFKA_CONNECT_URL/connectors/$KAFKA_CONNECTOR
```