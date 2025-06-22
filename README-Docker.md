# Docker Deployment Guide

## Security Requirements Compliance

This Docker setup meets all production security requirements:

### ✅ 1. Slim Base Images
- **Build stage**: Uses `maven:3.8.4-openjdk-8-slim` (optimized Maven image)
- **Runtime stage**: Uses `openjdk:8-jre-alpine` (minimal Alpine Linux)

### ✅ 2. Multi-stage Builds
- **Build stage**: Compiles application with Maven
- **Runtime stage**: Contains only JAR and runtime dependencies
- **Result**: Significantly smaller production image

### ✅ 3. Secure Environment Variables & Secrets
- **Single `.env` file** for all environments
- **No hardcoded passwords** in configuration files
- **Environment variables** for all sensitive data

### ✅ 4. Health Checks
- **Built-in health monitoring** with configurable intervals
- **Checks application health endpoint** at `/actuator/health`
- **Proper timeout and retry configuration**

## Setup Instructions

### Quick Start:

1. **Copy environment template:**
   ```bash
   cp env.example .env
   ```

2. **Edit `.env` file** with your configuration:
   ```bash
   nano .env
   ```

3. **Run the application:**
   ```bash
   docker-compose up --build
   ```

## Environment Configuration

### Required Variables:
- `DB_PASSWORD` - Database password
- `MYSQL_ROOT_PASSWORD` - MySQL root password

### Optional Variables (with defaults):
- `DB_HOST=mysql` - Database host
- `DB_PORT=3306` - Database port  
- `DB_NAME=javatechie` - Database name
- `DB_USERNAME=root` - Database username
- `APP_PORT=9191` - Application port
- `JPA_DDL_AUTO=update` - JPA DDL mode
- `MYSQL_DATABASE=javatechie` - MySQL database name
- `MYSQL_PORT=3306` - MySQL port
- `SPRING_PROFILES_ACTIVE=default` - Spring profile
- `SPRING_JPA_SHOW_SQL=true` - SQL logging

## Environment-Specific Settings

### For Development:
```bash
# In your .env file
JPA_DDL_AUTO=update
SPRING_JPA_SHOW_SQL=true
SPRING_PROFILES_ACTIVE=development
```

### For Production:
```bash
# In your .env file
JPA_DDL_AUTO=validate
SPRING_JPA_SHOW_SQL=false
SPRING_PROFILES_ACTIVE=production
```

## Security Features

- **Non-root user**: Application runs as `appuser` (UID 1001)
- **Environment variables**: All sensitive data in `.env` file
- **Network isolation**: Services communicate via internal network
- **Minimal attack surface**: Alpine-based runtime with minimal packages
- **Health monitoring**: Built-in health checks for container monitoring
- **No secrets files needed**: Simple `.env` file approach

## Usage

- **Application**: http://localhost:9191
- **Database**: localhost:3306 (MySQL)
- **Health Check**: http://localhost:9191/actuator/health

## Quick Commands

```bash
# Start services
docker-compose up --build

# Start in background
docker-compose up -d --build

# Stop services
docker-compose down

# View logs
docker-compose logs -f app

# View logs for specific service
docker-compose logs -f mysql
```

## Troubleshooting

### Common Issues:

1. **Port already in use**: Change `APP_PORT` in `.env`
2. **Database connection failed**: Check `DB_PASSWORD` and `MYSQL_ROOT_PASSWORD`
3. **Permission denied**: Ensure `.env` file has correct permissions

### Reset Everything:
```bash
# Stop and remove everything
docker-compose down -v

# Remove all images
docker-compose down --rmi all

# Start fresh
docker-compose up --build
``` 