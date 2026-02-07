#!/bin/bash
set -e

echo "== BONUS cleanup (cluster-only, no EKS delete) =="

# --- Argo CD (bonus app + repo secret) ---
echo "[1/4] Removing Argo CD Application and repo secret (if present)..."
kubectl delete application iot-bonus -n argocd --ignore-not-found >/dev/null 2>&1 || true
kubectl delete secret gitlab-repo-iot-bonus -n argocd --ignore-not-found >/dev/null 2>&1 || true

# --- Bonus namespace (app resources) ---
echo "[2/4] Removing bonus namespace (app resources)..."
kubectl delete namespace bonus --ignore-not-found >/dev/null 2>&1 || true

# --- GitLab (helm release + namespace) ---
echo "[3/4] Removing GitLab Helm release (if present)..."
if command -v helm >/dev/null 2>&1; then
  helm uninstall gitlab -n gitlab >/dev/null 2>&1 || true
else
  echo "  - helm not found, skipping helm uninstall (GitLab may remain)."
fi

echo "[4/4] Removing gitlab namespace..."
kubectl delete namespace gitlab --ignore-not-found >/dev/null 2>&1 || true

echo
echo "✅ Cleanup complete."
echo "Notes:"
echo "- EKS cluster NOT deleted."
echo "- Argo CD NOT deleted (only bonus app + repo secret removed)."
