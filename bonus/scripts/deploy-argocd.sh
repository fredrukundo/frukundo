#!/bin/bash
set -e

echo "== Deploying Argo CD bonus config =="

kubectl apply -f bonus/confs/argocd-project.yaml
kubectl apply -f bonus/confs/argocd-application.yaml

echo "Argo CD application deployed"
