---

````markdown
# MySQL Kubernetes Setup (Minikube)

This guide sets up a MySQL StatefulSet on Kubernetes using Minikube and provides steps for volume preparation, deployment, verification, and cleanup.

---

## Prerequisites

- [Minikube](https://minikube.sigs.k8s.io/)
- [kubectl](https://kubernetes.io/docs/tasks/tools/)
- MySQL manifests and kustomization setup under `k8s/base`

---

## Steps

### 1. Start Minikube

```bash
minikube start
````

### 2. Prepare Persistent Volume on Minikube VM

```bash
minikube ssh
```

Inside the Minikube VM:

```bash
sudo mkdir -p /home/docker/volumes/mysql/data
sudo chmod -R 777 /home/docker/volumes/mysql/data
exit
```

### 3. Create Kubernetes Namespace

```bash
kubectl create namespace inspiring
```

### 4. Apply Kustomize Manifests

```bash
kubectl apply -k k8s/base
```

### 5. Verify Kubernetes Resources

```bash
kubectl get pv
kubectl get pvc -n inspiring
kubectl get pods -n inspiring
```

### 6. Access MySQL Pod

```bash
kubectl exec -it mysql-0 -n inspiring -- /bin/bash
```

Inside the pod:

```bash
mysql -u root -p
# Enter the password when prompted (from the Kubernetes secret)
```

---

## Cleanup Commands

To remove all created Kubernetes resources and persistent volumes:

```bash
# Delete MySQL StatefulSet and associated PVC
kubectl delete statefulset mysql -n inspiring
kubectl delete pvc mysql-data-mysql-0 -n inspiring

# Delete the Persistent Volume (if manually created)
kubectl delete pv mysql-pv-0

# Delete the MySQL service (if created)
kubectl delete svc mysql -n inspiring

# Optional: Delete associated secrets/configmaps
kubectl delete secret mysql-root-password -n inspiring
kubectl delete configmap mysql-config -n inspiring

# Optional: Delete the namespace
kubectl delete namespace inspiring
```

Also remove the volume directory from the Minikube VM if needed:

```bash
minikube ssh
sudo rm -rf /home/docker/volumes/mysql/data
exit
```

---

* You can port-forward to access MySQL locally if needed:

```bash
kubectl port-forward svc/mysql 3306:3306 -n inspiring
```

---
