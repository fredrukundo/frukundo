# Inception of Things – Bonus (Local GitLab with Argo CD)

This README explains **step by step** how to run the **bonus part** of the project.  
The goal is to replace **GitHub** with a **local GitLab**, while keeping the **same GitOps workflow** using **Argo CD**.

⚠️ The bonus assumes **Part 3 is already working**.

---

## 0. Bonus directory structure

bonus/  
├── scripts/  
│   ├── install-gitlab.sh  
│   └── cleanup.sh  
└── confs/  
    ├── values.yaml  
    ├── namespace-dev.yaml  
    ├── deployment.yaml  
    ├── service.yaml  
    └── argocd-application.yaml  


## 1. Install Helm & GitLab inside the cluster

- Helm is required to install GitLab.

Install GitLab in a **dedicated namespace** using Helm:

```sh
bash bonus/scripts/install-gitlab.sh

helm version
```

This step can take **several minutes**.

Wait until all GitLab pods are running:

```sh
kubectl get pods -n gitlab
```

## 2. Access GitLab

Forward the GitLab web service:

```sh
kubectl -n gitlab port-forward svc/gitlab-webservice-default 8081:8181
```

Open in your browser:
```sh
http://localhost:8081
```

Login with:

- Username: **root**
- Password: (printed at the end of **install-gitlab.sh**)

## 3. Create a GitLab repository

Inside GitLab UI:

1. Create a **new project**
2. Set visibility to **Public**
3. Name it (example): **iot-bonus**

Clone the repository and push the configuration files:
```sh
bonus/confs/*

git add .
git commit -m "bonus: initial gitops config"
git push
```

## 4. Create the dev namespace
```sh
kubectl apply -f bonus/confs/namespace-dev.yaml
```

## 5. Deploy application via Argo CD (GitLab source)

Apply the Argo CD Application manifest:

```sh
kubectl apply -f bonus/confs/argocd-application.yaml
```

Argo CD will now:

- Pull manifests from **local GitLab**
- Deploy the application into the **dev** namespace

Check:

```sh
kubectl get applications -n argocd
```

## 6. Verify application (v1)

```sh
curl http://localhost:8888
```

Expected output:

```sh
{"status":"ok","message":"v1"}
```

## 7. Update application to v2 (GitLab → Argo CD)

Edit _bonus/confs/deployment.yaml_ **inside GitLab**:

```sh
image: wil42/playground:v2
```

Commit and push the change.

Wait a few seconds for Argo CD to sync.

Verify:
```sh
curl http://localhost:8888
```

Expected output:
```sh
{"status":"ok","message":"v2"}
```

## 8. Cleanup (optional)

To reset the bonus environment:
```sh
bash bonus/scripts/cleanup.sh
```

This removes GitLab and all related resources.
