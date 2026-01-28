# BONUS — GitLab + Argo CD on AWS EKS (Inception of Things)

This bonus demonstrates a complete **GitOps workflow** on **AWS EKS**:

- **GitLab** hosts the Kubernetes manifests (single source of truth)
- **Argo CD** continuously syncs the cluster from GitLab
- A **git push** updates the cluster automatically (v1 → v2)

> All commands below are intended to be executed **inside your Debian VM**.

---

## 0) Prerequisites

You need these tools available in the VM:

- `aws` (AWS CLI v2) configured
- `eksctl`
- `kubectl`
- `helm`
- `git`

Quick checks:

```bash
aws sts get-caller-identity
eksctl version
kubectl version --client
helm version
git --version
```

## 1) Create the EKS cluster (eksctl)

Example (single 16GB node, recommended for GitLab):
```bash
eksctl create cluster \
  --name iot-bonus \
  --region us-east-1 \
  --nodegroup-name standard-workers \
  --node-type t3.xlarge \
  --nodes 1 \
  --nodes-min 1 \
  --nodes-max 1 \
  --managed
```
Verify:
```bash
kubectl get nodes
```

✅ Expected: 1 node in __Ready__ state.

## 2) Install Argo CD
Use your existing Argo CD installer script (already prepared in your repo).


After installing, verify:

```bash
kubectl get pods -n argocd
```
✅ Expected: all Argo CD pods __Running__.

Access Argo CD UI:

```bash
kubectl -n argocd port-forward svc/argocd-server 8080:443
```

Open:

- URL: __https://localhost:8080__

- User: __admin__

- Password: (from your Argo CD install script / secret)

## 3) Install GitLab (Helm + optimized values)
You already have: __bonus/scripts/install-gitlab.sh__ and __bonus/confs/values.yaml__.

Run:

```bash
bash bonus/scripts/install-gitlab.sh
```

Verify:

```bash
kubectl get pods -n gitlab
```

✅ Expected: all GitLab pods __Running__ (no __Pending__).

Access GitLab UI:

```bash
kubectl -n gitlab port-forward svc/gitlab-webservice-default 8082:8181
```

Open:

- URL: __http://localhost:8082__

- User: __root__

- Password: printed by __install-gitlab.sh__ (or read from secret)

## 4) Create a GitLab repo and push manifests (HTTP)
### 4.1 Create repo

In GitLab UI:

- Create a Public project named: iot-bonus

Recommended (reduce noise/resources):

- Project → Settings → CI/CD → Auto DevOps OFF

### 4.2 Create a push token (HTTP push)

GitLab UI:

- User → Edit profile → Access Tokens

Create token:

1. Name: push-iot-bonus

2. Scopes: ✅ write_repository (or ✅ api)
3. Copy it.

### 4.3 Clone repo in your VM and add manifests

Clone (replace <PUSH_TOKEN>):

```bash
git clone http://root:<PUSH_TOKEN>@localhost:8082/root/iot-bonus.git
cd iot-bonus
```

Create folder:

```bash
mkdir -p manifests
```

Create __manifests/namespace.yaml__:

```bash
apiVersion: v1
kind: Namespace
metadata:
  name: bonus
```

Create __manifests/deployment.yaml__ (IMPORTANT: __wil42/playground__ listens on **8888** ):

```bash
apiVersion: apps/v1
kind: Deployment
metadata:
  name: bonus-app
  namespace: bonus
spec:
  replicas: 1
  selector:
    matchLabels:
      app: bonus
  template:
    metadata:
      labels:
        app: bonus
    spec:
      containers:
        - name: app
          image: wil42/playground:v1
          ports:
            - containerPort: 8888
```

Create __manifests/service.yaml__:

```bash
apiVersion: v1
kind: Service
metadata:
  name: bonus-svc
  namespace: bonus
spec:
  type: ClusterIP
  selector:
    app: bonus
  ports:
    - port: 80
      targetPort: 8888
```

Commit + push:
```bash
git add .
git commit -m "Add manifests v1"
git push -u origin main
```

## 5) Wire Argo CD → GitLab (repo secret + application)
### 5.1 Create a read-only token for Argo CD

GitLab UI:

- User → Edit profile → Access Tokens

Create token:

- Name: argocd-read

- Scopes: ✅ read_repository
- Copy it.

### 5.2 Create Argo CD repository secret

Create: __bonus/confs/argocd-repo-secret.yaml__

Replace <READ_TOKEN>:
```bash
apiVersion: v1
kind: Secret
metadata:
  name: gitlab-repo-iot-bonus
  namespace: argocd
  labels:
    argocd.argoproj.io/secret-type: repository
stringData:
  url: http://gitlab-webservice-default.gitlab.svc.cluster.local:8181/root/iot-bonus.git
  username: root
  password: <READ_TOKEN>
  type: git
```

Apply:

```bash
kubectl apply -f bonus/confs/argocd-repo-secret.yaml
```

### 5.3 Create Argo CD application

Create: __bonus/confs/argocd-application.yaml__

```bash
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: iot-bonus
  namespace: argocd
spec:
  project: default
  source:
    repoURL: http://gitlab-webservice-default.gitlab.svc.cluster.local:8181/root/iot-bonus.git
    targetRevision: main
    path: manifests
  destination:
    server: https://kubernetes.default.svc
    namespace: bonus
  syncPolicy:
    automated:
      selfHeal: true
      prune: true
```

Apply:

```bash
kubectl apply -f bonus/confs/argocd-application.yaml
```

Verify in Argo CD UI:

- Application <iot-bonus> → Synced / Healthy

## 6) Verify v1 running in the cluster

Check resources:

```bash
kubectl get ns bonus
kubectl get pods -n bonus
kubectl get svc -n bonus
```

Port-forward the app:

```bash
kubectl -n bonus port-forward svc/bonus-svc 8090:80
```

Test:
```bash
curl http://localhost:8090
```

✅ Expected: response from __wil42/playground__ (v1).

## 7) GitOps proof (EXAM): update to v2 with Git push only

Edit __manifests/deployment.yaml__:

```bash
- image: wil42/playground:v1
+ image: wil42/playground:v2
```

Commit + push:
```bash
git add manifests/deployment.yaml
git commit -m "Update to v2"
git push
```

Wait a few seconds (Argo CD auto-sync).

Verify image is v2:
```bash
kubectl get pods -n bonus -o jsonpath='{.items[0].spec.containers[0].image}{"\n"}'
```

✅ Expected: wil42/playground:v2

Verify service still responds:
```bash
curl http://localhost:8090
```

✅ Expected: successful response (v2).

## 8) Cleanup (recommended to avoid AWS costs)
### 8.1 Remove Argo CD application + repo secret
```bash
kubectl delete application iot-bonus -n argocd --ignore-not-found
kubectl delete secret gitlab-repo-iot-bonus -n argocd --ignore-not-found
```

### 8.2 Remove GitLab
```bash
helm uninstall gitlab -n gitlab || true
kubectl delete namespace gitlab --ignore-not-found
```

### 8.3 Delete the EKS cluster

```bash
eksctl delete cluster --name iot-bonus --region us-east-1
```