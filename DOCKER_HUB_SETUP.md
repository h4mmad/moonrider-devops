# Docker Hub Integration Setup

This guide explains how to set up Docker Hub integration with your GitHub Actions workflow to automatically build and push Docker images.

## Prerequisites

1. A Docker Hub account
2. A Docker Hub repository (will be created automatically if it doesn't exist)
3. GitHub repository with the workflow file

## Step 1: Create Docker Hub Access Token

1. Log in to [Docker Hub](https://hub.docker.com/)
2. Go to **Account Settings** → **Security**
3. Click **New Access Token**
4. Give it a name (e.g., "GitHub Actions")
5. Copy the token (you won't see it again!)

## Step 2: Add GitHub Secrets

In your GitHub repository:

1. Go to **Settings** → **Secrets and variables** → **Actions**
2. Add these secrets:

| Secret Name | Value |
|-------------|-------|
| `DOCKER_USERNAME` | Your Docker Hub username |
| `DOCKER_PASSWORD` | Your Docker Hub access token (not your password!) |

## Step 3: Update Repository Name (Optional)

The workflow uses `${{ github.repository }}` as the image name, which will be:
- `your-username/your-repo-name`

If you want a different image name, update the `IMAGE_NAME` in the workflow:

```yaml
env:
  REGISTRY: docker.io
  IMAGE_NAME: your-dockerhub-username/your-image-name
```

## Step 4: Test the Workflow

1. Push code to the `main` or `develop` branch
2. Go to **Actions** tab in your GitHub repository
3. Watch the workflow run

## How It Works

### Image Tagging Strategy

The workflow creates multiple tags for each build:

- **Branch tags**: `main-abc1234`, `develop-def5678`
- **PR tags**: `pr-123-abc1234`
- **Release tags**: `v1.0.0`, `v1.0`
- **Latest tag**: `latest` (only for main branch)
- **SHA tags**: `abc1234` (commit SHA)

### Example Tags

For a commit `abc1234` on the `main` branch:
```
docker.io/your-username/your-repo:main-abc1234
docker.io/your-username/your-repo:latest
docker.io/your-username/your-repo:abc1234
```

## Manual Deployment

After the GitHub Actions workflow pushes images to Docker Hub, you can deploy to your local microK8s cluster:

### Option 1: Deploy Latest Image
```bash
chmod +x deploy-to-microk8s.sh
./deploy-to-microk8s.sh latest
```

### Option 2: Deploy Specific Tag
```bash
./deploy-to-microk8s.sh main-abc1234
```

### Option 3: Deploy Release Version
```bash
./deploy-to-microk8s.sh v1.0.0
```

## Environment Variables

You can customize the deployment by setting environment variables:

```bash
export DOCKER_REGISTRY=docker.io
export DOCKER_IMAGE_NAME=your-username/your-image
./deploy-to-microk8s.sh latest
```

## Troubleshooting

### Common Issues

1. **Authentication Failed**
   - Check your Docker Hub credentials in GitHub secrets
   - Ensure you're using an access token, not your password

2. **Image Not Found**
   - Verify the image was pushed successfully
   - Check the Docker Hub repository URL in the workflow output

3. **Permission Denied**
   - Ensure your Docker Hub account has permission to push to the repository
   - Check if the repository exists or can be created

### Check Workflow Status

1. Go to **Actions** tab in your GitHub repository
2. Click on the latest workflow run
3. Check the logs for any errors

### Verify Docker Hub Push

1. Go to your Docker Hub repository
2. Check the **Tags** tab for new images
3. Verify the image was pushed with the correct tags

## Security Best Practices

1. **Use Access Tokens**: Never use your Docker Hub password
2. **Token Permissions**: Create tokens with minimal required permissions
3. **Repository Access**: Use private repositories for sensitive applications
4. **Image Scanning**: Enable Docker Hub's vulnerability scanning

## Advanced Configuration

### Multi-Platform Builds

The workflow builds for both `linux/amd64` and `linux/arm64`:
```yaml
platforms: linux/amd64,linux/arm64
```

### Build Caching

The workflow uses GitHub Actions cache for faster builds:
```yaml
cache-from: type=gha
cache-to: type=gha,mode=max
```

### Conditional Deployment

You can add conditions to only deploy on specific events:
```yaml
if: github.event_name == 'push' && github.ref == 'refs/heads/main'
```

## Next Steps

1. **Set up secrets** in your GitHub repository
2. **Push code** to trigger the workflow
3. **Deploy manually** using the deployment script
4. **Monitor** the deployment in your microK8s cluster

For automated deployment to your local cluster, consider setting up a self-hosted GitHub Actions runner as described in `SELF_HOSTED_RUNNER_SETUP.md`. 