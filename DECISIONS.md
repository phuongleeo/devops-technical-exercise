# DECISIONS.md

This file covers reasoning, not what was done. The commits show what was done.

---

## Decisions I'm least sure about

### Deployment roll-out strategy

- Strictly don't allow any downtime during a rolling update. `maxUnavailable: 0` ensures that Kubernetes will not take down a pod until a new one `maxSurge: 1` is ready.
  This is the safest option even in development environment with only 1 replica

- Avoid scheduling 2 replicas on the same node. `topologySpreadConstraints` with `maxSkew: 1` and `topologyKey: kubernetes.io/hostname` ensures that pods are spread across nodes. This is a best-effort guarantee — if the cluster has only 1 node, both pods will be scheduled there. Of course, you could replaced by podAntiAffinity, but it woulds cause a scheduling failure.

### `failureThreshold: 1` on the readiness probe

The service signals not-ready immediately on SIGTERM. One failed check means Kubernetes stops routing to the pod in approximately one probe period (5 seconds). This is intentional and matches the service's shutdown contract precisely.

The risk: if the `/readyz` endpoint has a transient failure (network blip inside the cluster), a pod could be removed from rotation unnecessarily. The alternative — `failureThreshold: 3` — would mean up to 15 seconds of routing traffic to a pod that is actively draining. Given that the service's shutdown behaviour is explicit and reliable by design, I chose 1.

What would change my mind: evidence of false positives from the probe under real cluster network conditions, or a service that has a less reliable readiness signal.

### NodePort over Ingress

For a local kind cluster, NodePort with a kind port mapping is the simplest path to "reachable from outside the cluster." An Ingress controller (nginx, traefik) adds a component that must be installed, configured, and kept running — overhead that adds no value for a single-service local exercise.

### Local Terraform state

No remote backend. For a local exercise this is correct — adding a remote backend would require AWS credentials or a Terraform Cloud account, which the exercise explicitly says not to use. In production this would be the first thing to change.

In real world, I've been using a remote state + Atlantis with locking for team collaboration. For a single-developer local exercise, local state is simpler and sufficient.

### Extension D

Prove it survives tested locally: `kubectl drain` + for loop curl testing
`hey` or `vegeta` for continuous load, capture the request log, and show zero 5xx during the drain and rolling update.

---

## What I considered and rejected

### The go 1.22 is obsoleted

But the exercise explicitly says to use it. I used 1.22 for the Dockerfile and local builds

### `scratch` vs `distroless` as the final image base

`scratch` produces a smaller image but has no CA certificates, no timezone data, and no `/etc/passwd`. `distroless/static-debian13:nonroot` adds roughly 2MB but provides CA certs and a real nonroot user (uid 65532). Since the service makes no outbound HTTPS calls today, `scratch` would work — but `distroless` is the safer default for a service that might add outbound calls later. Rejected `scratch` for this reason.

### `alpine` as the final image

Alpine has a shell and package manager, which increases attack surface unnecessarily. The binary is statically linked and needs neither. Rejected in favour of distroless.

### `minikube` vs `kind`

minikube is more user-friendly but multi-node requires extra flags and a hypervisor. kind runs nodes as Docker containers, is fully scriptable, and requires only Docker. For an exercise where "we will try to reproduce your cluster exactly" is an explicit requirement, kind's reproducibility is the deciding factor. Rejected minikube.

### `k3d` vs `kind`

k3d is faster and lighter (k3s inside Docker), but kind is the de facto standard for Kubernetes conformance testing and is what most CI systems use. For an exercise where reproducibility across machines matters, kind's wider adoption is an advantage. Not a strong rejection — k3d would have worked equally well.

### Kustomize vs Helm

I work with Helm alot, so I'd go with Helm
Also there is an official Terraform provider for Helm, which makes it easier to manage Helm releases from Terraform. Rejected Kustomize for this reason.

### `helm create` scaffold

The exercise explicitly says generated boilerplate scores nothing. The generated scaffold includes HPA, ServiceAccount, Ingress, PodDisruptionBudget, and test hooks — none of which are needed here. A minimal chart written from scratch is easier to reason about and easier to explain line by line. Rejected the scaffold entirely.

### PodDisruptionBudget

Would normally add `minAvailable: 1` to prevent voluntary disruptions (node drains, cluster upgrades) from taking all pods down simultaneously. Left out because with `topologySpreadConstraints` and `maxUnavailable: 0` on the rolling update strategy, the deployment already protects against involuntary disruptions. A PDB would add protection specifically against `kubectl drain` — relevant for extension D but not required for the core tasks.

### `kubernetes` provider vs `helm` provider in Terraform

The `kubernetes` provider can manage raw Kubernetes resources. The `helm` provider wraps Helm releases. Since I'm using Helm for packaging, the `helm` provider is the natural choice — it delegates resource management to Helm rather than duplicating it in Terraform. Using the `kubernetes` provider would mean managing the Deployment and Service directly in Terraform, which would duplicate the Helm chart.

---

## Ambiguities in the brief and assumptions made

### "reachable from outside the cluster"

The brief doesn't specify how. I interpreted this as "reachable from the host machine running the cluster." NodePort + kind port mapping (host:8080 → container:30080) satisfies this. If "outside" meant "from another machine on the network," a LoadBalancer or Ingress with a real IP would be needed.

### "stay available across the loss of a single node"

I interpreted this as: if one of the two worker nodes is lost, the service continues to serve traffic. `topologySpreadConstraints` with `maxSkew: 1` and `topologyKey: kubernetes.io/hostname` ensures pods are spread across nodes. With `replicaCount: 2` (default) and 2 workers, one pod per node — losing one node loses one pod, but the other continues. With `replicaCount: 1` (dev environment), this guarantee doesn't hold. That's a deliberate trade-off: dev is not expected to be HA.

### `terminationGracePeriodSeconds`

The brief describes the shutdown sequence precisely: SIGTERM → not-ready → wait `SHUTDOWN_DELAY_SECONDS` → drain `DRAIN_TIMEOUT_SECONDS`. The pod's `terminationGracePeriodSeconds` ( default 30 ) must exceed the sum of these. I set it to 35 (10 + 20 + 5 buffer). If an operator changes `SHUTDOWN_DELAY_SECONDS` or `DRAIN_TIMEOUT_SECONDS` via Helm values, they must also update `terminationGracePeriodSeconds` manually — this coupling is a known limitation. Helm doesn't support arithmetic in templates without a helper function, so I hardcoded 35 with a comment explaining the formula.

---

## What I'd do differently for something genuinely production-facing

**Image registry and digest pinning.** Push to a real registry (ECR, GCR, Docker Hub, GitHub packages) instead of loading into kind. Pin images by digest (`image@sha256:...`) rather than mutable tags to make deployments reproducible and auditable.

**Remote Terraform state with locking.** S3 + DynamoDB lock (or Terraform Cloud). State locking prevents concurrent applies from corrupting state. Separate state files per environment (or Terraform workspaces) so a `dev` apply can't accidentally affect `prod`.

**for better collaboration** use Atlantis to run Terraform in a controlled environment with PR-based approvals.

**PodDisruptionBudget.** Add `minAvailable: 1` to protect against voluntary disruptions during node maintenance or cluster upgrades.

**Network policies.** Restrict ingress to only the ports the service listens on, and egress to only what the service needs. The current deployment has no network policy, which means any pod in the cluster can reach it.

**Resource limits tuned from profiling.** The limits I set (200m CPU, 64Mi memory) are conservative guesses. In production, profile under realistic load and set limits based on p99 usage plus headroom. Overly tight limits cause throttling; overly loose limits waste capacity.

**Horizontal Pod Autoscaler.** Scale on request rate or CPU. The service is stateless, so horizontal scaling is straightforward. Not added here because the exercise doesn't require it.

**Observability.** The service already exposes Prometheus metrics at `/metrics`. In production: deploy Prometheus + Alertmanager, write SLO-based alerts (error rate > 1%, latency p99 > 500ms), connect to Grafana. The `/boom` endpoint exists specifically to demonstrate an alert firing — I'd write an alert on `greeter_http_requests_total{status="500"}` rate.

---

## What I deliberately left out and why

**Ingress controller.** NodePort is sufficient for a local cluster. An Ingress controller adds a component that needs to be installed, configured, and maintained. For a single service on a local cluster, the complexity is not justified.

**ServiceAccount with RBAC.** The service makes no Kubernetes API calls. The default ServiceAccount is fine for this exercise. See above for what I'd do in production.

**Horizontal Pod Autoscaler.** Not required by the exercise. The replica count is set per environment via Helm values.

**PodDisruptionBudget.** Omitted from core tasks (see above). Would add for production.

**CI pipeline (Extension A).** Not attempted. Would be a GitHub Actions workflow: `go test ./...` → `docker build` → push to registry → update Helm values with new image tag → open PR or apply directly.

**Observability (Extension B).** Not attempted. The service's `/metrics` endpoint is ready; adding Prometheus is straightforward with `kube-prometheus-stack`. The alert I'd write: fire when the 5-minute rate of 500 responses on any path exceeds 0.1/s.

**GitOps (Extension C).** Not attempted. Would use ArgoCD with separated per environment, ArgoCD will track an environment directory in a Git repository ( dev / prod ) to start the synchronization.
