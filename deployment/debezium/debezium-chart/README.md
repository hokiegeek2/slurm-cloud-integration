<p align="center">
    <img src="https://debezium.io/assets/images/color_white_debezium_type_600px.svg" style="width:256px;" alt="logo" />
</p>

<h1 align="center">
    Debezium Helm Chart
</h1>

<p align="center">
    Debezium helm chart including <span style="background: darkcyan">Connect</span> and <span style="background: darkcyan">UI</span> components
</p>

<p align="center">
    <img src="https://img.shields.io/badge/license-apache_2.0-red?style=for-the-badge&logo=apache" alt="license" />
    <img src="https://img.shields.io/badge/Version-0.0.2-informational?style=for-the-badge&logo=github" alt="version" />

</p>

## Deployment

Update the following envs in `values.yaml`:

```yaml
connect:

  ...

  env:
      # kafka bootstrap servers to publish database events
      - name: BOOTSTRAP_SERVERS
        value: KAFKA_BOOTSTRAP_SERVER_ADDRESS:9092 <------

  ...

ui:
  ...

  ingress:
    enabled: true
    router: private
    # url for accessing debezium dashboard
    host: DEBEZIUM_UI_HOST_ADDRESS  <----------
```

Use the following command to install the chart

```shell
helm install <CHART-NAME> debezium
```

## Be Cautious that

This chart is tested and installed on `OpenShift` successfully but use at your own risk. Feel free to open an issue for
improvement or other matters.
