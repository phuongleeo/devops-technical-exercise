resource "helm_release" "greeter" {
  count            = var.enabled_gitops ? 0 : 1 # manual deploy
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

resource "kubernetes_manifest" "greeter" {

  # Argo CD must be running before this resource can be applied.
  depends_on = [helm_release.argocd]

  manifest = {
    apiVersion = "argoproj.io/v1alpha1"
    kind       = "Application"
    metadata = {
      name      = "greeter-${var.environment}"
      namespace = "argocd"
    }
    spec = {
      project = "default"

      source = {
        repoURL        = "https://github.com/phuongleeo/devops-technical-exercise"
        targetRevision = "solution"
        path           = "helm/${var.environment}"
        helm = {
          valueFiles = ["values.yaml"]
        }
      }

      destination = {
        server    = "https://kubernetes.default.svc"
        namespace = "greeter-${var.environment}"
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

