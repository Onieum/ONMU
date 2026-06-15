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
| `Terraform Validate` | PR | fmt/validate/tflint/checkov 후보 |
| `Terraform Plan Staging` | PR 또는 manual | staging plan 생성, artifact 저장 |
| `Deploy Azure Staging` | manual + approval | image build/push, apply, migration, smoke |
| `Deploy Azure Production` | manual + approval | production deploy/cutover smoke |
| `Rollback Azure` | manual + approval | previous revision/image/DNS rollback |

## 3. PR 단계

PR에서 수행한다.

- `terraform fmt -check`
- `terraform validate`
- static policy check 후보
- Spring targeted tests
- Flutter analyze/test
- Docker image build
- docs link/secret scan

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
7. DB migration job 실행
8. Spring rollout
9. Worker rollout
10. smoke checklist 실행
11. deploy summary 작성

Deploy summary에는 commit, image tag, environment, endpoint status, count, Azure resource name 같은 안전한 메타데이터만 포함한다.

## 5. Production deploy 단계

Production은 staging smoke가 통과한 artifact/image를 승격한다.

- 새 image를 재빌드하지 않고 staging에서 검증한 digest를 우선 사용한다.
- production Key Vault secret 존재 여부와 managed identity 접근만 확인한다.
- migration은 dry-run/plan 성격의 사전 점검을 먼저 한다.
- traffic 전환 전 shadow smoke를 수행한다.
- cutover window와 rollback 담당자를 확정한다.

## 6. Migration job 기준

Spring DB schema는 Flyway가 관리한다.

- migration job은 Spring app image 또는 dedicated job image로 실행한다.
- migration logs에는 SQL parameter 값, 사용자 데이터, secret 값을 출력하지 않는다.
- migration version, status, duration, error type만 보고한다.
- 실패 시 app rollout 전에 중단한다.

## 7. Smoke job 기준

Smoke job은 [Azure smoke checklist](./azure-smoke-checklist.md)를 따른다.

Token이 필요한 API는 짧은 수명의 JWT를 job 내부에서만 생성하거나 approved secret reference를 사용한다. Authorization header와 token 값은 출력하지 않는다.

빌드 성공, container image push 성공, Terraform apply 성공은 각각 deploy 성공의 일부일 뿐이다. 최종 deploy 성공은 Spring startup, `/readyz`, public smoke, domain smoke까지 통과했을 때만 인정한다.

## 8. 실패 분류

| 실패 유형 | 예시 | 우선 조치 |
| --- | --- | --- |
| Terraform | provider auth, quota, resource conflict | apply 중단, plan 수정 |
| Runtime | container crash, readiness fail | logs/health/readiness 확인 |
| Migration | Flyway fail, extension missing | DB 변경 중단, forward fix 판단 |
| Network/Edge | 502/530/1033, DNS, WAF | local/container health와 edge 분리 |
| App contract | API status/body schema mismatch | app PR 또는 rollback |
| Provider | OAuth/place/route external fail | provider console/secret/runtime 분리 |
