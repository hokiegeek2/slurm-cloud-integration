# slurm-cloud-integration

## Background

The slurm-cloud-integration project contains Dockerfiles, config files, and deployment/config content designed to enable the protyping and delivery of capabilities that integrate the Kubernetes and Slurm-HPC ecosystems

The combination of the slurm-jupyter-docker and slurm-single-node Dockerfiles are based upon the excellent work by [Rodrigo Ancavil](https://medium.com/analytics-vidhya/slurm-cluster-with-docker-9f242deee601).

## slurm-single-node: full stack, single-node Slurm in Docker

The [slurm-single-node](https://github.com/hokiegeek2/slurm-cloud-integration/blob/master/src/docker/slurm-single-node) Dockerfile delivers an image that enables integration testing with a full Slurm stack w/ one worker (slurmd) node. This Dockerfile is based upon this excellent [example](https://blog.llandsmeer.com/tech/2020/03/02/slurm-single-instance.html) written by Lennart Landsmeer.

The slurm-single-node Docker image is built from the project root directory as follows:

```
export REPOSITORY=hokiegeek2
export VERSION=23.11.4

docker build --build-arg VERSION=$VERSION -f src/docker/slurm-single-node -t $REPOSITORY/slurm-single-node:$VERSION .
```
To simply run the slurm-single-node docker container, execute the following command:

```
export REPOSITORY=hokiegeek2
export VERSION=23.11.4

docker run -it --rm --network=host --privileged $REPOSITORY/slurm-single-node:$VERSION
```

Note: running the docker container in privileged mode is required to run slurmrestd

In order to perform any integration testing with applications outside of the slurm-single-node, a munge.key used in the external app must be mounted into the docker container. Accordingly, to mount a munge.key and start the slurm-single-node docker container, execute the following command:

```
export REPOSITORY=hokiegeek2
export VERSION=23.11.4

docker run -it --rm --network=host -v $PWD/munge.key:/tmp/munge.key $REPOSITORY/slurm-single-node:$VERSION
```

Successful startup of slurm-single-node looks like this:

![](https://user-images.githubusercontent.com/10785153/126529217-e8df432b-c925-4155-af37-d00e9205cd16.png)

### slurm-client Docker

The [slurm-client](https://github.com/hokiegeek2/slurm-cloud-integration/blob/master/src/docker/slurm-client) Dockerfile serves as a base Docker image to build slurm client images such as slurmrestd where the node is neither a slurm controller (slurmctld) nor a slurm worker (slurmd)

Building the slurm-client is as follows:

```
export REPOSITORY=hokiegeek2
export VERSION=23.11.4

docker build --build-arg VERSION=$VERSION -f src/docker/slurm-client -t $REPOSITORY/slurm-client:$VERSION .
```

Running the slurm-client is as follows:

```
docker run -it --rm --entrypoint=bash -v /tmp/munge.key:/tmp/munge/munge.key -v /tmp/slurm.conf:/etc/slurm/slurm.conf -v /tmp/slurmdbd.conf:/etc/slurm/slurmdbd.conf -v /tmp/jwt_hs256.key:/etc/slurm/jwt_hs256.key --network=host $REPOSITORY/slurm-client:$VERSION
```

### Troubleshooting

If the munge keys don't match, the following error occurs:

```
slurmctld: fatal: You are running with a database but for some reason we have no TRES from it.  This should only happen if the database is down and you don't have any state files.
```

## slurm-jupyterlab on k8s
The [slurm-jupyter-docker](https://github.com/hokiegeek2/slurm-cloud-integration/blob/master/src/docker/slurm-jupyter-docker) Dockerfile and slurm-jupyter [Helm chart](https://github.com/hokiegeek2/slurm-cloud-integration/tree/master/deployment/charts/slurm-jupyter) enables deployment of the awesome [NERSC](https://github.com/NERSC) [jupyterlab-slurm](https://github.com/NERSC/jupyterlab-slurm) application to Kubernetes. 

The slurm-jupyter Docker image is built from the project root directory as follows:

```
docker build -f src/docker/slurm-jupyter-docker -t hokiegeek2/slurm-jupyter:$VERSION .
```

The command sequence to start slurm-jupyterlab is contained within the [start-slurm-jupyter.sh](https://github.com/hokiegeek2/slurm-cloud-integration/blob/master/src/scripts/start-slurm-jupyter.sh) file and is as follows:

```
#!/bin/bash

# copy munge.key, set ownership and permissions, and move to config dir
sudo cp /tmp/munge/munge.key /tmp/munge.key
sudo mv /tmp/munge.key /etc/munge/munge.key
sudo chown munge:munge /etc/munge/munge.key
sudo chmod 400 /etc/munge/munge.key

# start munge authorization service
sudo service munge start

jupyter lab --no-browser --allow-root --ip=0.0.0.0 --NotebookApp.token='' \
            --NotebookApp.password=''

tail -f /dev/null
```

Note the munge.key handling section, which is required to handle the munge.key passed in at container startup. Specifically, the munge.key file must be owned by the munge user and the permissions must be 400.

## Deploying slurm-jupyterlab to Kubernetes

### Preparing for slurm-jupyterlab Deployment

The munge.key configured for slurmctld needs to be added as a secret, which is accomplished as follows:

```
# Add secret encapsulating munge.key
kubectl create secret generic slurm-munge-key --from-file=/tmp/munge.key -n slurm-integration

# Confirm secret was created
kubectl get secret -n slurm-integration
NAME                                         TYPE                                  DATA   AGE
slurm-munge-key                              Opaque                                1      18d
```
Importantly, in analogy to the slurmd workers, the munge.key _MUST_ be the same munge.key used in the munge service running on the slurmctld node. 

Deploying slurm-jupyterlab is done via the slurm-jupyter [Docker image](https://hub.docker.com/repository/docker/hokiegeek2/slurm-jupyter) and the slurm-jupyter [Helm chart](https://github.com/hokiegeek2/slurm-cloud-integration/tree/master/deployment/charts/slurm-jupyter). 

The helm command is executed as follows from the project root directory:

```
helm install -n slurm-integration slurm-jupyter-server deployment/charts/slurm-jupyter/ 
```
In addition to the helm chart artifacts, the slurm-jupyterhub k8s deployment requires the _same_ munge.key used in the slurm cluster that the slurm-jupyterlab will connect to. The munge.key is used to create a Kubernetes secret that is mounted in the pod. The kubectl command is as follows:

```
kubectl create secret generic slurm-munge-key --from-file=munge.key -n slurm-integration
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

Using the [test.slurm](https://github.com/hokiegeek2/slurm-cloud-integration/blob/master/src/tests/test.slurm) job, as successful job execution will look as follows in slurm-jupyterlab via terminal...

![](https://user-images.githubusercontent.com/10785153/126484359-e991a0ee-808b-4df9-90b8-23062b73c387.png)

...as well as this in slurm queue manager:

![](https://user-images.githubusercontent.com/10785153/126497874-a2c6be77-8219-431a-b8c5-a8bf3b5824d9.png)

...and finally this in slurm:

![](https://user-images.githubusercontent.com/10785153/126484250-716e1dcb-5f36-43e9-abb7-4e4f7721adcd.png)

# Deploying slurm_jupyter in Jupyterhub on k8s

## Background

The Jupyterhub deployment of slurm-jupyter utilizes the [kubespawner](https://github.com/jupyterhub/kubespawner) which is configured via the [singleuser](https://github.com/jupyterhub/jupyterhub/tree/main/singleuser) section of the jupyterhub [values.yaml](https://github.com/jupyterhub/zero-to-jupyterhub-k8s/blob/main/jupyterhub/values.yaml) file.

### Jupyterhub/slurm-jupyter Helm install

slurm-jupyter can be deployed as a singleuser image within a k8s jupyterhub install

#### Building slurm-jupyter singleuser image

```
docker build -f src/docker/slurm-jupyter-notebook -t hokiegeek2/slurm-jupyter-notebook:$VERSION .
```

As of 20211021, the way to mount the slurm.conf and munge.key file is done as follows within the helm install command, which is executed from the $PROJECT_HOME/deployments/charts directory:

Using a [fork](https://github.com/hokiegeek2/slurm-cloud-integration/tree/master/deployment/charts/slurm-jupyterhub) of the [zero-to-jupyterhub-k8s](https://github.com/jupyterhub/zero-to-jupyterhub-k8s) helm chart, the deployment is as follows:

```
helm install -n jupyter jupyterhub slurm-jupyterhub --values config.yaml \
--set-file singleuser.extraFiles.slurm-conf.stringData=/mnt/data/slurm/slurm.conf \
--set-file singleuser.extraFiles.munge-key.binaryData=/mnt/data/slurm/munge.key.b64
```
### Preparing munge.key file for Jupyterhub/slurm-jupyter Helm install

Note that the munge.key handling -> since it is a binary file, the following command must be run to generate the file submitted with the helm install:

```
base64 /mnt/data/slurm/munge.key > /mnt/data/slurm/munge.key.b64
```

# Testing 

There are a couple of [test slurm files](https://github.com/hokiegeek2/slurm-cloud-integration/tree/master/src/tests) in this repo to confirm expected slurm job behavior from slurm-jupyter.

# slurmrestd Integration

## Background

The [slurmrestd](https://slurm.schedmd.com/slurmrestd.html) service provides a REST endpoint to perform operations against slurm. An important benefit of slurmrestd is that it obviates the need to configure and deploy slurm libraries to clients that need slurm access.

## Steps to Enable slurmrestd 

### Install slurmrestd Dependencies

As shown in the [slurm-single-node](src/docker/slurm-single-node) docker file, the following slurmrestd dependencies must be installed:

```
sudo apt-get update && apt-get install cmake libhttp-parser-dev libjwt-dev libyaml-dev libjson-c-dev -y
```

### Build slurm with slurmrestd Support

As shown in the [slurm-single-node](src/docker/slurm-single-node) docker file, the slurm build needs to be configured to (1) build slurmrestd and (2) link to the slurmrestd dependent libraries (http-parser, yaml, and jwt) via the $SLURM_PROJECT_DIRECTORY/configure command:

```
./configure --prefix=/storage/slurm-build --sysconfdir=/etc/slurm --enable-pam \
    --with-pam_dir=/lib/x86_64-linux-gnu/security/ --without-shared-libslurm \
    --with-http-parser=/usr/local/ --with-yaml=/usr/local/ --with-jwt=/usr/local/lib/ --enable-slurmrestd 
```

### Update slurmctld and slurmdbd to Enable jwt Authentication

Since slurmrestd uses [Json Web Token](https://jwt.io/introduction) for authentication, jwt has to be added as 
an alternative authentiation type in both the slurm.conf and slurmdbd.conf files as detailed [here](https://slurm.schedmd.com/jwt.html):

```
AuthAltTypes=auth/jwt
AuthAltParameters=jwt_key=/etc/slurm/jwt_hs256.key
```

### Generate and Set Permissions for jwt key

Now that slurmctld and slurmdbd are built and configured for jwt authentication, generate the jwt key to be used by slurmctld and slurmdbd to verify user tokens submitted with each slurmrestd REST call and set the permissions. For Linux, the jwt key is generated as follows:

```
dd if=/dev/random of=/etc/slurm/jwt_hs256.key bs=32 count=1
```

Set the ownership and permissions for the jwt key:

```
chown slurm:slurm /etc/slurm/jwt_hs256.key
chmod 600 /etc/slurm/jwt_hs256.key
```

## Running slurmrestd

### Start slurmctld and slurmdbd with JWT Authentication

Now that slurmctld and slurmdbd are configured for alternate, jwt authentication, start slurmdbd, then slurmctd.

### Start slurmrestd

The slurmrestd daemon is started as follows (note the SLURM_JWT=daemon env variable)

```
export SLURMRESTD_HOST=0.0.0.0
export SLURMRESTD_PORT=6820
export SLURM_JWT=daemon

slurmrestd -vvvv -a rest_auth/jwt $SLURMRESTD_HOST:$SLURMRESTD_PORT
```

The following log message shows that slurmrestd was successfully started with jwt authentication enabled:

```
slurmrestd: debug:  main: server listen mode activated
slurmrestd: debug3: Trying to load plugin /usr/lib/slurm/auth_jwt.so
slurmrestd: debug:  auth/jwt: init: JWT authentication plugin loaded
slurmrestd: debug3: Success.
```

### Accessing slurmrestd

#### Generate JWT Token for User

Each user accessing slurmrestd must have a JWT token, which is generated by scontrol:

```
export $(scontrol token)
```

#### Execute slurmrestd Request

With the jwt token in hand, execute the slurmrestd command with the following, general structure:

```
export SLURMRESTD_HOST=0.0.0.0
export SLURMRESTD_PORT=6820

curl -H "X-SLURM-USER-NAME:slurm" -H "X-SLURM-USER-TOKEN:${SLURM_JWT}" http://$SLURMRESTD_HOST:$SLURMRESTD_PORT
```

Run the following curl command to confirm slurmrestd is working correctly:

```
$ curl -H "X-SLURM-USER-NAME:slurm" -H "X-SLURM-USER-TOKEN:${SLURM_JWT}" http://localhost:6820/slurm/v0.0.37/ping
{
   "meta": {
     "plugin": {
       "type": "openapi\/v0.0.36",
       "name": "REST v0.0.36"
     },
     "Slurm": {
       "version": {
         "major": 20,
         "micro": 8,
         "minor": 11
       },
       "release": "20.11.8"
     }
   },
   "errors": [
   ],
   "pings": [
     {
       "hostname": "e1968f80260d",
       "ping": "UP",
       "status": 0,
       "mode": "primary"
     }
   ]
 }
```

The slurmrestd server-side debug logging on the above request is similar to the following:

```
slurmrestd: debug3: _on_headers_complete: [[localhost]:39180] HTTP/1.1 connection
slurmrestd: operations_router: [[localhost]:39180] GET /slurm/v0.0.36/ping
slurmrestd: debug3: rest_auth/jwt: slurm_rest_auth_p_authenticate: slurm_rest_auth_p_authenticate: [[localhost]:39180] attempting user_name slurm token authentication
slurmrestd: debug3: _resolve_mime: [[localhost]:39180] mime read: application/x-www-form-urlencoded write: application/json
slurmrestd: debug:  parse_http: [[localhost]:39674] Accepted HTTP connection
slurmrestd: debug:  _on_url: [[localhost]:39674] url path: /slurm/v0.0.36/ping query: (null)
slurmrestd: debug2: _on_header_value: [[localhost]:39674] Header: Host Value: localhost:6820
slurmrestd: debug2: _on_header_value: [[localhost]:39674] Header: User-Agent Value: curl/7.58.0
slurmrestd: debug2: _on_header_value: [[localhost]:39674] Header: Accept Value: */*
slurmrestd: debug2: _on_header_value: [[localhost]:39674] Header: X-SLURM-USER-NAME Value: slurm
slurmrestd: debug2: _on_header_value: [[localhost]:39674] Header: X-SLURM-USER-TOKEN Value: eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJleHAiOjE2NDE4MjMxODYsImlhdCI6MTY0MTgyMTM4Niwic3VuIjoic2x1cm0ifQ.Rc6BIFHAMlZsLQVBAgN-8kPFw5Onc5kWgqMCG287WSc
```

# Slurm Administration Notes

## Upgrade

The current version of slurm needs to be removed prior to installing the new version. The command for removing slurm is as follows:

```
# get slurm version
slurmctld -V 
slurm-20.02.7

# remove all slurm components
dpkg -P slurm-20.02.7
```

Once the previous version of slurm is removed, proceed with the standard slurm install instructions
