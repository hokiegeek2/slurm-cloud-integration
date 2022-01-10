export SLURM_JWT=daemon
slurmrestd -vvvv -a rest_auth/jwt $SLURMRESTD_HOST:$SLURMRESTD_PORT