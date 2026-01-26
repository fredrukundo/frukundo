#!/bin/bash
set -e

echo "== Installing GitLab (bonus) =="

kubectl apply -f bonus/confs/gitlab-namespace.yaml
kubectl apply -f bonus/confs/gitlab-deployment.yaml
kubectl apply -f bonus/confs/gitlab-service.yaml

echo "Waiting for GitLab pod..."
kubectl rollout status deployment/gitlab -n gitlab

echo
echo "GitLab is ready:"
echo "URL: http://localhost:30090"
echo "User: root"
echo "Password:"
kubectl exec -n gitlab deploy/gitlab -- \
  cat /etc/gitlab/initial_root_password | grep Password
