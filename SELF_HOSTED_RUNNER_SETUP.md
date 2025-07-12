# Self-Hosted Runner Setup for Local microK8s Deployment

This guide explains how to set up a self-hosted GitHub Actions runner on your local machine to deploy to your local microK8s cluster.

## 🎯 **What This Achieves**

With a self-hosted runner, the workflow will:
1. **Build & Test** → On GitHub's servers
2. **Build & Push Docker Image** → On GitHub's servers  
3. **Deploy to Local microK8s** → On YOUR local machine

## 🔧 **Setup Steps**

### **Step 1: Create Self-Hosted Runner**

1. **Go to your GitHub repository**
   - Navigate to Settings → Actions → Runners
   - Click "New self-hosted runner"

2. **Choose your system**
   - Select your OS (Linux, macOS, Windows)
   - Follow the installation instructions

### **Step 2: Install Runner on Your Machine**

For **Linux** (Ubuntu/Debian):
```bash
# Create a directory for the runner
mkdir actions-runner && cd actions-runner

# Download the runner
curl -o actions-runner-linux-x64-2.311.0.tar.gz -L https://github.com/actions/runner/releases/download/v2.311.0/actions-runner-linux-x64-2.311.0.tar.gz

# Extract the installer
tar xzf ./actions-runner-linux-x64-2.311.0.tar.gz

# Configure the runner
./config.sh --url https://github.com/YOUR_USERNAME/YOUR_REPO --token YOUR_TOKEN

# Install and start the runner service
sudo ./svc.sh install
sudo ./svc.sh start
```

### **Step 3: Verify Runner is Online**

1. **Check GitHub repository**
   - Go to Settings → Actions → Runners
   - You should see your runner with a green "Idle" status

2. **Test the runner**
   - Push a small change to trigger the workflow
   - Check if the deployment job runs on your runner

## 🛠️ **Prerequisites on Your Machine**

### **Required Software**
```bash
# Install microK8s
sudo snap install microk8s --classic

# Install Docker (if not already installed)
sudo apt update
sudo apt install docker.io

# Install kubectl
sudo snap install kubectl --classic

# Install curl (for health checks)
sudo apt install curl
```

### **microK8s Setup**
```bash
# Start microK8s
microk8s start

# Add your user to the microk8s group
sudo usermod -a -G microk8s $USER
newgrp microk8s

# Enable required addons
microk8s enable dns
microk8s enable ingress
microk8s enable metrics-server
microk8s enable storage
microk8s enable registry
```

## 🔐 **Security Considerations**

### **Runner Permissions**
- The runner runs with your user permissions
- It can access your local files and system
- Consider running as a dedicated user

### **Network Access**
- The runner needs internet access to:
  - Download Docker images from Docker Hub
  - Communicate with GitHub
  - Pull dependencies

## 🚀 **How It Works**

### **Workflow Execution**
```
1. You push to main branch
2. GitHub Actions starts workflow
3. Build & Test job runs on GitHub servers
4. Build & Push job runs on GitHub servers
5. Deploy job runs on YOUR local machine
6. Your local microK8s gets updated
```

### **Local Deployment Process**
```bash
# The runner will execute these steps on your machine:
1. Check if microK8s is running
2. Enable required addons
3. Update image tags in manifests
4. Apply Kubernetes manifests
5. Wait for deployments to be ready
6. Run smoke tests
```

## 🔍 **Monitoring**

### **Check Runner Status**
```bash
# Check if runner service is running
sudo systemctl status actions.runner.*

# Check runner logs
sudo journalctl -u actions.runner.* -f
```

### **Check microK8s Status**
```bash
# Check microK8s status
microk8s status

# Check pods
kubectl get pods

# Check services
kubectl get services
```

## 🚨 **Troubleshooting**

### **Common Issues**

1. **Runner not connecting**
   ```bash
   # Restart the runner service
   sudo ./svc.sh restart
   ```

2. **microK8s not accessible**
   ```bash
   # Check microK8s status
   microk8s status
   
   # Restart if needed
   microk8s stop
   microk8s start
   ```

3. **Permission issues**
   ```bash
   # Add user to microk8s group
   sudo usermod -a -G microk8s $USER
   newgrp microk8s
   ```

### **Debug Commands**
```bash
# Check runner configuration
./config.sh --help

# Check runner logs
sudo journalctl -u actions.runner.* -n 50

# Test kubectl access
kubectl get nodes
```

## 🎉 **Benefits**

### **Advantages**
- ✅ **Deploys to your actual local cluster**
- ✅ **Persistent deployments** (not destroyed after workflow)
- ✅ **Access to local resources**
- ✅ **Faster deployment** (no image pulling delays)
- ✅ **Full control** over the deployment environment

### **Use Cases**
- **Development environment** automation
- **Testing** on local infrastructure
- **Staging environment** deployment
- **Production-like** local testing

## 📋 **Next Steps**

1. **Set up the self-hosted runner** following the steps above
2. **Configure Docker Hub secrets** in your GitHub repository
3. **Push to main branch** to test the complete workflow
4. **Monitor the deployment** on your local machine

Your local microK8s cluster will now be automatically updated whenever you push to the main branch! 🚀 