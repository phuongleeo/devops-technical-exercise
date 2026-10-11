output "release_name" {
  description = "Helm release name."
  value       = var.enabled_gitops ? "" : helm_release.greeter[0].name
}

output "service_url" {
  description = "URL to access the service (via kind port mapping)."
  value       = <<EOF
      Greeter:
       • DEV: http://localhost:8080/
       • PROD: http://localhost:8081/
      Argocd: http://localhost:8082/
      Prometheus: http://localhost:9090/
  EOF
}
