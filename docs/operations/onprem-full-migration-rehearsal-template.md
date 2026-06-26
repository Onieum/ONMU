# On-prem full migration rehearsal report template

이 템플릿은 Azure staging primary를 on-prem primary로 완전히 이전하기 전 dry-run 리허설 결과를 남기기 위한 양식이다. 실제 secret value, DB password, OAuth code/state/idToken, bearer token, 사용자 raw row, media raw URL은 기록하지 않는다.

## Window

- rehearsal id:
- date/time:
- operator:
- repo commit:
- target OS:
- target API host:
- target tile host:
- source freeze simulated: yes/no
- route cutover simulated: yes/no

## Readiness Gate

| Gate | Status | Evidence |
| --- | --- | --- |
| PR/branch latest with `dev` |  |  |
| target `/healthz` |  |  |
| target `/readyz` |  |  |
| no-token `/api/v1/users/me` |  |  |
| DB restore-test |  |  |
| media/object checkpoint |  |  |
| tile manifest/style/PMTiles |  |  |
| provider env presence |  |  |
| monitoring/alert dry-run |  |  |
| backup/restore-test |  |  |
| OAuth mobile smoke |  |  |
| rollback/reverse migration plan |  |  |

## RPO / RTO / HA

- RPO target:
- RTO target:
- primary policy: single primary / cold standby / hot standby
- cold standby target:
- Azure retention period:
- last successful backup:
- last successful restore-test:

## Data

- DB dump status:
- `pg_restore` exit:
- extension status:
- Flyway latest:
- core table presence:
- source/target count status:
- object/media count:
- tile object count:
- outbox pending count:

## Runtime

- Java version:
- Spring package/build:
- process manager: launchd / Task Scheduler / manual
- access log path:
- alert channel:
- monitoring soak duration:
- restart recovery status:

## Provider / Mobile

- Kakao OAuth:
- Naver OAuth:
- Google OAuth:
- iOS smoke:
- Android smoke:
- FCM/APNs scope: live / dry-run / excluded
- map/search provider:
- route provider:
- `--require-full-env` preflight decision:
- provider env missing count:
- notification env missing count:

## Domain Smoke

| Domain | Status | Count/Path Evidence |
| --- | --- | --- |
| home/user/profile |  |  |
| group/plan |  |  |
| chat/read/realtime |  |  |
| media/record |  |  |
| settlement |  |  |
| map/search/route |  |  |
| notification |  |  |

## Decision

- rehearsal verdict:
- blockers:
- risks:
- next action:
- primary source-of-truth declaration allowed: yes/no

## Secret Safety Check

- secret values omitted:
- token/code/state/idToken omitted:
- user raw data omitted:
- media raw URL omitted:
