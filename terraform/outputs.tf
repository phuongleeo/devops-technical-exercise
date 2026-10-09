output "release_name" {
  description = "Helm release name."
  value       = helm_release.greeter.name
}

output "namespace" {
  description = "Kubernetes namespace."
  value       = helm_release.greeter.namespace
}

output "service_url" {
  description = "URL to access the service (via kind port mapping)."
  value       = "http://localhost:${var.environment == "dev" ? 8000 : 8081}/"
}
