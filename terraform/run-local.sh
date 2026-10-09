#!/bin/bash
ENV=$1
: "${1?"Usage: $0 ENVIRONMENT - ex: $0 dev"}"

shift 1

set -CeE
set -o pipefail

echo "Running plan ${ENV}"

terraform init

if ! terraform workspace select "${ENV}"; then
	terraform workspace new "${ENV}"
fi

terraform plan --out "${ENV}.plan" --var-file="${ENV}.tfvars" "$@"

echo "To apply run :"
echo "terraform apply ${ENV}.plan"
