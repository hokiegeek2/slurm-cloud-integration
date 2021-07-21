#!/bin/bash

# copy munge.key, set ownership and permissions, and move to config dir
sudo cp /tmp/munge/munge.key /tmp/munge.key
sudo mv /tmp/munge.key /etc/munge/munge.key
sudo chown munge:munge /etc/munge/munge.key
sudo chmod 400 /etc/munge/munge.key

# start munge authorization service
sudo service munge start

jupyter lab --no-browser --allow-root --ip=0.0.0.0 --NotebookApp.token='' \
            --NotebookApp.password=''

tail -f /dev/null