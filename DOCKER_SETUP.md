# Docker Hub Setup for GitHub Actions

This guide explains how to set up Docker Hub integration with GitHub Actions for automated image building and pushing.

## 🔑 Required Secrets

You need to add the following secrets to your GitHub repository:

### 1. DOCKERHUB_USERNAME
- Your Docker Hub username
- Go to your GitHub repository → Settings → Secrets and variables → Actions
- Click "New repository secret"
- Name: `DOCKERHUB_USERNAME`
- Value: Your Docker Hub username

### 2. DOCKERHUB_TOKEN
- Your Docker Hub access token (not your password)
- Go to [Docker Hub](https://hub.docker.com/settings/security)
- Click "New Access Token"
- Give it a name (e.g., "GitHub Actions")
- Copy the token
- Go to your GitHub repository → Settings → Secrets and variables → Actions
- Click "New repository secret"
- Name: `DOCKERHUB_TOKEN`
- Value: The access token you just created

## 🚀 How It Works

### Trigger Events
The workflow runs on:
- **Push** to `main` or `develop` branches
- **Pull Request** to `main` branch
- **Release** published

### Workflow Steps

1. **Build and Test**
   - Sets up JDK 11
   - Runs Maven tests
   - Builds the application
   - Uploads test results as artifacts

2. **Build and Push Docker Image**
   - Sets up Docker Buildx
   - Logs in to Docker Hub
   - Builds multi-platform image (amd64, arm64)
   - Pushes to Docker Hub with appropriate tags

### Image Tags
The workflow automatically creates tags based on:
- **Branch name** (e.g., `main`, `develop`)
- **Git SHA** (e.g., `main-abc123`)
- **Semantic version** (if release)
- **Major.Minor version** (if release)

## 📦 Image Details

- **Registry**: `docker.io`
- **Repository**: `h4mmad/spring-boot-app`
- **Base Image**: `openjdk:11-jre-slim`
- **Multi-stage Build**: Yes (optimized for size)
- **Security**: Non-root user, health checks
- **Platforms**: Linux AMD64, ARM64

## 🔍 Example Image Tags

After a push to main branch:
```
h4mmad/spring-boot-app:main
h4mmad/spring-boot-app:main-abc123def
```

After a release v1.2.3:
```
h4mmad/spring-boot-app:1.2.3
h4mmad/spring-boot-app:1.2
```

## 🛠️ Local Testing

You can test the Docker build locally:

```bash
# Build the image
docker build -t h4mmad/spring-boot-app:test .

# Run the container
docker run -p 9191:9191 h4mmad/spring-boot-app:test

# Test the health endpoint
curl http://localhost:9191/actuator/health
```

## 🔧 Customization

### Change Image Name
Edit the workflow file:
```yaml
env:
  REGISTRY: docker.io
  IMAGE_NAME: your-username/your-app-name
```

### Add More Platforms
```yaml
platforms: linux/amd64,linux/arm64,linux/arm/v7
```

### Custom Tags
```yaml
tags: |
  type=ref,event=branch
  type=ref,event=pr
  type=semver,pattern={{version}}
  type=raw,value=latest,enable={{is_default_branch}}
```

## 🚨 Troubleshooting

### Common Issues

1. **Authentication Failed**
   - Check your Docker Hub credentials
   - Ensure the access token has write permissions

2. **Build Fails**
   - Check the Dockerfile syntax
   - Verify all dependencies are available

3. **Push Fails**
   - Check Docker Hub rate limits
   - Verify repository permissions

### Debug Commands
```bash
# Check if secrets are set (in workflow)
echo "Username: ${{ secrets.DOCKERHUB_USERNAME }}"
echo "Token: ${{ secrets.DOCKERHUB_TOKEN }}"

# Test Docker Hub login locally
docker login -u your-username -p your-token
```

## 📋 Next Steps

After setting up Docker Hub integration:

1. **Push to main branch** to trigger the workflow
2. **Check the Actions tab** to monitor the build
3. **Verify the image** is pushed to Docker Hub
4. **Use the image** in your Kubernetes deployments

The workflow will automatically build and push your Spring Boot application to Docker Hub on every push to main or develop branches! 🎉 