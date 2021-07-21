# slurm-cloud-integration

## Background

The slurm-cloud-integration project contains Dockerfiles, config files, and deployment/config content designed to enable the protyping and delivery of capabilities that integrate the Kubernetes and Slurm-HPC ecosystems

The combination of the slurm-jupyter-docker and slurm-single-node Dockerfiles are based upon the excellent work by [Rodrigo Ancavil](https://medium.com/analytics-vidhya/slurm-cluster-with-docker-9f242deee601).

## slurm-single-node: full stack, single-node Slurm in Docker

The [slurm-single-node](https://github.com/hokiegeek2/slurm-cloud-integration/blob/master/src/docker/slurm-single-node) Dockerfile delivers an image that enables integration testing with a full Slurm stack w/ one worker (slurmd) node. This Dockerfile is based upon this excellent [example](https://blog.llandsmeer.com/tech/2020/03/02/slurm-single-instance.html)

The slurm-single-node Docker image is built from the project root directory as follows:

```
docker build -f src/docker/slurm-single-node -t hokiegeek2/slurm-single-node .
```

## slurm-jupyterlab on k8s
The [slurm-jupyter-docker](https://github.com/hokiegeek2/slurm-cloud-integration/blob/master/src/docker/slurm-jupyter-docker) Dockerfile and slurm-jupyter [Helm chart](https://github.com/hokiegeek2/slurm-cloud-integration/tree/master/deployment/charts/slurm-jupyter) enables deployment of the awesome [NERSC](https://github.com/NERSC) [jupyterlab-slurm](https://github.com/NERSC/jupyterlab-slurm) application to Kubernetes. 

The slurm-jupyter Docker image is built from the project root directory as follows:

```
docker build -f src/docker/slurm-jupyter-docker -t hokiegeek2/slurm-jupyter:20.11.8-1 .
```

The command sequence to start slurm-jupyterlab is contained within the [start-slurm-jupyter.sh](https://github.com/hokiegeek2/slurm-cloud-integration/blob/master/src/scripts/start-slurm-jupyter.sh) file and is as follows:

```
#!/bin/bash

# start the munge authentication service
sudo service munge start

# start jupyter lab with slurm-jupyterlab plugin
jupyter lab --no-browser --allow-root --ip=0.0.0.0 --NotebookApp.token='' --NotebookApp.password=''

# keep the docker image running
tail -f /dev/null
```

## Deploying slurm-jupyterlab to Kubernetes

Deploying slurm-jupyterlab is done via the slurm-jupyter [Docker image](https://hub.docker.com/repository/docker/hokiegeek2/slurm-jupyter) and the slurm-jupyter [Helm chart](https://github.com/hokiegeek2/slurm-cloud-integration/tree/master/deployment/charts/slurm-jupyter). 

The helm command is executed as follows from the project root directory:

```
helm install -n slurm-integration slurm-jupyter-server deployment/charts/slurm-jupyter/ 
```
## Integration testing of slurm-jupyterlab on k8s with slurm-single-node

The combination of the slurm-jupyter-docker and slurm-single-node [Dockerfiles](https://github.com/hokiegeek2/slurm-cloud-integration/tree/master/src/docker) are based upon the excellent work by [Rodrigo Ancavil](https://medium.com/analytics-vidhya/slurm-cluster-with-docker-9f242deee601).

Integration testing of slurm-jupyterlab on k8s with slurm-single-node involves running the slurm-single-node [Docker image](https://hub.docker.com/repository/docker/hokiegeek2/slurm-single-node). The docker run command is as follows:

```
docker run -it --rm --entrypoint=bash --network=host -v $PWD/munge.key:/tmp/munge.key hokiegeek2/slurm-single-node
```

The munge.key is passed into the Docker container, which is an extremely important detail. The munge key either in the slurm docker container or on a bare-metal slurm cluster *must* be the same munge.key in the slurm-jupyterlab deployment on k8s. If not, authentication from slurm-jupyterlab on k8s to the slurm cluster will fail.
