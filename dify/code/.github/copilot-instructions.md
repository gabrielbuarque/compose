# Dify Docker Compose Deployment - AI Coding Assistant Instructions

## Architecture Overview

This is a multi-service Docker Compose deployment for Dify, an AI application platform. The system consists of:

- **Core Services**: API server, worker processes, web frontend, PostgreSQL database, Redis cache
- **Security**: Nginx reverse proxy, SSRF proxy for sandboxed code execution, Certbot SSL management
- **Extensibility**: Plugin daemon, multiple vector database options, sandbox environment
- **Configuration**: Environment-driven setup with extensive `.env` variables

## Key Architectural Patterns

### Service Communication
- **Internal Network**: Services communicate via Docker networks (`ssrf_proxy_network`, `default`)
- **Reverse Proxy**: Nginx routes `/api`, `/console/api`, `/files` to API service, `/` to web service
- **Security Isolation**: Sandbox and SSRF proxy run in isolated network to prevent SSRF attacks

### Configuration Management
- **Environment Variables**: All configuration via `.env` file (copy from `.env.example`)
- **Template System**: Nginx, Squid configs use variable substitution
- **Profile-Based Deployment**: Use `--profile` flag for optional services (certbot, vector databases)

### Data Persistence
- **Named Volumes**: `./volumes/` directory for database and service data
- **Vector Stores**: Multiple options (Weaviate, Qdrant, Milvus, etc.) selectable via `VECTOR_STORE`

## Critical Developer Workflows

### Initial Deployment
```bash
# 1. Setup environment
cp .env.example .env
# Edit .env with your configuration

# 2. Start services
docker compose up -d

# 3. Check logs
docker compose logs -f
```

### SSL Certificate Setup
```bash
# Enable certbot profile
docker compose --profile certbot up -d

# Generate certificates
docker compose exec -it certbot /bin/sh /update-cert.sh

# Enable HTTPS in .env
echo "NGINX_HTTPS_ENABLED=true" >> .env
docker compose --profile certbot up -d --no-deps --force-recreate nginx
```

### Development with Middleware Only
```bash
# Copy middleware config
cp middleware.env.example middleware.env

# Start middleware services
docker-compose -f docker-compose.middleware.yaml up -d
```

### Vector Database Switching
```bash
# Set in .env
echo "VECTOR_STORE=weaviate" >> .env
# or VECTOR_STORE=qdrant, milvus, etc.

# Restart with new vector store
docker compose up -d
```

## Project-Specific Conventions

### File Organization
- **Templates**: `.template` files in service directories (nginx, ssrf_proxy) use variable substitution
- **Auto-generated**: `docker-compose.yaml` is generated from templates - do not edit directly
- **Environment Files**: Separate `.env` for main deployment, `middleware.env` for development

### Naming Patterns
- **Service Names**: `api`, `worker`, `web`, `db`, `redis`, `sandbox`, `ssrf_proxy`
- **Volume Paths**: `./volumes/{service}/data` for persistence
- **Network Names**: `ssrf_proxy_network` (internal), `default` (external access)

### Environment Variables
- **Database**: `DB_HOST=db`, `DB_PORT=5432`, `DB_DATABASE=dify`
- **Redis**: `REDIS_HOST=redis`, `REDIS_PORT=6379`
- **API URLs**: `CONSOLE_API_URL`, `SERVICE_API_URL`, `APP_WEB_URL`
- **Security**: `SECRET_KEY`, `REDIS_PASSWORD=difyai123456`

### Docker Patterns
- **Health Checks**: All services have health checks for proper startup ordering
- **Depends On**: Services wait for dependencies via `condition: service_healthy`
- **Profiles**: Optional services activated via `--profile {name}`
- **Entrypoints**: Custom entrypoint scripts for configuration templating

## Integration Points

### Vector Databases
- **Weaviate**: Default, `WEAVIATE_ENDPOINT=http://weaviate:8080`
- **Qdrant**: `QDRANT_URL=http://qdrant:6333`
- **Milvus**: `MILVUS_URI=http://host.docker.internal:19530`
- **Others**: Chroma, Elasticsearch, OpenSearch, etc.

### External Dependencies
- **PostgreSQL**: Main database with pgvector support
- **Redis**: Caching and Celery broker
- **Nginx**: Reverse proxy with SSL termination
- **Certbot**: Let's Encrypt certificate management

### Plugin System
- **Plugin Daemon**: Runs on port 5002, manages plugin installation
- **Inner API**: `PLUGIN_DIFY_INNER_API_URL=http://api:5001`
- **Storage**: Configurable plugin storage (local, S3, Azure, etc.)

## Common Development Tasks

### Debugging Services
```bash
# Check service status
docker compose ps

# View logs
docker compose logs {service_name}

# Execute commands
docker compose exec {service_name} bash
```

### Configuration Changes
```bash
# Edit .env, then restart
docker compose up -d --no-deps {service_name}

# Or restart all
docker compose restart
```

### Adding New Services
1. Add service definition to `docker-compose.yaml`
2. Add environment variables to `.env.example`
3. Update `README.md` with deployment instructions
4. Add health checks and dependencies

### SSL Troubleshooting
```bash
# Check certbot logs
docker compose --profile certbot logs certbot

# Renew certificates
docker compose exec -it certbot /bin/sh /update-cert.sh
docker compose exec nginx nginx -s reload
```

## Security Considerations

### Network Isolation
- **Internal Networks**: `ssrf_proxy_network` prevents external access to sandbox
- **SSRF Protection**: All outbound requests proxy through squid with allowlists
- **API Keys**: Generate strong keys for `SANDBOX_API_KEY`, `PLUGIN_DAEMON_KEY`

### SSL Configuration
- **Certificate Paths**: `/etc/letsencrypt/live/{domain}/`
- **Protocols**: TLS 1.1-1.3 enabled by default
- **HSTS**: Configure via nginx templates

## Performance Tuning

### Database
- **Connections**: `POSTGRES_MAX_CONNECTIONS=100`
- **Memory**: `POSTGRES_SHARED_BUFFERS=128MB`, `POSTGRES_EFFECTIVE_CACHE_SIZE=4096MB`
- **Workers**: `POSTGRES_WORK_MEM=4MB`, `POSTGRES_MAINTENANCE_WORK_MEM=64MB`

### Application
- **Workers**: `SERVER_WORKER_AMOUNT=1`, `CELERY_WORKER_AMOUNT`
- **Timeouts**: `GUNICORN_TIMEOUT=360`, `WORKFLOW_MAX_EXECUTION_TIME=1200`
- **Limits**: `UPLOAD_FILE_SIZE_LIMIT=15MB`, `MAX_TOOLS_NUM=10`

## Troubleshooting Patterns

### Service Startup Issues
1. Check `docker compose logs {service}`
2. Verify environment variables in `.env`
3. Check health check status: `docker compose ps`
4. Ensure dependencies are healthy

### Network Issues
1. Verify network connectivity: `docker compose exec {service} ping {target}`
2. Check nginx configuration: `docker compose exec nginx nginx -t`
3. Review firewall rules and port mappings

### Database Issues
1. Check PostgreSQL logs: `docker compose logs db`
2. Verify connection string in `.env`
3. Test connectivity: `docker compose exec db pg_isready`

Remember: This deployment uses auto-generated configurations. Always modify `.env.example` or template files, not the generated `docker-compose.yaml`.