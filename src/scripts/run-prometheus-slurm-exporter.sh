#!/bin/bash

docker run -it --rm \
-v $SLURM_FILES_DIRECTORY/munge.key:/tmp/munge/munge.key \
-v $SLURM_FILES_DIRECTORY/slurm.conf:/etc/slurm/slurm.conf \
-v $SLURM_FILES_DIRECTORY/slurmdbd.conf:/etc/slurm/slurmdbd.conf \
--network=host hokiegeek2/prometheus-slurm-exporter:$EXPORTER_VERSION
