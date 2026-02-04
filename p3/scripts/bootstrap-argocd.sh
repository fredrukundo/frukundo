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
echo "== port forward argocd =="
echo "== kubectl -n argocd port-forwad svc/argocd-server 8080:443=="
echo
echo "=== Admin password / push to public repo if not yet ==="
kubectl -n argocd get secret argocd-initial-admin-secret \
  -o jsonpath='{.data.password}' | base64 --decode
echo
echo "== apply once kubectl apply -f namespace yaml and argocd app yaml =="
echo "== verify by curl then test by change conf/depl v2, push and verify again=="
