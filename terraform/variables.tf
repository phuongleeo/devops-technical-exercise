variable "environment" {
  description = "Deployment environment name (dev or prod)."
  type        = string

  validation {
    condition     = contains(["dev", "prod"], var.environment)
    error_message = "environment must be 'dev' or 'prod'."
  }
}

variable "namespace" {
  description = "Kubernetes namespace to deploy into."
  type        = string
  default     = "greeter"
}

variable "greeting_name" {
  description = "The name used in the greeting response."
  type        = string
}

variable "replica_count" {
  description = "Number of pod replicas."
  type        = number
  default     = 2
}

variable "node_port" {
  description = "NodePort for the service."
  type        = number
  default     = 30080
}

variable "enabled_gitops" {
  description = "enable gitops"
  type        = bool
  default     = true
}
