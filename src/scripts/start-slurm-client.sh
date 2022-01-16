#!/bin/bash

# copy munge.key, set ownership and permissions, and move to config dir
sudo cp /tmp/munge/munge.key /tmp/munge.key
sudo mv /tmp/munge.key /etc/munge/munge.key
sudo chown munge:munge /etc/munge/munge.key
sudo chmod 400 /etc/munge/munge.key

# start munge authorization service
sudo service munge start

# set ownership/permissions for slurmdbd.conf and the jwt key
sudo chmod 600 /etc/slurm/slurmdbd.conf
sudo chown slurm:slurm /etc/slurm/slurmdbd.conf
sudo chown slurm:slurm /etc/slurm/jwt_hs256.key
sudo chmod 600 /etc/slurm/jwt_hs256.key
