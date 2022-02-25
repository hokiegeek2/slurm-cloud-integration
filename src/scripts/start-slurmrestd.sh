export SLURM_JWT=daemon
export SLURMRESTD_HOST=0.0.0.0
export SLURMRESTD_PORT=6820

slurmrestd -vvvv -a rest_auth/jwt $SLURMRESTD_HOST:$SLURMRESTD_PORT
