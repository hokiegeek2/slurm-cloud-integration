# slurm-cloud-integration

## Background

The slurm-cloud-integration project contains Dockerfiles, config files, and deployment/config content designed to enable the protyping and delivery of capabilities that integrate the Kubernetes and Slurm-HPC ecosystems

The combination of the slurm-jupyter-docker and slurm-single-node Dockerfiles are based upon the excellent work by [Rodrigo Ancavil](https://medium.com/analytics-vidhya/slurm-cluster-with-docker-9f242deee601).

## slurm-single-node: full stack, single-node Slurm in Docker

The [slurm-single-node](https://github.com/hokiegeek2/slurm-cloud-integration/blob/master/src/docker/slurm-single-node) Dockerfile delivers an image that enables integration testing with a full Slurm stack w/ one worker (slurmd) node. This Dockerfile is based upon this excellent [example](https://blog.llandsmeer.com/tech/2020/03/02/slurm-single-instance.html)

The slurm-single-node Docker image is built from the project root directory as follows:

```
docker build -f src/docker/slurm-single-node -t hokiegeek2/slurm-single-node:$VERSION .
```

Successful startup of slurm-single-node looks like this:

![](https://user-images.githubusercontent.com/10785153/126529217-e8df432b-c925-4155-af37-d00e9205cd16.png)

## slurm-jupyterlab on k8s
The [slurm-jupyter-docker](https://github.com/hokiegeek2/slurm-cloud-integration/blob/master/src/docker/slurm-jupyter-docker) Dockerfile and slurm-jupyter [Helm chart](https://github.com/hokiegeek2/slurm-cloud-integration/tree/master/deployment/charts/slurm-jupyter) enables deployment of the awesome [NERSC](https://github.com/NERSC) [jupyterlab-slurm](https://github.com/NERSC/jupyterlab-slurm) application to Kubernetes. 

The slurm-jupyter Docker image is built from the project root directory as follows:

```
docker build -f src/docker/slurm-jupyter-docker -t hokiegeek2/slurm-jupyter:$VERSION .
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
In addition to the helm chart artifacts, the slurm-jupyterhub k8s deployment requires the _same_ munge.key used in the slurm cluster that the slurm-jupyterlab will connect to. The munge.key is used to create a Kubernetes secret that is mounted in the pod. The kubectl command is as follows:

```
kubectl create secret generic slurm-munge-key --from-file=/munge.key -n slurm-integration
```

The configuration logic for loading the k8s munge.key secret is in the slurm-jupyter [Helm template](https://github.com/hokiegeek2/slurm-cloud-integration/blob/master/deployment/charts/slurm-jupyter/templates/slurm-jupyter.yaml)

Successful deployment of slurm-jupyterlab looks like this:

![](https://user-images.githubusercontent.com/10785153/126530356-26eaeaf2-c940-48f2-9849-c14eda61b924.png)

Confirm connectivity to slurm via the following commands:

```
# generic cluster info including slurmd node names 
sinfo

# specific info and statuses for each slurmd node
scontrol show nodes
```

![](https://user-images.githubusercontent.com/10785153/126530625-980de73b-57ba-4114-b9f8-b58db3654bb5.png)

## Integration testing of slurm-jupyterlab on k8s with slurm-single-node

The combination of the slurm-jupyter-docker and slurm-single-node [Dockerfiles](https://github.com/hokiegeek2/slurm-cloud-integration/tree/master/src/docker) are based upon the excellent work by [Rodrigo Ancavil](https://medium.com/analytics-vidhya/slurm-cluster-with-docker-9f242deee601).

Integration testing of slurm-jupyterlab on k8s with slurm-single-node involves running the slurm-single-node [Docker image](https://hub.docker.com/repository/docker/hokiegeek2/slurm-single-node). The docker run command is as follows:

```
docker run -it --rm --network=host -v $PWD/munge.key:/tmp/munge.key hokiegeek2/slurm-single-node:$VERSION
```

The munge.key is passed into the Docker container, which is an extremely important detail. The munge key either in the slurm docker container or on a bare-metal slurm cluster *must* be the same munge.key in the slurm-jupyterlab deployment on k8s. If not, authentication from slurm-jupyterlab on k8s to the slurm cluster will fail with the following message:

![](https://user-images.githubusercontent.com/10785153/126519402-7a0e7679-2c15-4937-b883-d7bd87d090b1.png)
