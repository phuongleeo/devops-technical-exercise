# Create Kind cluster

```bash
cd cluster ; ./setup.sh

```

## Deployment - Either via Helm or Terraform

### Deploy with Terraform

```bash
cd terraform
# DEV: this also install argocd + prometheus server
   # first time, we need argocd deployed first, to have CRDs available
  ./run-local.sh dev -target helm_release.argocd
  ./run-local.sh dev
# PROD:
  ./run-local.sh prod

```

### apply Helm directly

```bash
# DEV:
  cd ./helm/dev
  helm dep build --skip-refresh
  helm upgrade --create-namespace -n greeter-dev --install greeter .

# PROD:
  cd ./helm/prod
  helm dep build --skip-refresh
  helm upgrade --create-namespace -n greeter-prod --install greeter .

```

## Access the service

```
Greeter:
 • DEV: curl http://localhost:8080/
 • PROD: curl http://localhost:8081/
Argocd: http://localhost:8082/
Prometheus: http://localhost:9090/
```

## Manually build image and load to Kind cluster

```bash
docker build -t greeter:<tag> .
kind load docker-image greeter:<tag> --name "$(kind get -q clusters)"
```

## ArgoCD credential

```bash
# Once deployed via terraform. To retrieve the initial password for ArgoCD, run the following command:
# username: admin
kubectl get --namespace argocd secret argocd-initial-admin-secret -o go-template='{{.data.password | base64decode}}'
```

## Verify the Alerting rule

```bash
while true;do curl -4 http://localhost:8080/boom ; done
```
