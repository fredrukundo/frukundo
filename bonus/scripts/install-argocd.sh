#!/bin/bash
set -e

echo "== Installing Argo CD =="

kubectl create namespace argocd --dry-run=client -o yaml | kubectl apply -f -

kubectl apply -n argocd \
  -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

echo "Waiting for Argo CD pods..."
kubectl wait --for=condition=available deployment \
  --all -n argocd --timeout=300s

echo "Argo CD installed successfully"
echo
echo "Argo CD admin password:"
echo
kubectl -n argocd get secret argocd-initial-admin-secret \
  -o jsonpath="{.data.password}" | base64 -d
echo
echo "============================"

# 6. Access instructions
echo
echo "Access ArgoCD UI with: (admin + passwd)"
echo
echo "kubectl -n argocd port-forward svc/argocd-server 8080:443"
echo
echo "Verify installation: kubectl get pods -n argocd"
echo
echo "Then open: http://localhost:8080"
