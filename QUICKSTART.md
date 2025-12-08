# Quick Start Guide

## Prerequisites

- Docker Engine 20.10 or later
- Docker Compose 2.0 or later
- At least 4GB of available RAM
- `dig` command (from `dnsutils` or `bind-tools` package) for testing DNS queries

## Starting the Stack

1. **Clone the repository**:
   ```bash
   git clone https://github.com/inabox099/dnsop.git
   cd dnsop
   ```

2. **Start all services**:
   ```bash
   docker compose up -d
   ```
   
   Or using the Makefile:
   ```bash
   make up
   ```

3. **Wait for services to initialize** (approximately 30 seconds):
   ```bash
   docker compose ps
   ```
   
   All services should show status as "Up".

## Accessing the Services

### Grafana Dashboard
1. Open your browser to http://localhost:3000
2. Login credentials:
   - Username: `admin`
   - Password: `admin`
3. Navigate to **Dashboards** → **DNS** → **DNS Observability Dashboard**

### Service Endpoints
- **Grafana**: http://localhost:3000
- **Loki API**: http://localhost:3100
- **Tempo API**: http://localhost:3200
- **Mimir API**: http://localhost:9009
- **Vector API**: http://localhost:8686
- **CoreDNS**: localhost:5353 (DNS server)

## Testing DNS Queries

### Query Example Zone
```bash
# Basic A record lookups
dig @localhost -p 5353 example.com
dig @localhost -p 5353 www.example.com
dig @localhost -p 5353 api.example.com

# MX record lookup
dig @localhost -p 5353 example.com MX

# All records
dig @localhost -p 5353 example.com ANY
```

### Query External Domains (Forwarded to 8.8.8.8)
```bash
dig @localhost -p 5353 google.com
dig @localhost -p 5353 github.com
```

### Using the Makefile
```bash
make test-dns
```

## Viewing Logs and Metrics

### Via Loki API
```bash
# Query recent logs
curl "http://localhost:3100/loki/api/v1/query_range?query={service=\"coredns\"}&limit=10"
```

### Via Grafana
1. Navigate to **Explore** (compass icon in left sidebar)
2. Select **Loki** as the data source
3. Enter query: `{service="coredns"}`
4. Click "Run query"

## Generating Test Traffic

To generate continuous DNS query traffic for testing:

```bash
# Simple loop
for i in {1..100}; do 
  dig @localhost -p 5353 www.example.com +short > /dev/null
  sleep 1
done
```

Or use a more realistic pattern:

```bash
# Mix of different queries
while true; do
  dig @localhost -p 5353 www.example.com +short > /dev/null
  dig @localhost -p 5353 api.example.com +short > /dev/null
  dig @localhost -p 5353 db.example.com +short > /dev/null
  sleep 2
done
```

## Verifying the Pipeline

### Check Vector is collecting logs
```bash
docker compose logs vector -f
```

You should see logs being ingested from CoreDNS.

### Check Loki has data
```bash
curl -s "http://localhost:3100/loki/api/v1/labels"
```

Expected output should include: `["container","log_type","service"]`

### Check CoreDNS metrics
```bash
curl -s "http://localhost:9153/metrics" | grep coredns_dns
```

## Stopping the Stack

```bash
# Stop all services
docker compose down

# Or using Makefile
make down
```

## Cleaning Up

To remove all data and start fresh:

```bash
# Stop services and remove volumes (WARNING: deletes all data)
docker compose down -v

# Or using Makefile
make clean
```

## Common Issues

### Port 53 Already in Use
By default, CoreDNS runs on port 5353 to avoid conflicts with systemd-resolved or other DNS servers. If you need to use port 53, either:

1. Stop the conflicting service:
   ```bash
   sudo systemctl stop systemd-resolved
   ```

2. Or modify `docker-compose.yml` to use a different port

### Services Not Starting
Check service logs:
```bash
docker compose logs <service-name>
```

Common services to check: `coredns`, `vector`, `loki`, `mimir`, `tempo`, `grafana`

### No Data in Grafana
1. Verify Vector is running: `docker compose ps vector`
2. Check Vector logs: `docker compose logs vector`
3. Verify Loki has data: `curl "http://localhost:3100/loki/api/v1/labels"`
4. Refresh the Grafana dashboard or adjust the time range

## Next Steps

- Customize DNS zones by adding files to `coredns/zones/`
- Modify Vector pipelines in `vector/vector.yaml`
- Create custom Grafana dashboards
- Configure alerting rules in Mimir
- Explore traces in Tempo

For more information, see the main [README.md](README.md).
