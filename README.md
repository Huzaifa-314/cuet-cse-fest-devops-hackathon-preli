# E-Commerce Microservices - Docker Setup

A fully containerized microservices architecture with Docker, featuring a product management backend, API gateway, and MongoDB database.

## 🏗️ Architecture

```
                    ┌─────────────────┐
                    │   Client/User   │
                    └────────┬────────┘
                             │
                             │ HTTP (port 5921)
                             │
                    ┌────────▼────────┐
                    │    Gateway      │
                    │  (port 5921)    │
                    │   [Exposed]     │
                    └────────┬────────┘
                             │
                    ┌────────┴────────┐
                    │                 │
         ┌──────────▼──────────┐      │
         │   Private Network   │      │
         │  (Docker Network)   │      │
         └──────────┬──────────┘      │
                    │                 │
         ┌──────────┴──────────┐      │
         │                     │      │
    ┌────▼────┐         ┌──────▼──────┐
    │ Backend │         │   MongoDB   │
    │(port    │◄────────┤  (port      │
    │ 3847)   │         │  27017)     │
    │[Not     │         │ [Not        │
    │Exposed] │         │ Exposed]    │
    └─────────┘         └─────────────┘
```

**Key Points:**
- Gateway is the only service exposed to external clients (port 5921)
- All external requests must go through the Gateway
- Backend and MongoDB are not exposed to public network
- Data persistence via Docker volumes

## 📁 Project Structure

```
.
├── backend/
│   ├── Dockerfile              # Production multi-stage build
│   ├── Dockerfile.dev          # Development with hot-reload
│   ├── .dockerignore          # Files excluded from build
│   ├── package.json
│   ├── tsconfig.json
│   └── src/
│       ├── config/
│       ├── models/
│       ├── routes/
│       └── types/
├── gateway/
│   ├── Dockerfile              # Production build
│   ├── Dockerfile.dev          # Development with hot-reload
│   ├── .dockerignore          # Files excluded from build
│   ├── package.json
│   └── src/
│       └── gateway.js
├── docker/
│   ├── compose.development.yaml  # Development configuration
│   └── compose.production.yaml   # Production configuration
├── Makefile                    # CLI commands
├── .env                        # Environment variables (not committed)
└── README.md
```

## 🚀 Quick Start

### Prerequisites

- Docker Desktop (or Docker Engine + Docker Compose V2)
  - **Note**: This project uses `docker compose` (space) command, which is the newer Docker Compose V2 syntax
  - If you have the older `docker-compose` (hyphen), you may need to install Docker Compose V2 or create an alias
- Make (optional, for using Makefile commands)
- Git

### Setup

1. **Clone the repository**
   ```bash
   git clone https://github.com/Huzaifa-314/cuet-cse-fest-devops-hackathon-preli
   cd cuet-cse-fest-devops-hackathon-preli
   ```

2. **Create `.env` file**
   ```bash
   # Copy and edit with your values
   cp .env.example .env  # If available, or create manually
   
   # Or edit the .env file directly
   nano .env  # On Linux/Mac
   # On Windows, use: notepad .env
   ```

3. **Configure environment variables**
   ```env
   # MongoDB Configuration
   MONGO_INITDB_ROOT_USERNAME=admin
   MONGO_INITDB_ROOT_PASSWORD=your_secure_password
   MONGO_URI=mongodb://admin:your_secure_password@mongo:27017/ecommerce?authSource=admin
   MONGO_DATABASE=ecommerce

   # Service Ports (DO NOT CHANGE)
   BACKEND_PORT=3847
   BACKEND_URL=http://backend:3847
   GATEWAY_PORT=5921

   # Environment
   NODE_ENV=development  # or production
   ```

4. **Start development environment**
   ```bash
   make dev-up
   # Or manually:
   docker-compose -f docker/compose.development.yaml up -d
   ```

5. **Verify services are running**
   ```bash
   make health MODE=dev
   # Or manually:
   curl http://localhost:5921/health
   ```

## 🛠️ Makefile Commands

### Service Management

```bash
# Start services
make up [service...]              # Start services (default: dev)
make up MODE=prod                 # Start production services
make up ARGS="--build"            # Start with build

# Stop services
make down [service...]            # Stop services
make down MODE=prod               # Stop production services
make down ARGS="--volumes"        # Stop and remove volumes

# Build containers
make build [service...]           # Build containers
make build MODE=prod              # Build production containers

# View logs
make logs SERVICE=backend         # View logs for a service
make logs SERVICE=gateway MODE=prod

# Restart services
make restart [service...]         # Restart services
make restart MODE=prod

# Show running containers
make ps                          # Show containers
make ps MODE=prod

# Open shell in container
make shell SERVICE=backend         # Open shell (default: backend)
make shell SERVICE=gateway MODE=prod
```

### Development Aliases

```bash
make dev-up                      # Start development environment
make dev-down                    # Stop development environment
make dev-build                   # Build development containers
make dev-logs SERVICE=backend    # View development logs
make dev-restart                 # Restart development services
make dev-ps                      # Show development containers
make backend-shell               # Open shell in backend container
make gateway-shell               # Open shell in gateway container
make mongo-shell                 # Open MongoDB shell
```

### Production Aliases

```bash
make prod-up                     # Start production environment
make prod-down                   # Stop production environment
make prod-build                  # Build production containers
make prod-logs SERVICE=backend   # View production logs
make prod-restart                # Restart production services
make prod-ps                     # Show production containers
```

### Backend Commands

```bash
make backend-build               # Build TypeScript
make backend-install             # Install dependencies
make backend-type-check          # Type check code
make backend-dev                 # Run locally (not Docker)
```

### Database Commands

```bash
make db-backup                   # Backup MongoDB database
make db-reset FORCE=yes          # Reset database (WARNING: deletes all data)
```

### Cleanup Commands

```bash
make clean                       # Remove containers and networks
make clean-all FORCE=yes         # Remove everything (containers, networks, volumes, images)
make clean-volumes FORCE=yes     # Remove all volumes
```

### Utilities

```bash
make health MODE=dev             # Check service health
make status MODE=prod            # Show container status
make help                        # Display help message
```

## 🧪 Testing

### Health Checks

```bash
# Gateway health
curl http://localhost:5921/health

# Backend health via gateway
curl http://localhost:5921/api/health
```

### Product Management

```bash
# Create a product
curl -X POST http://localhost:5921/api/products \
  -H 'Content-Type: application/json' \
  -d '{"name":"Test Product","price":99.99}'

# Get all products
curl http://localhost:5921/api/products

# Get product by ID
curl http://localhost:5921/api/products/<product-id>

# Update product
curl -X PUT http://localhost:5921/api/products/<product-id> \
  -H 'Content-Type: application/json' \
  -d '{"name":"Updated Product","price":149.99}'

# Delete product
curl -X DELETE http://localhost:5921/api/products/<product-id>
```

### Security Test

```bash
# Should fail - backend not directly accessible
curl http://localhost:3847/api/products
```

### Data Persistence Test

```bash
# 1. Create a product
curl -X POST http://localhost:5921/api/products \
  -H 'Content-Type: application/json' \
  -d '{"name":"Persistence Test","price":199.99}'

# 2. Stop containers
make dev-down

# 3. Start containers
make dev-up

# 4. Verify product still exists
curl http://localhost:5921/api/products
```

## 🔒 Security Features

- **Network Isolation**: Backend and MongoDB are not exposed to external networks
- **Single Entry Point**: Only gateway is exposed (port 5921)
- **Non-root Users**: All containers run as non-root users
- **Environment Variables**: Sensitive data stored in `.env` file (not committed)
- **No Hardcoded Credentials**: All credentials come from environment variables
- **Input Validation**: Express JSON parsing and validation


## 🔧 Development vs Production

### Development
- Hot-reload enabled (volume mounts for source code)
- All dependencies installed (including dev dependencies)
- More verbose logging
- Faster startup times

### Production
- Multi-stage builds for smaller images
- Production dependencies only
- Optimized layer caching
- Resource limits configured
- Health checks with longer intervals
- Log rotation configured

## 🐛 Troubleshooting

### Docker Compose command not found

If you get `docker-compose: No such file or directory`:

```bash
# Check if you have Docker Compose V2 (newer version)
docker compose version

# If not available, install Docker Compose V2 or create an alias:
# Option 1: Install Docker Compose V2 plugin
# Option 2: Create alias (temporary fix)
alias docker-compose='docker compose'

# Or update the Makefile to use 'docker-compose' if you have the standalone version
```

### Services won't start
```bash
# Check logs
make dev-logs SERVICE=backend
make dev-logs SERVICE=gateway
make dev-logs SERVICE=mongo

# Check container status
make dev-ps

# Restart services
make dev-restart
```

### MongoDB connection issues
```bash
# Check MongoDB logs
make dev-logs SERVICE=mongo

# Verify environment variables
docker exec backend-dev env | grep MONGO

# Test MongoDB connection
make mongo-shell
```

### Port conflicts
```bash
# Check what's using the ports
netstat -ano | findstr :5921
netstat -ano | findstr :3847

# Stop conflicting services or change ports in .env
```

### Data persistence issues
```bash
# Check volume exists
docker volume ls | grep mongo

# Inspect volume
docker volume inspect mongo-dev-data

# Reset database (WARNING: deletes data)
make db-reset FORCE=yes
```

## 📚 Additional Resources

- [Docker Documentation](https://docs.docker.com/)
- [Docker Compose Documentation](https://docs.docker.com/compose/)
- [MongoDB Documentation](https://docs.mongodb.com/)
- [Node.js Best Practices](https://github.com/goldbergyoni/nodebestpractices)

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## 📄 License

This project is part of a hackathon challenge.


---

**Good luck with the hackathon! 🚀**
