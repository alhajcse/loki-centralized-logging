# Loki Centralized Logging

Standalone Grafana Loki deployment using Docker Compose.

## Architecture

- Loki runs on a separate VM, currently planned as `10.70.16.235`.
- Loki stores data persistently in `/opt/loki/data`.
- Existing Grafana connects to Loki as a data source.
- Grafana Alloy will be configured separately to forward Kubernetes logs.
- PostgreSQL Docker-host logs require a separate collector configuration.

## Requirements

- Ubuntu Server 24.04 or compatible Linux
- Docker Engine and Docker Compose plugin
- A VM with sufficient RAM and persistent disk
- TCP port 3100 available on the Loki VM

## Deployment

Run these commands on the Loki VM after cloning this repository:

```bash
cp .env.example .env
nano .env
```

Set `LOKI_BIND_IP` to an IP address assigned to the Loki VM.

Then run:

```bash
chmod +x scripts/install.sh scripts/verify.sh
sudo -E ./scripts/install.sh
```

The installer copies the configuration to `/opt/loki` and starts Loki.
It does not modify the existing Prometheus/Grafana Compose project.

## Verify

```bash
curl -i http://127.0.0.1:3100/ready
sudo /opt/loki/scripts/verify.sh
sudo docker logs --tail 100 loki
df -h /
```

A healthy Loki instance should return HTTP 200 from `/ready`.

## Grafana data source

In Grafana, open Connections -> Data sources -> Add data source -> Loki.

Set the URL to:

```text
http://10.70.16.235:3100
```

Save and test. If Grafana cannot reach the host-published address from its container,
check container-to-host connectivity and routing.

## Retention and storage

The default retention is seven days (`168h`). Actual disk use depends on log volume.
Monitor `/opt/loki/data` and available disk space regularly.

## Security warning

This lab configuration has Loki authentication disabled. Do not expose port 3100
to the public internet. Restrict access to trusted collectors and Grafana using
network controls or a properly authenticated proxy.

This is a single-instance lab deployment, not a highly available Loki cluster.
