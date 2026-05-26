# Kubernetes Layout

This directory is intentionally scaffolded before full manifests are added.

Recommended structure:

```text
base/
  api/
  realtime-gateway/
  workers/
  ingress/
overlays/
  dev/
  staging/
  prod/
```

Use `base` for common Deployments, Services, ServiceAccounts, and ConfigMaps. Use overlays for environment-specific replica counts, image tags, hostnames, and secrets references.

Target platform:

- AKS
- Azure CNI Overlay
- Cilium network policy
- Gateway API ingress
- Workload Identity
- Key Vault CSI Driver
- HPA and KEDA
