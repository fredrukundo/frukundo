#!/bin/bash
set -e

echo "=== Checking Helm installation ==="
if ! command -v helm >/dev/null 2>&1; then
  echo "Helm not found, installing Helm..."
  curl -fsSL https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
else
  echo "Helm already installed"
fi

echo "=== Creating gitlab namespace ==="
kubectl create namespace gitlab 2>/dev/null || true

echo "=== Adding GitLab Helm repo ==="
helm repo add gitlab https://charts.gitlab.io
helm repo update

echo "=== Installing GitLab ==="
helm upgrade --install gitlab gitlab/gitlab \
  --namespace gitlab \
  -f bonus/confs/values.yaml

echo "=== Waiting for GitLab (this can take several minutes) ==="
kubectl wait --for=condition=Available deployment \
  --all -n gitlab --timeout=600s

echo "=== GitLab is Ready ==="

echo "=== GitLab admin password ==="
kubectl -n gitlab get secret gitlab-gitlab-initial-root-password \
  -o jsonpath='{.data.password}' | base64 -d
echo
