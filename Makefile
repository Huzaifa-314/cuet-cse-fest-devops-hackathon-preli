# Docker Services:
#   up - Start services (use: make up [service...] or make up MODE=prod, ARGS="--build" for options)
#   down - Stop services (use: make down [service...] or make down MODE=prod, ARGS="--volumes" for options)
#   build - Build containers (use: make build [service...] or make build MODE=prod)
#   logs - View logs (use: make logs [service] or make logs SERVICE=backend, MODE=prod for production)
#   restart - Restart services (use: make restart [service...] or make restart MODE=prod)
#   shell - Open shell in container (use: make shell [service] or make shell SERVICE=gateway, MODE=prod, default: backend)
#   ps - Show running containers (use MODE=prod for production)
#
# Convenience Aliases (Development):
#   dev-up - Alias: Start development environment
#   dev-down - Alias: Stop development environment
#   dev-build - Alias: Build development containers
#   dev-logs - Alias: View development logs
#   dev-restart - Alias: Restart development services
#   dev-shell - Alias: Open shell in backend container
#   dev-ps - Alias: Show running development containers
#   backend-shell - Alias: Open shell in backend container
#   gateway-shell - Alias: Open shell in gateway container
#   mongo-shell - Open MongoDB shell
#
# Convenience Aliases (Production):
#   prod-up - Alias: Start production environment
#   prod-down - Alias: Stop production environment
#   prod-build - Alias: Build production containers
#   prod-logs - Alias: View production logs
#   prod-restart - Alias: Restart production services
#
# Backend:
#   backend-build - Build backend TypeScript
#   backend-install - Install backend dependencies
#   backend-type-check - Type check backend code
#   backend-dev - Run backend in development mode (local, not Docker)
#
# Database:
#   db-reset - Reset MongoDB database (WARNING: deletes all data)
#   db-backup - Backup MongoDB database
#
# Cleanup:
#   clean - Remove containers and networks (both dev and prod)
#   clean-all - Remove containers, networks, volumes, and images
#   clean-volumes - Remove all volumes
#
# Utilities:
#   status - Alias for ps
#   health - Check service health
#
# Help:
#   help - Display this help message

# Default mode (dev or prod)
MODE ?= dev
SERVICE ?= backend
ARGS ?=

# Compose file paths
COMPOSE_DEV = docker/compose.development.yaml
COMPOSE_PROD = docker/compose.production.yaml

# Determine compose file based on MODE
ifeq ($(MODE),prod)
	COMPOSE_FILE = $(COMPOSE_PROD)
	CONTAINER_PREFIX = -prod
else
	COMPOSE_FILE = $(COMPOSE_DEV)
	CONTAINER_PREFIX = -dev
endif

# Default target
.DEFAULT_GOAL := help

# Core Service Management Commands
.PHONY: up
up:
	@echo "Starting services in $(MODE) mode..."
	docker-compose -f $(COMPOSE_FILE) up -d $(ARGS) $(filter-out $@,$(MAKECMDGOALS))

.PHONY: down
down:
	@echo "Stopping services in $(MODE) mode..."
	docker-compose -f $(COMPOSE_FILE) down $(ARGS) $(filter-out $@,$(MAKECMDGOALS))

.PHONY: build
build:
	@echo "Building containers in $(MODE) mode..."
	docker-compose -f $(COMPOSE_FILE) build $(ARGS) $(filter-out $@,$(MAKECMDGOALS))

.PHONY: logs
logs:
	@echo "Viewing logs for $(SERVICE) in $(MODE) mode..."
	docker-compose -f $(COMPOSE_FILE) logs -f $(SERVICE)

.PHONY: restart
restart:
	@echo "Restarting services in $(MODE) mode..."
	docker-compose -f $(COMPOSE_FILE) restart $(filter-out $@,$(MAKECMDGOALS))

.PHONY: shell
shell:
	@echo "Opening shell in $(SERVICE)$(CONTAINER_PREFIX) container..."
	docker exec -it $(SERVICE)$(CONTAINER_PREFIX) sh

.PHONY: ps
ps:
	@echo "Running containers in $(MODE) mode:"
	docker-compose -f $(COMPOSE_FILE) ps

# Development Aliases
.PHONY: dev-up
dev-up:
	@$(MAKE) up MODE=dev ARGS="$(ARGS)"

.PHONY: dev-down
dev-down:
	@$(MAKE) down MODE=dev ARGS="$(ARGS)"

.PHONY: dev-build
dev-build:
	@$(MAKE) build MODE=dev ARGS="$(ARGS)"

.PHONY: dev-logs
dev-logs:
	@$(MAKE) logs MODE=dev SERVICE="$(SERVICE)"

.PHONY: dev-restart
dev-restart:
	@$(MAKE) restart MODE=dev

.PHONY: dev-ps
dev-ps:
	@$(MAKE) ps MODE=dev

.PHONY: dev-shell
dev-shell:
	@$(MAKE) shell MODE=dev SERVICE="$(SERVICE)"

.PHONY: backend-shell
backend-shell:
	@$(MAKE) shell MODE=dev SERVICE=backend

.PHONY: gateway-shell
gateway-shell:
	@$(MAKE) shell MODE=dev SERVICE=gateway

.PHONY: mongo-shell
mongo-shell:
	@echo "Opening MongoDB shell..."
	docker exec -it mongo$(CONTAINER_PREFIX) mongosh -u $$(docker exec mongo$(CONTAINER_PREFIX) printenv MONGO_INITDB_ROOT_USERNAME) -p $$(docker exec mongo$(CONTAINER_PREFIX) printenv MONGO_INITDB_ROOT_PASSWORD) --authenticationDatabase admin

# Production Aliases
.PHONY: prod-up
prod-up:
	@$(MAKE) up MODE=prod ARGS="$(ARGS)"

.PHONY: prod-down
prod-down:
	@$(MAKE) down MODE=prod ARGS="$(ARGS)"

.PHONY: prod-build
prod-build:
	@$(MAKE) build MODE=prod ARGS="$(ARGS)"

.PHONY: prod-logs
prod-logs:
	@$(MAKE) logs MODE=prod SERVICE="$(SERVICE)"

.PHONY: prod-restart
prod-restart:
	@$(MAKE) restart MODE=prod

.PHONY: prod-ps
prod-ps:
	@$(MAKE) ps MODE=prod

# Backend Commands
.PHONY: backend-build
backend-build:
	@echo "Building TypeScript in backend..."
	cd backend && npm run build

.PHONY: backend-install
backend-install:
	@echo "Installing backend dependencies..."
	cd backend && npm install

.PHONY: backend-type-check
backend-type-check:
	@echo "Type checking backend code..."
	cd backend && npm run type-check

.PHONY: backend-dev
backend-dev:
	@echo "Running backend in development mode (local)..."
	cd backend && npm run dev

# Database Commands
.PHONY: db-reset
db-reset:
	@if [ "$(FORCE)" != "yes" ]; then \
		echo "WARNING: This will delete all data in MongoDB!"; \
		echo "Use 'make db-reset FORCE=yes' to skip confirmation."; \
		exit 1; \
	fi
	@echo "Resetting database..."
	@docker-compose -f $(COMPOSE_FILE) stop mongo || true
	@docker-compose -f $(COMPOSE_FILE) rm -f mongo || true
	@docker volume rm mongo$(CONTAINER_PREFIX)-data 2>/dev/null || true
	@docker-compose -f $(COMPOSE_FILE) up -d mongo
	@echo "Database reset complete."

.PHONY: db-backup
db-backup:
	@echo "Backing up MongoDB database..."
	@mkdir -p backups
	@docker exec mongo$(CONTAINER_PREFIX) mongodump \
		--username $$(docker exec mongo$(CONTAINER_PREFIX) printenv MONGO_INITDB_ROOT_USERNAME) \
		--password $$(docker exec mongo$(CONTAINER_PREFIX) printenv MONGO_INITDB_ROOT_PASSWORD) \
		--authenticationDatabase admin \
		--db $$(docker exec mongo$(CONTAINER_PREFIX) printenv MONGO_INITDB_DATABASE) \
		--archive > backups/backup-$$(date +%Y%m%d-%H%M%S).archive
	@echo "Backup saved to backups/backup-$$(date +%Y%m%d-%H%M%S).archive"

# Cleanup Commands
.PHONY: clean
clean:
	@echo "Removing containers and networks..."
	docker-compose -f $(COMPOSE_DEV) down
	docker-compose -f $(COMPOSE_PROD) down
	@echo "Cleanup complete."

.PHONY: clean-all
clean-all:
	@if [ "$(FORCE)" != "yes" ]; then \
		echo "WARNING: This will remove containers, networks, volumes, and images!"; \
		echo "Use 'make clean-all FORCE=yes' to skip confirmation."; \
		exit 1; \
	fi
	@echo "Removing everything..."
	@docker-compose -f $(COMPOSE_DEV) down -v --rmi all || true
	@docker-compose -f $(COMPOSE_PROD) down -v --rmi all || true
	@docker system prune -af
	@echo "Cleanup complete."

.PHONY: clean-volumes
clean-volumes:
	@if [ "$(FORCE)" != "yes" ]; then \
		echo "WARNING: This will remove all volumes!"; \
		echo "Use 'make clean-volumes FORCE=yes' to skip confirmation."; \
		exit 1; \
	fi
	@echo "Removing volumes..."
	@docker-compose -f $(COMPOSE_DEV) down -v || true
	@docker-compose -f $(COMPOSE_PROD) down -v || true
	@docker volume prune -f
	@echo "Volumes removed."

# Utilities
.PHONY: status
status:
	@$(MAKE) ps MODE=$(MODE)

.PHONY: health
health:
	@echo "Checking service health..."
	@echo ""
	@echo "Gateway Health:"
	@curl -s http://localhost:5921/health || echo "Gateway not responding"
	@echo ""
	@echo "Backend Health (via Gateway):"
	@curl -s http://localhost:5921/api/health || echo "Backend not responding"
	@echo ""
	@echo "Container Status:"
	@docker-compose -f $(COMPOSE_FILE) ps

.PHONY: help
help:
	@echo "Docker Services:"
	@echo "  make up [service...]              - Start services (use MODE=prod for production)"
	@echo "  make down [service...]            - Stop services (use MODE=prod for production)"
	@echo "  make build [service...]            - Build containers (use MODE=prod for production)"
	@echo "  make logs [SERVICE=name]          - View logs (use MODE=prod for production)"
	@echo "  make restart [service...]         - Restart services (use MODE=prod for production)"
	@echo "  make shell [SERVICE=name]         - Open shell in container (default: backend)"
	@echo "  make ps                           - Show running containers (use MODE=prod for production)"
	@echo ""
	@echo "Development Aliases:"
	@echo "  make dev-up                       - Start development environment"
	@echo "  make dev-down                     - Stop development environment"
	@echo "  make dev-build                    - Build development containers"
	@echo "  make dev-logs [SERVICE=name]      - View development logs"
	@echo "  make dev-restart                  - Restart development services"
	@echo "  make dev-ps                       - Show running development containers"
	@echo "  make backend-shell                - Open shell in backend container"
	@echo "  make gateway-shell                - Open shell in gateway container"
	@echo "  make mongo-shell                  - Open MongoDB shell"
	@echo ""
	@echo "Production Aliases:"
	@echo "  make prod-up                      - Start production environment"
	@echo "  make prod-down                    - Stop production environment"
	@echo "  make prod-build                   - Build production containers"
	@echo "  make prod-logs [SERVICE=name]     - View production logs"
	@echo "  make prod-restart                 - Restart production services"
	@echo "  make prod-ps                      - Show running production containers"
	@echo ""
	@echo "Backend Commands:"
	@echo "  make backend-build                - Build TypeScript"
	@echo "  make backend-install              - Install dependencies"
	@echo "  make backend-type-check            - Type check code"
	@echo "  make backend-dev                  - Run locally (not Docker)"
	@echo ""
	@echo "Database Commands:"
	@echo "  make db-reset [FORCE=yes]         - Reset MongoDB database (WARNING: deletes all data)"
	@echo "  make db-backup                    - Backup MongoDB database"
	@echo ""
	@echo "Cleanup:"
	@echo "  make clean                         - Remove containers and networks"
	@echo "  make clean-all [FORCE=yes]         - Remove containers, networks, volumes, and images"
	@echo "  make clean-volumes [FORCE=yes]     - Remove all volumes"
	@echo ""
	@echo "Utilities:"
	@echo "  make status                       - Alias for ps"
	@echo "  make health                       - Check service health"
	@echo "  make help                         - Display this help message"

# Prevent make from treating targets as files
%:
	@:
