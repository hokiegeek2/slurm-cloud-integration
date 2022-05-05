#!/bin/bash

# copy munge.key, set ownership and permissions, and move to config dir
cp /tmp/munge/munge.key /tmp/munge.key
mv /tmp/munge.key /etc/munge/munge.key
chown munge:munge /etc/munge/munge.key
chmod 400 /etc/munge/munge.key

# start munge authorization service
service munge start

# start prometheus-slurm-exporter
./bin/prometheus-slurm-exporter -listen-address 0.0.0.0:9090
