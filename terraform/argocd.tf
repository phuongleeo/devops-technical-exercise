resource "helm_release" "argocd" {
  count            = var.environment == "dev" ? 1 : 0 # need 1 instance only
  name             = "argocd"
  repository       = "https://argoproj.github.io/argo-helm"
  chart            = "argo-cd"
  version          = "10.10.2"
  namespace        = "argocd"
  create_namespace = true

  set = [
    {
      name  = "dex.enabled"
      value = "false"
    },
    {
      name  = "configs.params.server\\.insecure"
      value = "true"
    },
    {
      name  = "server.service.type"
      value = "NodePort"
    },
    {
      name  = "server.service.nodePortHttp"
      value = "30082"
    }
  ]

  wait    = true
  timeout = 300
}

