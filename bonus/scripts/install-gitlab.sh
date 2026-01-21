#!/bin/bash
set -e

echo "=== Creating gitlab namespace ==="
kubectl create namespace gitlab || true

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
echo "=== Gitlab is Ready ==="

echo "=== Admin passward ==="

kubectl -n gitlab get secret gitlab-gitlab-initial-root-password \
  -o jsonpath='{.data.password}' | base64 -d
echo
