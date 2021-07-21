#!/bin/bash

# set munge.key ownership and permissions
sudo mv /tmp/munge/munge.key /etc/munge/
sudo chown munge:munge /etc/munge/munge.key
sudo chmod 400 /etc/munge/munge.key

# start munge authorization service
sudo service munge start

jupyter lab --no-browser --allow-root --ip=0.0.0.0 --NotebookApp.token='' --NotebookApp.password=''

tail -f /dev/null