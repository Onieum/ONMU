# Azure tfstate bootstrap apply 준비 runbook

이 문서는 ONMU Terraform state backend bootstrap을 실제 apply 전에 준비하는 절차다. 앱 리소스 생성, DNS 변경, DB migration, Key Vault secret value 작성, production apply는 포함하지 않는다.

## 1. 고정 결정

| 항목 | 기준 |
| --- | --- |
| Subscription | `대한상공회의소 Data School` |
| Resource group | 기존 `3dt-final-team1` 사용 |
| Storage Account 후보 | `onmutfstatekrc001`, `onmutfstatekrc002`, `onmutfstatekrc003` 순서 |
| Container | `tfstate` |
| State key | `onmu/staging/terraform.tfstate`, `onmu/prod/terraform.tfstate` |
| Backend auth | Azure AD auth, storage account key 미사용 |
| Budget gate | 2026-06-26까지 총 1,000,000원 상한 |

Subscription id, principal object id, raw plan output은 문서, PR, 채팅에 기록하지 않는다.

## 2. Apply 전 read-only 확인

```powershell
git fetch origin --prune
git log -1 --oneline origin/dev

.\scripts\windows\test-tfstate-backend-preflight.ps1
```

확인 결과는 다음 정보만 공유한다.

- active Azure account load와 enabled 상태
- resource group 존재와 region 일치 여부
- Storage Account 후보 availability 또는 기존 안전 설정 여부
- apply 미수행 확인

한글 subscription 표시명은 Windows shell/CLI stdout 인코딩에 따라 깨져 비교될 수 있으므로 기본 preflight의 필수 gate로 두지 않는다. 표시명 일치까지 엄격히 확인해야 하는 환경에서는 Azure CLI stdout UTF-8 처리가 정상인 shell에서 `-RequireSubscriptionNameMatch`를 명시해 실행한다.

## 3. Budget gate

`3dt-final-team1` 기준 2026-06-26까지 총 1,000,000원 상한을 넘기지 않는다.

| 항목 | 기준 |
| --- | --- |
| 권장 alert | 50%, 75%, 90%, 100% |
| apply 전 비용 보고 | 현재 누적 / 예상 증가분 / 상한 대비 잔여율 |
| Budget resource 생성 | 별도 승인 전까지 제외 |

ACR, ACA, PostgreSQL, Redis, CDN, Event Hubs는 skeleton/plan-only 이후 별도 apply 승인 전에 budget impact를 확인한다. WAF/APIM/Front Door Premium/Private Endpoint/AKS는 2026-06-26 전 staging 1차 범위에서 제외한다.

## 4. Local tfvars와 plan 경계

- 첫 bootstrap은 remote backend가 없으므로 local state와 `terraform init -backend=false`로 진행한다.
- 승인된 principal object id는 local ignored tfvars 또는 protected CI 변수로만 전달한다.
- `operator_principal_object_ids` 또는 `github_actions_principal_object_ids` 중 최소 하나 이상이 승인된 값으로 채워져야 실제 apply를 검토할 수 있다.
- plan 파일은 local ignored path에만 만들고, 공유는 resource/action 요약으로 제한한다.

## 5. Phase 1 / Phase 2

Phase 1:

- `create_resource_group=false`
- `create_state_container=false`
- Storage Account와 RBAC role assignment만 준비
- 선택적 delete lock은 별도 승인 후에만 적용

Phase 2:

- RBAC propagation 확인
- Terraform 실행 주체가 Blob data-plane 권한을 갖는지 확인
- `create_state_container=true`
- private `tfstate` container 생성
- backend config로 staging/prod init smoke

RBAC propagation 지연으로 container 생성이 `403`이면 phase 사이에 권한 전파를 기다리고 data-plane 권한을 재확인한다.

## 6. Workload Identity 후속 계획

Workload Identity 연동은 후속 CI PR로 분리한다.

- GitHub Actions OIDC로 Azure login
- apply job은 GitHub Environment `azure-staging-apply` 사용
- required reviewers와 branch 제한 적용
- plan identity와 apply identity/권한 분리 검토
- Workload Identity principal 실제 값은 protected variable 또는 environment secret으로만 관리

## 7. 다음 staging 연결 순서

1. tfstate backend bootstrap phase 1/2 완료
2. ACR 신규 생성 plan과 budget impact 확인
3. ACA/PostgreSQL/Redis/Blob/CDN/Event Hubs/observability skeleton 확장
4. clean DB + Flyway full migration
5. 실제 OAuth 로그인 기반 `/healthz`, `/readyz`, `/api/v1/users/me` smoke
6. Blob/CDN 기본 endpoint smoke
7. custom domain/TLS 연결 후 manifest/style/PMTiles Range/CORS smoke 반복

Dev snapshot dump/restore는 지금 수행하지 않는다. Clean staging smoke 통과 후 별도 승인으로 sanitized/minimal dump rehearsal만 검토한다.
