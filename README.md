# dnsop
DNS Observability Pipeline PoC

A complete DNS observability solution using CoreDNS, Vector, and the LGTM stack (Loki, Grafana, Tempo, Mimir) for comprehensive monitoring, logging, and tracing of DNS queries.

## Architecture

This setup provides a complete observability pipeline for DNS operations:

- **CoreDNS**: DNS server with Prometheus metrics and structured logging
- **Vector**: Log and metrics collection, transformation, and routing
- **Loki**: Log aggregation and querying
- **Grafana**: Visualization and dashboards
- **Tempo**: Distributed tracing
- **Mimir**: Long-term metrics storage

### Dashboard Preview

The included Grafana dashboard provides real-time visibility into DNS operations:

![DNS Observability Dashboard](https://github.com/user-attachments/assets/2e792a52-c225-46fb-9a52-acdec96dd4cf)

The dashboard includes:
- DNS request rate visualization
- Total queries per second gauge
- Real-time CoreDNS logs
- Response code distribution
- Query latency percentiles (p50, p95, p99)

## Components

### CoreDNS
- Serves DNS queries on port 5353 (UDP/TCP)
- Provides Prometheus metrics on port 9153
- Health check endpoint on port 8080
- Configured with example zone file for `example.com`

### Vector
- Collects logs from Docker containers (specifically CoreDNS)
- Scrapes Prometheus metrics from CoreDNS
- Transforms and enriches log data
- Routes data to appropriate backends (Loki, Tempo, Mimir)
- API available on port 8686

### LGTM Stack
- **Loki** (port 3100): Aggregates and stores logs
- **Grafana** (port 3000): Visualization and dashboards
- **Tempo** (port 3200): Distributed tracing backend
- **Mimir** (port 9009): Prometheus-compatible metrics storage

## Quick Start

### Prerequisites
- Docker
- Docker Compose

### Starting the Stack

```bash
docker compose up -d
```

See [QUICKSTART.md](QUICKSTART.md) for detailed instructions.

### Accessing Services

- **Grafana**: http://localhost:3000
  - Username: `admin`
  - Password: `admin`
  - Pre-configured datasources for Loki, Tempo, and Mimir
  - DNS Observability Dashboard included

- **Loki**: http://localhost:3100
- **Tempo**: http://localhost:3200
- **Mimir**: http://localhost:9009
- **Vector API**: http://localhost:8686
- **CoreDNS**: localhost:5353 (DNS queries)

### Testing DNS Queries

```bash
# Query the example zone
dig @localhost -p 5353 example.com
dig @localhost -p 5353 www.example.com
dig @localhost -p 5353 api.example.com

# Query external domains (forwarded to 8.8.8.8)
dig @localhost -p 5353 google.com
dig @localhost -p 5353 github.com
```

### Viewing Logs and Metrics

1. Open Grafana at http://localhost:3000
2. Navigate to "Dashboards" -> "DNS" -> "DNS Observability Dashboard"
3. View real-time metrics, logs, and traces

## Configuration Files

- `docker-compose.yml`: Main orchestration file
- `coredns/Corefile`: CoreDNS configuration
- `coredns/zones/example.com.zone`: Example DNS zone file
- `vector/vector.yaml`: Vector pipeline configuration
- `loki/loki-config.yaml`: Loki configuration
- `tempo/tempo-config.yaml`: Tempo configuration
- `mimir/mimir-config.yaml`: Mimir configuration
- `grafana/provisioning/`: Grafana datasources and dashboards

## Monitoring Capabilities

### Metrics (via Mimir)
- DNS request rate
- Response codes distribution
- Query latency (p50, p95, p99)
- Cache hit/miss rates
- Error rates

### Logs (via Loki)
- Structured DNS query logs
- Error logs
- Server events

### Traces (via Tempo)
- DNS query execution traces
- Latency breakdown
- Service dependencies

## Data Retention

- **Loki**: 7 days (168 hours)
- **Tempo**: 7 days (168 hours)
- **Mimir**: 7 days

## Customization

### Adding More DNS Zones

1. Create a new zone file in `coredns/zones/`
2. Update `coredns/Corefile` to include the new zone
3. Restart CoreDNS: `docker compose restart coredns`

### Modifying Data Pipelines

Edit `vector/vector.yaml` to add or modify:
- Log parsing rules
- Metric transformations
- Routing logic
- Additional data sources

### Creating Custom Dashboards

1. Access Grafana at http://localhost:3000
2. Create dashboards using the pre-configured datasources
3. Export and save to `grafana/provisioning/dashboards/`

## Stopping the Stack

```bash
# Stop all services
docker compose down

# Stop and remove volumes (WARNING: deletes all data)
docker compose down -v
```

## Troubleshooting

### Check Service Status
```bash
docker compose ps
```

### View Logs
```bash
# All services
docker compose logs -f

# Specific service
docker compose logs -f coredns
docker compose logs -f vector
docker compose logs -f grafana
```

### Verify Data Flow
1. Check Vector is collecting logs: `docker compose logs vector`
2. Verify Loki is receiving data: http://localhost:3100/ready
3. Check Grafana datasource connectivity in Settings -> Data Sources

## License

See LICENSE file for details.

