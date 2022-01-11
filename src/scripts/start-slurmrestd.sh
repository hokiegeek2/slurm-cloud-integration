export SLURM_JWT=daemon

slurmrestd -vvvv -a rest_auth/jwt 0.0.0.0:6820
