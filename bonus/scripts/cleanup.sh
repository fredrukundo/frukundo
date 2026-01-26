#!/bin/bash

echo "== Cleaning bonus resources =="

kubectl delete application bonus-gitlab-app -n argocd --ignore-not-found
kubectl delete appproject gitlab-project -n argocd --ignore-not-found
kubectl delete namespace gitlab --ignore-not-found

echo "Cleanup done"
