#!/bin/bash
set -e

echo "=== Creating argocd namespace ==="
kubectl create namespace argocd || true

echo "=== Installing Argo CD ==="
kubectl apply -n argocd \
  -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

echo "=== Waiting for Argo CD pods ==="
kubectl wait --for=condition=Ready pods \
  --all -n argocd --timeout=300s

echo "=== Argo CD is ready ==="

echo "=== Admin password ==="
kubectl -n argocd get secret argocd-initial-admin-secret \
  -o jsonpath='{.data.password}' | base64 --decode
echo
