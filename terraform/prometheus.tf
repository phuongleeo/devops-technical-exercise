
resource "helm_release" "prometheus" {
  count            = var.environment == "dev" ? 1 : 0
  name             = "prometheus"
  repository       = "https://prometheus-community.github.io/helm-charts"
  chart            = "prometheus"
  version          = "29.36.1"
  namespace        = "monitoring"
  create_namespace = true

  values = [
    file("files/values.yaml")
  ]

  # Prometheus needs cluster-wide pod discovery; wait for it to be ready.
  wait    = true
  timeout = 180
}

