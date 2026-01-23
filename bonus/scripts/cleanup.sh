#!/bin/bash

# This script cleans up the k3d cluster, GitLab installation, and related resources
set -e

CLUSTER_NAME="iot"
GITLAB_RELEASE="gitlab"
GITLAB_NAMESPACE="gitlab"

echo "=== Stopping active kubectl port-forwards (if any) ==="
pkill -f "kubectl.*port-forward" 2>/dev/null || true

echo "=== Removing Argo CD Applications (bonus) ==="
kubectl delete application playground-bonus -n argocd 2>/dev/null || true

echo "=== Uninstalling GitLab Helm release ==="
helm uninstall "$GITLAB_RELEASE" -n "$GITLAB_NAMESPACE" 2>/dev/null || true

echo "=== Deleting gitlab namespace ==="
kubectl delete namespace "$GITLAB_NAMESPACE" 2>/dev/null || true

echo "=== Deleting k3d cluster: $CLUSTER_NAME ==="
k3d cluster delete "$CLUSTER_NAME" 2>/dev/null || true

echo "=== Cleaning kubectl context ==="
kubectl config delete-context "k3d-$CLUSTER_NAME" 2>/dev/null || true

echo "=== Removing unused Docker resources ==="
docker system prune -f

echo "=== Bonus cleanup complete ==="
