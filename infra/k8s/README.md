# Kubernetes 구조

이 디렉터리는 전체 manifest를 추가하기 전에 기본 구조를 먼저 잡아둔 상태입니다.

권장 구조:

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

`base`에는 공통 Deployment, Service, ServiceAccount, ConfigMap을 둡니다. `overlays`에는 환경별 replica 수, image tag, hostname, secret reference를 둡니다.

목표 플랫폼:

- AKS
- Azure CNI Overlay
- Cilium network policy
- Gateway API ingress
- Workload Identity
- Key Vault CSI Driver
- HPA와 KEDA
