#!/bin/bash

# Spring Boot microK8s Deployment Script
# Usage: ./scripts/deploy.sh [version]

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Default values
VERSION=${1:-"latest"}
NAMESPACE="default"
REGISTRY="ghcr.io"
IMAGE_NAME="h4mmad/spring-boot-app"

echo -e "${BLUE}🚀 Starting Spring Boot microK8s Deployment${NC}"
echo -e "${BLUE}Version: ${VERSION}${NC}"
echo -e "${BLUE}Namespace: ${NAMESPACE}${NC}"

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to print status
print_status() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

# Check prerequisites
echo -e "${BLUE}📋 Checking prerequisites...${NC}"

if ! command_exists kubectl; then
    print_error "kubectl is not installed"
    exit 1
fi

if ! command_exists microk8s; then
    print_error "microk8s is not installed"
    exit 1
fi

print_status "Prerequisites check passed"

# Check microK8s status
echo -e "${BLUE}🔍 Checking microK8s status...${NC}"

if ! microk8s status >/dev/null 2>&1; then
    print_error "microK8s is not running. Please start it first: microk8s start"
    exit 1
fi

print_status "microK8s is running"

# Enable required addons
echo -e "${BLUE}⚙️  Enabling microK8s addons...${NC}"

microk8s enable dns
microk8s enable ingress
microk8s enable metrics-server
microk8s enable storage
microk8s enable registry

print_status "Addons enabled"

# Wait for microK8s to be ready
echo -e "${BLUE}⏳ Waiting for microK8s to be ready...${NC}"

microk8s status --wait-ready
kubectl wait --for=condition=ready pod -l k8s-app=kube-dns -n kube-system --timeout=300s

print_status "microK8s is ready"

# Configure kubectl
echo -e "${BLUE}🔧 Configuring kubectl...${NC}"

microk8s config > ~/.kube/config
chmod 600 ~/.kube/config

print_status "kubectl configured"

# Update image tags in manifests
echo -e "${BLUE}🏷️  Updating image tags...${NC}"

IMAGE_TAG="${REGISTRY}/${IMAGE_NAME}:${VERSION}"

# Update all deployment manifests with the new image
find k8s/ -name "*-app-manifest.yaml" -exec sed -i "s|image: h4mmad/spring-boot-app:.*|image: $IMAGE_TAG|g" {} \;

print_status "Image tags updated to: $IMAGE_TAG"

# Deploy in order
echo -e "${BLUE}📦 Deploying to microK8s...${NC}"

# 1. Apply configuration and storage
echo -e "${BLUE}   📋 Applying configuration and storage...${NC}"
kubectl apply -f k8s/config-secrets.yaml
kubectl apply -f k8s/mysql-pvc.yaml
print_status "Configuration and storage applied"

# 2. Deploy MySQL
echo -e "${BLUE}   🗄️  Deploying MySQL...${NC}"
kubectl apply -f k8s/mysql-deployment.yaml

# Wait for MySQL to be ready
echo -e "${BLUE}   ⏳ Waiting for MySQL to be ready...${NC}"
kubectl wait --for=condition=ready pod -l app=mysql --timeout=300s
print_status "MySQL is ready"

# 3. Deploy applications
echo -e "${BLUE}   🚀 Deploying Spring Boot applications...${NC}"
kubectl apply -f k8s/v1-app-manifest.yaml
kubectl apply -f k8s/v1.1-app-manifest.yaml
kubectl apply -f k8s/v2-app-manifest.yaml
print_status "Applications deployed"

# 4. Apply HPA
echo -e "${BLUE}   📈 Applying Horizontal Pod Autoscalers...${NC}"
kubectl apply -f k8s/hpa-manifest.yaml
print_status "HPAs applied"

# 5. Apply ingress
echo -e "${BLUE}   🌐 Applying ingress...${NC}"
kubectl apply -f k8s/ingress.yaml
print_status "Ingress applied"

# Wait for deployments to be ready
echo -e "${BLUE}⏳ Waiting for deployments to be ready...${NC}"

kubectl wait --for=condition=available --timeout=600s deployment/spring-app-v1-deployment
kubectl wait --for=condition=available --timeout=600s deployment/spring-app-v1.1-deployment
kubectl wait --for=condition=available --timeout=600s deployment/spring-app-v2-deployment

print_status "All deployments are ready"

# Run smoke tests
echo -e "${BLUE}🧪 Running smoke tests...${NC}"

# Wait for ingress to be ready
sleep 30

# Get the node IP
NODE_IP=$(kubectl get nodes -o jsonpath='{.items[0].status.addresses[?(@.type=="InternalIP")].address}')

# Test health endpoints
echo -e "${BLUE}   Testing health endpoints...${NC}"

if curl -s -H "Host: moonrider.local" http://$NODE_IP/v1/actuator/health >/dev/null; then
    print_status "V1 health check passed"
else
    print_warning "V1 health check failed"
fi

if curl -s -H "Host: moonrider.local" http://$NODE_IP/v1.1/actuator/health >/dev/null; then
    print_status "V1.1 health check passed"
else
    print_warning "V1.1 health check failed"
fi

if curl -s -H "Host: moonrider.local" http://$NODE_IP/v2/actuator/health >/dev/null; then
    print_status "V2 health check passed"
else
    print_warning "V2 health check failed"
fi

# Display deployment status
echo -e "${BLUE}📊 Deployment Status:${NC}"

echo -e "${BLUE}=== Pod Status ===${NC}"
kubectl get pods

echo -e "${BLUE}=== Service Status ===${NC}"
kubectl get services

echo -e "${BLUE}=== Ingress Status ===${NC}"
kubectl get ingress

echo -e "${BLUE}=== HPA Status ===${NC}"
kubectl get hpa

# Display access information
echo -e "${BLUE}🌐 Access Information:${NC}"
echo -e "${GREEN}Node IP: ${NODE_IP}${NC}"
echo -e "${GREEN}V1: http://${NODE_IP}/v1/actuator/health${NC}"
echo -e "${GREEN}V1.1: http://${NODE_IP}/v1.1/actuator/health${NC}"
echo -e "${GREEN}V2: http://${NODE_IP}/v2/actuator/health${NC}"

echo -e "${GREEN}🎉 Deployment completed successfully!${NC}" 