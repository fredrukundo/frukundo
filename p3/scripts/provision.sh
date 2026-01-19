#!/bin/bash
set -e # Stop script on any error

# 1. Clean up existing environment
echo "Cleaning up..."
sudo k3d cluster delete mon-cluster || true

# 2. Update and Install Prerequisites
sudo apt-get update
sudo apt-get install -y apt-transport-https ca-certificates curl software-properties-common

# 3. Install Docker
if ! command -v docker &> /dev/null; then
    curl -fsSL https://get.docker.com -o get-docker.sh
    sudo sh get-docker.sh
    sudo usermod -aG docker $USER
fi

# 4. Install K3d
if ! command -v k3d &> /dev/null; then
    curl -s https://raw.githubusercontent.com/rancher/k3d/main/install.sh | bash
fi

# 5. Install Kubectl
if ! command -v kubectl &> /dev/null; then
    curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
    chmod +x kubectl
    sudo mv kubectl /usr/local/bin/
fi

# 6. Create K3d Cluster
# Mapping 8888 to 80 for the application as shown in project examples [cite: 515]
sudo k3d cluster create mon-cluster --port "8888:80@loadbalancer" --port "4242:443@loadbalancer"

# 7. Setup Kubeconfig for current user (Fixes connection refused issues)
mkdir -p $HOME/.kube
sudo k3d kubeconfig get mon-cluster > $HOME/.kube/config
sudo chown $USER:$USER $HOME/.kube/config

# 8. Setup Namespaces [cite: 460, 461, 462]
kubectl create namespace argocd
kubectl create namespace dev

# 9. Install Argo CD [cite: 444]
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

echo "Waiting for Argo CD to become ready..."
kubectl wait --for=condition=available deployments -n argocd --all --timeout=300s

# 10. Extract Initial Admin Password [cite: 501]
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d > ../argo_password
echo "ArgoCD password saved to p3/argo_password"

# 11. Apply Argo CD Application (The GitOps Link) [cite: 451, 463]
# IMPORTANT: Ensure your files are in p3/confs/ as per subject 
kubectl apply -f ../confs/app.yaml -n argocd

echo "Waiting for Argo CD to sync and deploy the application to 'dev'..."
# We wait for the deployment to appear in the 'dev' namespace
until kubectl get deployment playground -n dev >/dev/null 2>&1; do
  echo "Syncing..."
  sleep 10
done

kubectl wait --for=condition=available deployments/playground -n dev --timeout=300s

# 12. Port Forwarding for Access
# ArgoCD UI on 4242, App on 8888 [cite: 478, 515]
kubectl port-forward svc/argocd-server -n argocd 4242:443 --address 0.0.0.0 >/dev/null 2>&1 &
kubectl port-forward svc/playground-service -n dev 8888:8888 --address 0.0.0.0 >/dev/null 2>&1 &

echo "Setup Complete!"
echo "App available at: http://localhost:8888"