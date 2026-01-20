# Inception of Things – Part 3 (k3d & Argo CD)

This README describes **all required steps in the correct order** to run **Part 3** on a **Debian VM**, using **k3d** and **Argo CD**, following the project rules.

---

## 0. Prerequisites

Make sure the scripts are executable:

```sh
chmod +x p3/scripts/install.sh
chmod +x p3/scripts/bootstrap-argocd.sh

```
## 1. Install required tools

Install Docker, kubectl, and k3d:

```sh
bash p3/scripts/install.sh
```
Then **apply Docker group changes:**

```sh
newgrp docker
```
(Alternatively, reboot the VM.)

## 2. Create the k3d cluster

Create the Kubernetes cluster and expose the application port:
```sh
k3d cluster create iot \
  --port "8888:30080@loadbalancer"
```
Verify the cluster:
```sh
kubectl get nodes
```

## 3. Install Argo CD

Bootstrap Argo CD (namespace creation + installation):
```sh
bash p3/scripts/bootstrap-argocd.sh
```

Wait until **all pods are running:**
```sh
kubectl get pods -n argocd
```

Expected state:
```sh
STATUS: Running
```

## 4. Access Argo CD UI

Port-forward the Argo CD server:
```sh
kubectl -n argocd port-forward svc/argocd-server 8080:443
```
**Get admin password**
If the bootstrap script does not print the password:
```sh
kubectl -n argocd get secret argocd-initial-admin-secret -o yaml
```

Copy the **base64 value and decode it manually:**
```sh
echo YWRtaW4xMjM0NTY= | base64 -d
```
**Login**

- URL: https://localhost:8080

- User: admin

- Password: (decoded value)

## 5. Push configuration files to GitHub (if not yet done)

Your public GitHub repository must contain:
```sh
p3/confs/*
```

Push the files:
```sh
git add .
git commit -m "argocd app v1"
git push
```
## 6. Deploy application via Argo CD

Apply the namespace and Argo CD Application manually (once):
```sh
kubectl apply -f p3/confs/namespace-dev.yaml
kubectl apply -f p3/confs/argocd-application.yaml
```

From this point on, **Argo CD controls the application.**

## 7. Verify application (v1)
```sh
curl http://localhost:8888
```

Expected output:
```sh
{"status":"ok","message":"v1"}
```
## 8. Update application to v2 (EXAM STEP)

Edit **deployment.yaml:**
```sh
image: wil42/playground:v2
```

Commit and push:
```sh
git add .
git commit -m "update to v2"
git push
```

Wait **10–20 seconds** for Argo CD to sync.

Verify again:
```sh
curl http://localhost:8888
```

Expected output:
```sh
{"status":"ok","message":"v2"}
```

✅ Result

*   k3d cluster running

*   Argo CD installed in argocd namespace

*   Application deployed in dev namespace

*   GitHub → Argo CD → Kubernetes GitOps flow validated

*   Version update handled only via Git