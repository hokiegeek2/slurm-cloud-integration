FROM hokiegeek2/slurm-client-docker:21.08.5 as slurm_client

FROM hokiegeek2/ubuntu22_go

COPY --from=slurm_client /storage/slurm-build /storage/slurm-build
COPY --from=slurm_client /usr/bin/sinfo /usr/bin/sinfo
COPY --from=slurm_client /usr/bin/squeue /usr/bin/squeue
COPY --from=slurm_client /usr/bin/sdiag /usr/bin/sdiag
COPY --from=slurm_client /usr/bin/sshare /usr/bin/sshare

ARG EXPORTER_VERSION=${EXPORTER_VERSION}
ENV EXPORTER_VERSION=${EXPORTER_VERSION}

## Install munge and unzip
RUN apt-get update && apt-get install unzip libmunge-dev libmunge2 munge -y && \
    useradd slurm

WORKDIR /opt

RUN wget https://github.com/vpenso/prometheus-slurm-exporter/archive/refs/tags/${EXPORTER_VERSION}.zip && \
    unzip ${EXPORTER_VERSION}

WORKDIR /opt/prometheus-slurm-exporter-${EXPORTER_VERSION}
COPY Makefile /opt/prometheus-slurm-exporter-${EXPORTER_VERSION}/Makefile
RUN make

COPY start-prometheus-exporter.sh /opt/prometheus-slurm-exporter-${EXPORTER_VERSION}/start-prometheus-exporter.sh
ENTRYPOINT sh start-prometheus-exporter.sh
