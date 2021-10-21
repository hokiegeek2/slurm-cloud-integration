# Replace munge.key with munge.key file used in calling slurm client(s)
FILE=/tmp/munge.key

if test -f "$FILE"; then
    sudo cp /tmp/munge.key /tmp/m.key
    sudo chown munge:munge /tmp/m.key
    sudo mv /tmp/m.key /etc/munge/munge.key
    sudo chmod 400 /etc/munge/munge.key
fi

# Restart munge service to load replacement munge.key
sudo service munge start

# Start and configure mysql database and slurm db interface
sudo service mysql start
sudo service slurmdbd start
sudo mysql -u root < initialize-mariadb.sh

# Start slurmd worker
slurmd

# Sleep for 10 seconds to prevent race condition, then start slurmctld controller
sleep 10
slurmctld -D
