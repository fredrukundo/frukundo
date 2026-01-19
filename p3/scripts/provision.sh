#!/bin/bash
# Exit on error
set -e 

echo "Cleaning up..."
# Ignore errors if cluster doesn't exist
sudo k3d cluster delete mon-cluster || true

echo "Installing prerequisites..."
sudo apt-get update
# Removed software-properties-common, added curl and ca-certificates
sudo apt-get install -y apt-transport-https ca-certificates curl gnupg

# Install Docker if not present
if ! command -v docker &> /dev/null; then
    echo "Installing Docker..."
    curl -fsSL https://get.docker.com -o get-docker.sh
    sudo sh get-docker.sh
    sudo usermod -aG docker $USER
fi

# Install K3d if not present
if ! command -v k3d &> /dev/null; then
    echo "Installing K3d..."
    curl -s https://raw.githubusercontent.com/rancher/k3d/main/install.sh | bash
fi

# Install Kubectl if not present
if ! command -v kubectl &> /dev/null; then
    echo "Installing Kubectl..."
    curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
    chmod +x kubectl
    sudo mv kubectl /usr/local/bin/
fi

echo "Creating K3d Cluster..."
# Mandatory: map port 8888 for the app [cite: 175, 478]
# Mandatory: map port 8080 or 4242 for ArgoCD UI [cite: 501, 515]
sudo k3d cluster create mon-cluster --port "8888:80@loadbalancer" --port "8080:443@loadbalancer" --wait

# FIX: Ensure kubectl can talk to the cluster without sudo errors
mkdir -p $HOME/.kube
sudo k3d kubeconfig get mon-cluster > $HOME/.kube/config
sudo chown $USER:$USER $HOME/.kube/config
export KUBECONFIG=$HOME/.kube/config

echo "Setting up Namespaces..."
# Mandatory namespaces: argocd and dev [cite: 460, 461, 462]
kubectl create namespace argocd || true
kubectl create namespace dev || true

echo "Installing Argo CD..."
# Use the stable manifest as required [cite: 501]
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

echo "Waiting for Argo CD pods..."
kubectl wait --for=condition=available deployments -n argocd --all --timeout=300s

# Save ArgoCD password [cite: 501]
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d > ../argo_password
echo "Password saved in p3/argo_password"

echo "Applying Application Manifest..."
# This links your GitHub repo to the cluster [cite: 463, 465]
kubectl apply -f ../confs/app.yaml -n argocd

echo "Waiting for GitOps Sync (this may take a minute)..."
until kubectl get deployment playground -n dev >/dev/null 2>&1; do
  sleep 5
done

kubectl wait --for=condition=available deployments/playground -n dev --timeout=300s

# Background Port-Forwarding
# Service must be accessible at localhost:8888 [cite: 478, 515]
kubectl port-forward svc/playground-service -n dev 8888:8888 --address 0.0.0.0 >/dev/null 2>&1 &

echo "Deployment complete! Verify with: curl http://localhost:8888/"