resource "helm_release" "greeter" {
  name             = "greeter-${var.environment}"
  chart            = "${path.module}/../helm/greeter"
  namespace        = var.namespace
  create_namespace = true

  # Environment-specific values
  set = [
    {
      name  = "greeting.name"
      value = var.greeting_name
    },
    {
      name  = "replicaCount"
      value = var.replica_count
    },
    {
      name  = "version"
      value = var.environment
    },
    {
      name  = "service.nodePort"
      value = var.node_port
    }
  ]
  # Wait for rollout to complete
  wait    = true
  timeout = 120
}
