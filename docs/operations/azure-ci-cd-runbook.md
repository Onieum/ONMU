# Azure CI/CD runbook

이 문서는 ONMU의 Terraform 기반 Azure 배포를 GitHub Actions로 연결할 때의 단계와 보호 장치를 정의한다.

## 1. 원칙

- `dev`와 `main`에 직접 push하지 않는다.
- PR에서는 validate/plan/test까지만 자동 수행한다.
- `terraform apply`, DB migration, production deploy는 protected environment approval 이후에만 수행한다.
- secret 값은 GitHub logs, PR body, artifact에 남기지 않는다.
- Windows deploy/runtime 문제와 Azure deploy 문제를 같은 원인으로 단정하지 않는다.

## 2. Workflow 후보

| Workflow | Trigger | 역할 |
| --- | --- | --- |
| `pr-check.yml` | PR | docs/secret scan, Spring/Flutter test, Docker build 후보 |
| `terraform-plan.yml` | PR 또는 manual | fmt/validate/plan, artifact 저장 |
| `deploy-staging.yml` | manual + approval | staging image build/push, apply, migration, smoke |
| `deploy-prod.yml` | manual + approval | staging 검증 image digest 승격, production migration/cutover smoke |
| `smoke-staging.yml` | manual 또는 deploy 후 | smoke checklist 실행 |
| `rollback.yml` | manual + approval | previous revision/image/DNS rollback |

production은 자동 apply하지 않는다. `terraform plan -> approval -> apply -> infra readiness -> migration dry-run/check -> approval -> migration -> deploy -> smoke -> monitoring window` 순서를 기본 gate로 둔다.

## 3. PR 단계

PR에서 수행한다.

- `terraform fmt -check`
- `terraform validate`
- static policy check 후보
- Spring targeted tests
- Flutter analyze/test
- Docker image build
- docs link/secret scan
- Markdown UTF-8/encoding smoke 후보
- 문서 링크 존재 여부 후보

PR 단계에서는 수행하지 않는다.

- `terraform apply`
- production secret 변경
- DNS 변경
- DB destructive migration
- provider console 변경

## 4. Staging deploy 단계

1. 최신 base branch 확인
2. container image build
3. ACR push
4. Terraform plan review
5. protected environment approval
6. Terraform apply
7. infra readiness gate
8. DB migration job 실행
9. Spring rollout
10. Worker rollout
11. smoke checklist 실행
12. deploy summary 작성

Deploy summary에는 commit, image tag, environment, endpoint status, count, Azure resource name 같은 안전한 메타데이터만 포함한다.

## 5. Orchestration race guard

GitHub Actions는 Terraform이 만든 리소스가 실제로 준비되기 전에 Flyway나 app rollout이 먼저 접근하는 race condition을 막아야 한다.

권장 job 순서:

```text
terraform_plan
  -> protected_environment_approval
  -> terraform_apply
  -> infra_readiness_gate
  -> flyway_migration
  -> app_rollout
  -> smoke
```

`infra_readiness_gate`는 secret 값을 출력하지 않고 다음 상태만 확인한다.

- Terraform apply job이 성공했고 output artifact가 현재 commit/environment와 일치한다.
- PostgreSQL Flexible Server endpoint, database, extension 후보가 활성 상태다.
- migration job이 사용할 `DATABASE_URL` 또는 secret reference가 존재한다.
- Key Vault RBAC/secret reference 전파가 완료되어 runtime identity가 필요한 secret을 읽을 수 있다.
- Container Apps 또는 AKS runtime identity와 env binding 후보가 배포 대상 revision에 연결되어 있다.
- public traffic 전환 전 internal `/healthz` 또는 container readiness probe가 통과할 수 있는 네트워크 경로가 있다.

Flyway 실행 방식은 environment별로 하나만 선택한다.

- staging/production 권장: dedicated migration job을 먼저 실행하고, 성공 뒤 Spring rollout을 진행한다.
- 단순 dev/staging rehearsal 후보: Spring startup Flyway를 사용할 수 있지만 이 경우 별도 migration job을 동시에 실행하지 않는다.

두 방식이 동시에 같은 database를 찌르지 않도록 workflow `needs`와 environment lock을 둔다. migration이 실패하면 app rollout과 traffic cutover는 실행하지 않는다.

## 6. Production deploy 단계

Production은 staging smoke가 통과한 artifact/image를 승격한다.

- 새 image를 재빌드하지 않고 staging에서 검증한 digest를 우선 사용한다.
- production Key Vault secret 존재 여부와 managed identity 접근만 확인한다.
- migration은 dry-run/plan 성격의 사전 점검을 먼저 한다.
- traffic 전환 전 shadow smoke를 수행한다.
- cutover window와 rollback 담당자를 확정한다.

## 7. Migration job 기준

Spring DB schema는 Flyway가 관리한다.

- migration job은 Spring app image 또는 dedicated job image로 실행한다.
- migration logs에는 SQL parameter 값, 사용자 데이터, secret 값을 출력하지 않는다.
- migration version, status, duration, error type만 보고한다.
- 실패 시 app rollout 전에 중단한다.

## 8. Smoke job 기준

Smoke job은 [Azure smoke checklist](./azure-smoke-checklist.md)를 따른다.

Token이 필요한 API는 짧은 수명의 JWT를 job 내부에서만 생성하거나 approved secret reference를 사용한다. Authorization header와 token 값은 출력하지 않는다.

빌드 성공, container image push 성공, Terraform apply 성공은 각각 deploy 성공의 일부일 뿐이다. 최종 deploy 성공은 Spring startup, `/readyz`, public smoke, domain smoke까지 통과했을 때만 인정한다.

## 9. Documentation quality gate

운영 문서는 배포 절차의 일부이므로 PR 단계에서 다음을 후보로 검증한다.

- `docs/**/*.md`가 UTF-8로 저장되어 있는지 확인
- PowerShell과 zsh에서 한글이 깨지지 않는지 spot check
- GitHub 웹 렌더링에서 표/링크가 깨지지 않는지 확인
- 상대 링크가 존재하는지 확인
- secret/token/raw body 예시가 실제 값처럼 보이지 않는지 scan
- 문서에 쓰인 env var name이 `azure-secret-inventory.md`와 충돌하지 않는지 확인

## 10. 실패 분류

| 실패 유형 | 예시 | 우선 조치 |
| --- | --- | --- |
| Terraform | provider auth, quota, resource conflict | apply 중단, plan 수정 |
| Runtime | container crash, readiness fail | logs/health/readiness 확인 |
| Migration | Flyway fail, extension missing | DB 변경 중단, forward fix 판단 |
| Network/Edge | 502/530/1033, DNS, WAF | local/container health와 edge 분리 |
| App contract | API status/body schema mismatch | app PR 또는 rollback |
| Provider | OAuth/place/route external fail | provider console/secret/runtime 분리 |
