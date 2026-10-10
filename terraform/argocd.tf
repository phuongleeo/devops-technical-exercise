resource "helm_release" "argocd" {
  count            = var.environment == "dev" ? 1 : 0
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

resource "kubernetes_manifest" "greeter_dev" {
  count = var.environment == "dev" ? 1 : 0

  # Argo CD must be running before this resource can be applied.
  depends_on = [helm_release.argocd]

  manifest = {
    apiVersion = "argoproj.io/v1alpha1"
    kind       = "Application"
    metadata = {
      name      = "greeter-dev"
      namespace = "argocd"
    }
    spec = {
      project = "default"

      source = {
        repoURL        = "https://github.com/phuongleeo/devops-technical-exercise"
        targetRevision = "solution"
        path           = "helm/dev"
        helm = {
          valueFiles = ["values.yaml"]
        }
      }

      destination = {
        server    = "https://kubernetes.default.svc"
        namespace = "greeter-dev"
      }

      syncPolicy = {
        automated = {
          prune    = true
          selfHeal = true
        }
        syncOptions = [
          "CreateNamespace=true",
          "ServerSideApply=true"
        ]
      }
    }
  }
}

resource "kubernetes_manifest" "greeter_prod" {
  count = var.environment == "prod" ? 1 : 0

  depends_on = [helm_release.argocd]

  manifest = {
    apiVersion = "argoproj.io/v1alpha1"
    kind       = "Application"
    metadata = {
      name      = "greeter-prod"
      namespace = "argocd"
    }
    spec = {
      project = "default"

      source = {
        repoURL        = "https://github.com/phuongleeo/devops-technical-exercise"
        targetRevision = "solution"
        path           = "helm/prod"
        helm = {
          valueFiles = ["values.yaml"]
        }
      }

      destination = {
        server    = "https://kubernetes.default.svc"
        namespace = "greeter-prod"
      }

      syncPolicy = {
        automated = {
          prune    = true
          selfHeal = true
        }
        syncOptions = [
          "CreateNamespace=true",
          "ServerSideApply=true"
        ]
      }
    }
  }
}

