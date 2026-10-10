# Create Kind cluster

```bash
cd cluster ; ./setup.sh

```

## Deployment - Either via Helm or Terraform

### Deploy with Terraform

```bash
cd terraform
# DEV:
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
• DEV: curl http://localhost:8080/
• PROD: curl http://localhost:8081/
```
