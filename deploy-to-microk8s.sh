#!/bin/bash

# Deploy Spring Boot CRUD App to local microK8s cluster
# Usage: ./deploy-to-microk8s.sh [IMAGE_TAG]
# Example: ./deploy-to-microk8s.sh main-abc1234

set -e

# Default image tag if not provided
IMAGE_TAG=${1:-latest}
REGISTRY=${DOCKER_REGISTRY:-docker.io}
IMAGE_NAME=${DOCKER_IMAGE_NAME:-h4mmad/spring-boot-app}

FULL_IMAGE_NAME="$REGISTRY/$IMAGE_NAME:$IMAGE_TAG"

echo "🚀 Deploying to microK8s cluster..."
echo "Image: $FULL_IMAGE_NAME"

# Check if microK8s is running
if ! microk8s status >/dev/null 2>&1; then
    echo "❌ microK8s is not running. Please start it first:"
    echo "   microk8s start"
    exit 1
fi

# Enable required addons
echo "📦 Enabling microK8s addons..."
microk8s enable dns
microk8s enable ingress
microk8s enable metrics-server
microk8s enable storage
microk8s enable registry

# Wait for microK8s to be ready
echo "⏳ Waiting for microK8s to be ready..."
microk8s status --wait-ready
microk8s kubectl wait --for=condition=ready pod -l k8s-app=kube-dns -n kube-system --timeout=300s

# Configure kubectl
echo "🔧 Configuring kubectl..."
microk8s config > ~/.kube/config
chmod 600 ~/.kube/config

# Update image tags in manifests
echo "🔄 Updating image tags in manifests..."
find k8s/ -name "*-app-manifest.yaml" -exec sed -i "s|image: .*spring-boot-app:.*|image: $FULL_IMAGE_NAME|g" {} \;

# Deploy in order
echo "📋 Deploying resources..."

# 1. ConfigMaps and Secrets
echo "   - ConfigMaps and Secrets..."
kubectl apply -f k8s/config-secrets.yaml

# 2. MySQL PVC
echo "   - MySQL PVC..."
kubectl apply -f k8s/mysql-pvc.yaml

# 3. MySQL Deployment
echo "   - MySQL Deployment..."
kubectl apply -f k8s/mysql-deployment.yaml

# Wait for MySQL to be ready
echo "⏳ Waiting for MySQL to be ready..."
kubectl wait --for=condition=ready pod -l app=mysql --timeout=300s

# 4. Application Deployments
echo "   - Application Deployments..."
kubectl apply -f k8s/v1-app-manifest.yaml
kubectl apply -f k8s/v1.1-app-manifest.yaml
kubectl apply -f k8s/v2-app-manifest.yaml

# 5. HPA
echo "   - Horizontal Pod Autoscaler..."
kubectl apply -f k8s/hpa-manifest.yaml

# 6. Ingress
echo "   - Ingress..."
kubectl apply -f k8s/ingress.yaml

# Wait for deployments to be ready
echo "⏳ Waiting for deployments to be ready..."
kubectl wait --for=condition=available --timeout=600s deployment/spring-app-v1-deployment
kubectl wait --for=condition=available --timeout=600s deployment/spring-app-v1.1-deployment
kubectl wait --for=condition=available --timeout=600s deployment/spring-app-v2-deployment

# Wait for ingress to be ready
echo "⏳ Waiting for ingress to be ready..."
sleep 30

# Get deployment status
echo "📊 Deployment Status:"
echo "=== Pods ==="
kubectl get pods
echo ""
echo "=== Services ==="
kubectl get services
echo ""
echo "=== Ingress ==="
kubectl get ingress
echo ""
echo "=== HPA ==="
kubectl get hpa

# Get access information
echo "🌐 Access Information:"
NODE_IP=$(kubectl get nodes -o jsonpath='{.items[0].status.addresses[?(@.type=="InternalIP")].address}')
echo "Node IP: $NODE_IP"
echo ""
echo "Application URLs:"
echo "  V1:   http://$NODE_IP/v1"
echo "  V1.1: http://$NODE_IP/v1.1"
echo "  V2:   http://$NODE_IP/v2"
echo ""
echo "Health Check URLs:"
echo "  V1:   http://$NODE_IP/v1/actuator/health"
echo "  V1.1: http://$NODE_IP/v1.1/actuator/health"
echo "  V2:   http://$NODE_IP/v2/actuator/health"

# Run smoke tests
echo ""
echo "🧪 Running smoke tests..."
curl -s -H "Host: moonrider.local" http://$NODE_IP/v1/actuator/health | grep -q "UP" && echo "✅ V1 health check passed" || echo "❌ V1 health check failed"
curl -s -H "Host: moonrider.local" http://$NODE_IP/v1.1/actuator/health | grep -q "UP" && echo "✅ V1.1 health check passed" || echo "❌ V1.1 health check failed"
curl -s -H "Host: moonrider.local" http://$NODE_IP/v2/actuator/health | grep -q "UP" && echo "✅ V2 health check passed" || echo "❌ V2 health check failed"

echo ""
echo "🎉 Deployment completed successfully!" 