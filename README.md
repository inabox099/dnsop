# DNS Observability Pipeline (current)

A self-contained DNS observability playground that captures dnstap from DNS servers (CoreDNS and BIND/named), processes and aggregates it with Vector, stores logs in Loki, and exports metrics to Mimir (Prometheus remote write). Use this repository to run the full stack locally (via Docker) and inspect logs, aggregated events, and metrics in Grafana.

Quick file references:
- Compose orchestration: [docker-compose.yml](docker-compose.yml)
- CoreDNS config (dnstap over TCP): [coredns/Corefile](coredns/Corefile)
- Central Vector config: [vector/vector.yaml](vector/vector.yaml)
- Named (BIND) local Vector config: [named/vector.yaml](named/vector.yaml)
- Named authoritative config: [named/named-authoritative.conf](named/named-authoritative.conf)
- Named caching config: [named/named-caching.conf](named/named-caching.conf)
- Named container build & entrypoint: [named/Dockerfile](named/Dockerfile), [named/scripts/entrypoint.sh](named/scripts/entrypoint.sh)
- Loki config: [loki/loki.yaml](loki/loki.yaml)
- Mimir config: [mimir/mimir.yaml](mimir/mimir.yaml)
- Zone files: [named/zones/db.example.com](named/zones/db.example.com), [named/zones/db.root](named/zones/db.root)
- Persistent storage root: ./data
- License: [LICENSE](LICENSE)
- Git ignore: [.gitignore](.gitignore)

Architecture — what runs and how it connects
- docker-compose coordinates services: see [docker-compose.yml](docker-compose.yml).
  - Network "backend" is created with the configured subnet and static IPs for services so dnstap and Vector endpoints are reachable by predictable addresses.

Services and configuration details
- CoreDNS ([coredns/Corefile](coredns/Corefile))
  - Runs as the container `coredns` (mapped to host ports 5353/5353 udp/tcp).
  - Configured to forward queries and emit dnstap by calling:
    dnstap tcp://vector:9053 full
  - Effect: CoreDNS streams dnstap events over TCP to the central Vector instance on the container name `vector`.

- Central Vector ([vector/vector.yaml](vector/vector.yaml))
  - Runs as the `vector` container (10.10.1.40 in the compose network).
  - Sources:
    - `dnstap_source`: accepts dnstap over TCP (port 9053) — this receives CoreDNS dnstap.
    - `vector_source`: accepts Vector-to-Vector frames (port 9054) — used by named containers to forward their parsed dnstap.
  - Transforms:
    - `dnstap_json` remaps dnstap payloads into JSON fields.
    - `filter_client_responses` keeps only ClientResponse messages (combined inputs include direct vector frames).
    - Two reduce stages (`dns_message_reduce` and `qname_reduce`) aggregate events by qname/source/qtype/rcode to produce counts over short windows.
    - Aggregated remaps prepare `dnstap_aggregated` and `qname_aggregated` log records.
    - `client_metric` and `qname_metric` convert aggregated logs into metrics (counters).
  - Sinks:
    - `loki_sink`: sends raw and aggregated JSON logs to Loki at http://loki:3100 (see [loki/loki.yaml](loki/loki.yaml)).
    - `mimir_sink` (prometheus_remote_write): pushes metrics to Mimir at http://mimir:9090/api/v1/push (see [mimir/mimir.yaml](mimir/mimir.yaml)).
    - File/console sinks exist for debugging and local inspection.

- Named (BIND) containers and local Vector
  - Image built by [named/Dockerfile](named/Dockerfile) installs BIND and Vector.
  - Named runs either authoritative or caching configurations:
    - Authoritative: [named/named-authoritative.conf](named/named-authoritative.conf) (container name `named-authoritative`, mapped host port 6053)
    - Caching: [named/named-caching.conf](named/named-caching.conf) (container name `named-caching`, mapped host port 5153)
  - Each named container enables dnstap writing to a local UNIX socket at /run/dnstap.sock.
  - The container runs a local instance of Vector (config: [named/vector.yaml](named/vector.yaml)) which:
    - Reads the UNIX dnstap socket (`dnstap_socket` source).
    - Remaps messages to JSON.
    - Forwards parsed messages to the central Vector over the Vector-to-Vector protocol (`my_sink_id` => 10.10.1.40:9054).
  - The container entrypoint [named/scripts/entrypoint.sh](named/scripts/entrypoint.sh) starts the container-local Vector, then starts named; it also handles graceful shutdown.

- Loki ([loki/loki.yaml](loki/loki.yaml))
  - Stores logs on the host-mounted `./data` directory (configured in [docker-compose.yml](docker-compose.yml)).
  - Exposes container port 3100; the compose file maps it to host 3101 (`http://localhost:3101`) to avoid conflicts.
  - Vector sends JSON log lines here for log indexing and queries.

- Mimir ([mimir/mimir.yaml](mimir/mimir.yaml))
  - Acts as the long-term Prometheus remote write receiver and store (Prometheus-compatible API).
  - Receives metrics from Vector's `prometheus_remote_write` sink.
  - Exposes port 9090 on the host (`http://localhost:9090`).

- Grafana (configured inside docker-compose)
  - Provisioned at container `grafana` with data sources pre-created to point to Loki and Mimir.
  - Host port 3000 is exposed for UI: http://localhost:3000.

Data flow summary
- CoreDNS -> dnstap TCP -> central Vector (9053) -> transforms -> Loki + Mimir
- named -> local dnstap socket -> per-container Vector -> forwards (Vector protocol) -> central Vector (9054) -> same pipeline
- Vector reduces and aggregates events into metrics (per qname, per source) and sends them to Mimir; logs (raw + aggregated) go to Loki.

Run / quickstart
1. Start services:
   ```sh
   docker-compose up -d
   ```
2. Watch central Vector logs and services:
   ```sh
   docker-compose logs -f vector
   docker-compose logs -f loki
   ```
3. Open UIs:
   - Grafana: http://localhost:3000
   - Loki (host): http://localhost:3101
   - Vector API (central): http://localhost:8686
   - Mimir: http://localhost:9090

Important implementation notes and gotchas
- The named containers use a UNIX socket at /run/dnstap.sock. The bundled entrypoint starts a local Vector inside the named container to read that socket then forward to the central Vector. Inspect [named/vector.yaml](named/vector.yaml) and [named/scripts/entrypoint.sh](named/scripts/entrypoint.sh).
- CoreDNS sends dnstap directly to central Vector over TCP (see [coredns/Corefile](coredns/Corefile)).
- The compose network uses static IPs (10.10.1.x). Ensure those addresses don't conflict with your host network.
- Loki data is persisted to ./data — keep backups if you want to preserve logs across rebuilds.
- If you change Vector configs, restart the vector container (`docker-compose restart vector`). For named config changes, rebuild the `named-dnstap` image as defined by [named/Dockerfile](named/Dockerfile).

Troubleshooting
- Vector not receiving dnstap:
  - From CoreDNS: confirm [coredns/Corefile](coredns/Corefile) points at `vector:9053`.
  - From named containers: confirm the per-container Vector (`named/vector.yaml`) is running and the sink points at the central vector ip:port.
- Loki errors: check `docker-compose logs loki` and file permissions of `./data`.
- UNIX socket permission issues inside named containers: the Dockerfile sets up vector and attempts to write `/run/dnstap.sock` — ensure the runtime user and file modes match your container setup.

Where to inspect & edit configs
- Compose orchestration: [docker-compose.yml](docker-compose.yml)
- Central pipeline: [vector/vector.yaml](vector/vector.yaml)
- Named local pipeline (per-container): [named/vector.yaml](named/vector.yaml)
- DNS server configs: [coredns/Corefile](coredns/Corefile), [named/named-caching.conf](named/named-caching.conf), [named/named-authoritative.conf](named/named-authoritative.conf)
- Loki: [loki/loki.yaml](loki/loki.yaml)
- Mimir: [mimir/mimir.yaml](mimir/mimir.yaml)
- Named build & entrypoint: [named/Dockerfile](named/Dockerfile), [named/scripts/entrypoint.sh](named/scripts/entrypoint.sh)

License
- Project licensed under: [LICENSE](LICENSE)


## Queries

```
count_over_time({your_label="value"}[$__range])
```


```
count(
  count_over_time({app="app"}[1h])
  by (UserID)
)
```