#!/bin/bash
set -e

echo "=== Installing GitLab (optimized for EKS) ==="

# 1. Ensure namespace
kubectl create namespace gitlab --dry-run=client -o yaml | kubectl apply -f -

# 2. Add Helm repo (idempotent)
helm repo add gitlab https://charts.gitlab.io || true
helm repo update

# 3. Install / upgrade GitLab
helm upgrade --install gitlab gitlab/gitlab \
  --namespace gitlab \
  -f bonus/confs/values.yaml \
  --timeout 900s

echo "=== Waiting for GitLab to become Ready ==="

# 4. Wait for webservice deployment
kubectl wait \
  --namespace gitlab \
  --for=condition=available deployment/gitlab-webservice-default \
  --timeout=900s

echo "=== GitLab is Ready ==="

# 5. Print root password
echo
echo "=== GitLab root password ==="
kubectl get secret -n gitlab gitlab-gitlab-initial-root-password \
  -o jsonpath='{.data.password}' | base64 -d
echo
echo "============================"

# 6. Access instructions
echo
echo "Access GitLab UI with:"
echo "kubectl -n gitlab port-forward svc/gitlab-webservice-default 8082:8181"
echo
echo "Then open: http://localhost:8082"
