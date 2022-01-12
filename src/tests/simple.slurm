#!/bin/bash
#
#SBATCH --job-name=test
#SBATCH --output=res.txt
#SBATCH --mem=500
#SBATCH --ntasks=1
#SBATCH --nodes=1
#SBATCH --time=1:00
 
srun hostname
cat /proc/self/stat | awk '{print $39}'
srun sleep 60
