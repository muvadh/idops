NAMESPACE=inspiring
KUSTOMIZE_DIR=k8s/base
PV_PATH=/home/docker/volumes/mysql/data

.PHONY: help start-minikube prepare-volume ns-create apply verify exec-mysql port-forward cleanup cleanup-hard reset-data recreate

## Show help
help:
	@echo "MySQL Kubernetes Setup (Minikube)"
	@echo ""
	@echo "Usage:"
	@echo "  make start-minikube       Start Minikube cluster"
	@echo "  make prepare-volume       Prepare volume inside Minikube VM"
	@echo "  make ns-create            Create Kubernetes namespace '$(NAMESPACE)'"
	@echo "  make apply                Apply Kustomize manifests"
	@echo "  make verify               Verify PV, PVC, Pods"
	@echo "  make exec-mysql           Access MySQL pod shell"
	@echo "  make port-forward         Port-forward MySQL service to localhost:3306"
	@echo "  make cleanup              Delete app resources (StatefulSet, PVC, PV, etc.)"
	@echo "  make reset-data           Remove volume data inside Minikube VM"
	@echo "  make cleanup-hard         Cleanup all + namespace + volume data"
	@echo "  make recreate             Full teardown and redeploy"

## Start Minikube
start-minikube:
	minikube start

## Prepare PV directory inside Minikube
prepare-volume:
	minikube ssh -- "sudo mkdir -p $(PV_PATH) && sudo chmod -R 777 $(PV_PATH)"

## Create Kubernetes namespace
ns-create:
	kubectl create namespace $(NAMESPACE) --dry-run=client -o yaml | kubectl apply -f -

## Apply manifests using Kustomize
apply: ns-create
	kubectl apply -k $(KUSTOMIZE_DIR)

## Verify Kubernetes resources
verify:
	kubectl get pv
	kubectl get pvc -n $(NAMESPACE)
	kubectl get pods -n $(NAMESPACE)

## Exec into MySQL pod
exec-mysql:
	kubectl exec -it mysql-0 -n $(NAMESPACE) -- /bin/bash

## Port-forward MySQL to localhost:3306
port-forward:
	kubectl port-forward svc/mysql 3306:3306 -n $(NAMESPACE)

## Cleanup application-specific resources
cleanup:
	kubectl delete statefulset mysql -n $(NAMESPACE) || true
	kubectl delete pvc mysql-data-mysql-0 -n $(NAMESPACE) || true
	kubectl delete pv mysql-pv-0 || true
	kubectl delete svc mysql -n $(NAMESPACE) || true
	kubectl delete secret mysql-root-password -n $(NAMESPACE) || true
	kubectl delete configmap mysql-config -n $(NAMESPACE) || true

## Remove volume data inside Minikube
reset-data:
	minikube ssh -- "sudo rm -rf $(PV_PATH)"

## Full cleanup including namespace and volume
cleanup-hard: cleanup reset-data
	kubectl delete namespace $(NAMESPACE) || true

## Recreate from scratch
recreate: cleanup-hard start-minikube prepare-volume apply verify
