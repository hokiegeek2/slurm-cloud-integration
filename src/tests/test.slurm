#!/bin/bash
#
#SBATCH --job-name=test
#SBATCH --output=result.out
#
#SBATCH --ntasks=1
#SBATCH --mem=2300
#
srun python3 /tmp/test.py
srun sleep 60