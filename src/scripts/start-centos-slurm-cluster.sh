# Replace munge.key with munge.key file used in calling slurm client(s)
FILE=/tmp/munge.key

if test -f "$FILE"; then
    cp /tmp/munge.key /tmp/m.key
    chown munge:munge /tmp/m.key
    mv /tmp/m.key /etc/munge/munge.key
    chmod 400 /etc/munge/munge.key
fi

# Restart munge service to load replacement munge.key
systemctl start munge 

# Start and configure mysql database and slurm db interface
systemctl start mariadb 
systemctl start slurmdbd
mysql -u root < initialize-mariadb.sh

# Start slurmd worker
slurmd

# Sleep for 5 seconds to prevent race condition, then start slurmctld controller
sleep 5
slurmctld

export SLURMRESTD_HOST=0.0.0.0
export SLURMRESTD_PORT=6820
export SLURM_JWT=daemon

runuser -l slurmrestd -c 'export SLURM_JWT=daemon; slurmrestd -vvvv -a rest_auth/jwt 0.0.0.0:6820'
