# slurm-cloud-integration

## Background

The slurm-cloud-integration project contains Dockerfiles, config files, and wiki content designed to enable the protyping and delivery of capabilities that integrate the Kubernetes and Slurm-HPC ecosystems

The combination of the slurm-jupyter-docker and slurm-single-node Dockerfiles are based upon the excellent work by [Rodrigo Ancavil](https://medium.com/analytics-vidhya/slurm-cluster-with-docker-9f242deee601).

## slurm-single-node: full stack, single-node Slurm in Docker

The [slurm-single-node](https://github.com/hokiegeek2/slurm-cloud-integration/blob/master/src/docker/slurm-single-node) Dockerfile delivers an image that enables integration testing with a full Slurm stack w/ one worker (slurmd) node. 

## slurm-jupyter on k8s
The [slurm-jupyter-docker](https://github.com/hokiegeek2/slurm-cloud-integration/blob/master/src/docker/slurm-jupyter-docker) Dockerfile and slurm-jupyter [Helm chart](https://github.com/hokiegeek2/slurm-cloud-integration/tree/master/deployment/charts/slurm-jupyter) enables deployment of the awesome [NERSC](https://github.com/NERSC) [jupyterlab-slurm](https://github.com/NERSC/jupyterlab-slurm) application to Kubernetes. 

The combination of the slurm-jupyter-docker and slurm-single-node Dockerfiles are based upon the excellent work by [Rodrigo Ancavil](https://medium.com/analytics-vidhya/slurm-cluster-with-docker-9f242deee601).
