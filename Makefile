.PHONY: help up down restart logs ps clean test-dns

help: ## Show this help message
	@echo 'Usage: make [target]'
	@echo ''
	@echo 'Available targets:'
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "  %-15s %s\n", $$1, $$2}' $(MAKEFILE_LIST)

up: ## Start all services
	docker compose up -d
	@echo "Waiting for services to be ready..."
	@sleep 10
	@echo ""
	@echo "Services are starting up. Access points:"
	@echo "  - Grafana: http://localhost:3000 (admin/admin)"
	@echo "  - Loki: http://localhost:3100"
	@echo "  - Tempo: http://localhost:3200"
	@echo "  - Mimir: http://localhost:9009"
	@echo "  - Vector API: http://localhost:8686"
	@echo "  - CoreDNS: localhost:5353"

down: ## Stop all services
	docker compose down

restart: ## Restart all services
	docker compose restart

logs: ## Show logs from all services
	docker compose logs -f

ps: ## Show running services
	docker compose ps

clean: ## Stop services and remove volumes (WARNING: deletes all data)
	docker compose down -v
	@echo "All services stopped and data volumes removed"

test-dns: ## Run DNS query tests
	@echo "Testing example.com zone..."
	@dig @localhost -p 5353 example.com +short || echo "CoreDNS not ready yet"
	@dig @localhost -p 5353 www.example.com +short || echo "CoreDNS not ready yet"
	@dig @localhost -p 5353 api.example.com +short || echo "CoreDNS not ready yet"
	@echo ""
	@echo "Testing forwarding to external DNS..."
	@dig @localhost -p 5353 google.com +short | head -1 || echo "CoreDNS not ready yet"
