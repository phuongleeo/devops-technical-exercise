#!/usr/bin/env bash
set -euo pipefail

# ── colours ──────────────────────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'
info() { echo -e "${YELLOW}[INFO]${NC}  $*"; }
success() { echo -e "${GREEN}[OK]${NC}    $*"; }
die() {
	echo -e "${RED}[ERROR]${NC} $*" >&2
	exit 1
}

# ── paths ─────────────────────────────────────────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
CLUSTER_NAME="w3w-local"
CONFIG="${SCRIPT_DIR}/kind-config.yaml"

# ── pre-flight checks ─────────────────────────────────────────────────────────
command -v kind >/dev/null 2>&1 || die "kind is not installed. See https://kind.sigs.k8s.io/docs/user/quick-start/#installation"
command -v kubectl >/dev/null 2>&1 || die "kubectl is not installed. See https://kubernetes.io/docs/tasks/tools/"
docker info >/dev/null 2>&1 || die "Docker is not running. Start Docker and retry."

# ── cluster ───────────────────────────────────────────────────────────────────
if kind get clusters 2>/dev/null | grep -q "^${CLUSTER_NAME}$"; then
	info "Deleting existing cluster '${CLUSTER_NAME}'..."
	kind delete cluster --name "${CLUSTER_NAME}"
fi

info "Creating cluster '${CLUSTER_NAME}' from ${CONFIG}..."
kind create cluster --config "${CONFIG}"
success "Cluster '${CLUSTER_NAME}' created with 1 control-plane + 2 workers."

# ── image ─────────────────────────────────────────────────────────────────────
info "Building Docker image greeter:local..."
docker build -t greeter:local "${REPO_ROOT}"
success "Image built."

info "Loading greeter:local into kind cluster '${CLUSTER_NAME}'..."
kind load docker-image greeter:local --name "${CLUSTER_NAME}"
success "Image loaded into cluster nodes."

# ── done ──────────────────────────────────────────────────────────────────────
echo ""
success "Setup complete. Next steps:"
echo "  • Deploy with Terraform:  cd terraform && terraform init && terraform apply"
echo "  • Or apply Helm directly:"
echo "  * DEV: helm upgrade --create-namespace -n greeter-dev --install greeter ./helm/greeter -f helm/greeter/values-dev.yaml"
echo "  • PROD: helm upgrade --create-namespace -n greeter-prod --install greeter ./helm/greeter -f helm/greeter/values-prod.yaml"
echo "  • Access the service:     curl http://localhost:8080/"
