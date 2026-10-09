# Terraform — Greeter Deployment

Deploys the greeter Helm chart to the local kind cluster.

## Prerequisites

- kind cluster running: `./cluster/setup.sh`
- Terraform >= 1.16.5: `brew install terraform`

## Usage

```bash
cd terraform

# Plan an environment
./run-local.sh dev | prod


# Deploy <env>
terraform apply <env>.out
```

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | ~> 1.16.5 |
| <a name="requirement_helm"></a> [helm](#requirement\_helm) | >= 3.3, < 4 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_helm"></a> [helm](#provider\_helm) | 3.3.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [helm_release.greeter](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_environment"></a> [environment](#input\_environment) | Deployment environment name (dev or prod). | `string` | n/a | yes |
| <a name="input_greeting_name"></a> [greeting\_name](#input\_greeting\_name) | The name used in the greeting response. | `string` | n/a | yes |
| <a name="input_namespace"></a> [namespace](#input\_namespace) | Kubernetes namespace to deploy into. | `string` | `"greeter"` | no |
| <a name="input_node_port"></a> [node\_port](#input\_node\_port) | NodePort for the service. | `number` | `30080` | no |
| <a name="input_replica_count"></a> [replica\_count](#input\_replica\_count) | Number of pod replicas. | `number` | `2` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_namespace"></a> [namespace](#output\_namespace) | Kubernetes namespace. |
| <a name="output_release_name"></a> [release\_name](#output\_release\_name) | Helm release name. |
| <a name="output_service_url"></a> [service\_url](#output\_service\_url) | URL to access the service (via kind port mapping). |
<!-- END_TF_DOCS -->

```

```
