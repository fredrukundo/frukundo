#!/bin/bash
set -e

CLUSTER_NAME="iot"

echo "=== Stopping active kubectl port-forwards (if any) ==="
pkill -f "kubectl.*port-forward" 2>/dev/null || true

echo "=== Deleting k3d cluster: $CLUSTER_NAME ==="
k3d cluster delete "$CLUSTER_NAME" || true

echo "=== Cleaning kubectl context (if exists) ==="
kubectl config delete-context "k3d-$CLUSTER_NAME" 2>/dev/null || true

echo "=== Removing unused Docker resources ==="
docker system prune -f

echo "=== Cleanup complete ==="
