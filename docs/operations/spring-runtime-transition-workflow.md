# Spring runtime 전환 및 팀원 연결 검증

이 문서는 Spring Boot Main API runtime과 Cloudflare Access TCP 기반 dev DB 연결을 팀원이 검증할 때 쓰는 안내입니다.

비밀번호, token, secret 값은 채팅방, Notion, GitHub에 공유하지 않고 터미널 환경변수로만 사용합니다.

## ONMU dev API / dev DB 연결 테스트 안내

## 1. 필요한 권한

각 팀원에게 필요한 권한:

- Key Vault에서 본인 dev DB password secret을 읽을 수 있는 권한
- API 연결 테스트가 필요한 경우 `dev-api-access-token` 읽기 권한

공유하지 않는 항목:

- `dev-api-refresh-token`
- 전체 secret 관리 권한
- `Secrets Officer` 권한
- Cloudflare API token

## 2. 개인별 DB password secret 이름

| 사용자 | Secret name |
| --- | --- |
| `3dt001` | `dev-db-3dt001-password` |
| `3dt005` | `dev-db-3dt005-password` |
| `3dt016` | `dev-db-3dt016-password` |
| `3dt028` | `dev-db-3dt028-password` |

아래 예시는 `3dt005` 기준입니다. 본인 계정에 맞게 username과 secret name만 바꿔서 실행합니다.

## 3. Azure 로그인 확인

```bash
az account show
```

로그인이 안 되어 있으면:

```bash
az login
```

## 4. Key Vault에서 본인 DB password 읽기

Windows PowerShell:

```powershell
$env:AZURE_KEY_VAULT_NAME="onmu-dev-kv-27db5e"
$env:PGPASSWORD = az keyvault secret show --vault-name $env:AZURE_KEY_VAULT_NAME --name dev-db-3dt005-password --query value -o tsv
```

Mac/Linux:

```bash
export AZURE_KEY_VAULT_NAME="onmu-dev-kv-27db5e"
export PGPASSWORD="$(az keyvault secret show --vault-name "$AZURE_KEY_VAULT_NAME" --name dev-db-3dt005-password --query value -o tsv)"
```

주의:

- `echo $PGPASSWORD` 같은 명령으로 값을 출력하지 않습니다.
- 터미널 로그나 스크린샷에 secret 값이 남지 않게 합니다.

## 5. Mac DNS 캐시 확인

Mac에서 `dig`나 `nslookup`은 성공하지만 `cloudflared`가 `lookup db-dev.onmu.cloud: no such host`를 내면 macOS system resolver 지연 또는 DNS negative cache일 수 있습니다.

Access TCP 실행 전에 아래 명령으로 system resolver를 확인합니다.

```bash
dscacheutil -q host -a name db-dev.onmu.cloud
python3 - <<'PY'
import socket
print(socket.getaddrinfo("db-dev.onmu.cloud", 443))
PY
```

실패하면 DNS cache를 정리하고 잠시 기다린 뒤 다시 확인합니다.

```bash
sudo dscacheutil -flushcache
sudo killall -HUP mDNSResponder
```

## 6. Access TCP 터널 열기

별도 터미널에서 아래 명령을 실행하고 계속 켜둡니다.

```bash
cloudflared access tcp --hostname db-dev.onmu.cloud --url localhost:15432
```

로컬 PC에서 `15432` 포트를 이미 쓰고 있으면 `15433`으로 바꿔 실행합니다.

```bash
cloudflared access tcp --hostname db-dev.onmu.cloud --url localhost:15433
```

이 경우 아래 `psql` 명령의 port도 `15433`으로 바꿉니다.

## 7. DB SELECT 검증

`3dt005` 기준:

```bash
psql -h localhost -p 15432 -U 3dt005 -d onmu -c "select current_user, count(*) from users group by current_user;"
```

기대 결과:

- `current_user`가 본인 계정으로 나옵니다.
- `users` count 조회가 성공합니다.

## 8. Read-only 권한 검증

개인 계정은 SELECT 중심 계정이라 `CREATE`/`INSERT`는 실패해야 정상입니다. 혹시 권한이 잘못 열려 있어도 데이터가 남지 않도록 `rollback` 포함 명령으로 확인합니다.

DDL 차단 확인:

```bash
psql -h localhost -p 15432 -U 3dt005 -d onmu -v ON_ERROR_STOP=1 -c "begin; create table public.__onmu_3dt005_should_fail(id int); rollback;"
```

DML 차단 확인:

```bash
psql -h localhost -p 15432 -U 3dt005 -d onmu -v ON_ERROR_STOP=1 -c "begin; insert into users (id, public_id, display_name, status, created_at, updated_at) values (gen_random_uuid(), 'readonly_should_fail', 'readonly_should_fail', 'active', now(), now()); rollback;"
```

기대 결과:

- `permission denied` 또는 `read-only transaction` 관련 에러가 나면 정상입니다.
- 명령 exit code가 실패로 나오는 것도 정상입니다.
- 성공하면 권한이 과하게 열린 것이므로 바로 공유합니다.

## 9. API 연결 테스트가 필요한 경우

Key Vault에서 API access token만 읽어서 사용합니다. `dev-api-refresh-token`은 일반 연결 확인 용도로 공유하지 않습니다.

Windows PowerShell:

```powershell
$env:ONMU_API_BASE_URL="https://dev-api.onmu.cloud"
$env:ONMU_DEV_ACCESS_TOKEN = az keyvault secret show --vault-name onmu-dev-kv-27db5e --name dev-api-access-token --query value -o tsv
```

Mac/Linux:

```bash
export ONMU_API_BASE_URL="https://dev-api.onmu.cloud"
export ONMU_DEV_ACCESS_TOKEN="$(az keyvault secret show --vault-name onmu-dev-kv-27db5e --name dev-api-access-token --query value -o tsv)"
```

Flutter API mode 예시:

```env
ONMU_DATA_SOURCE=api
ONMU_API_BASE_URL=https://dev-api.onmu.cloud
```

주의:

- token 없이 `/api/v1/**` 호출 시 `401`이 정상입니다.
- 보호 API는 bearer token 포함해서 호출해야 합니다.

## 10. 정리

Windows PowerShell:

```powershell
Remove-Item Env:\PGPASSWORD
Remove-Item Env:\ONMU_DEV_ACCESS_TOKEN
```

Mac/Linux:

```bash
unset PGPASSWORD
unset ONMU_DEV_ACCESS_TOKEN
```

## 11. Mac Codex 검증 결과

Mac Codex 기준으로 아래 검증을 완료했습니다.

- Key Vault `dev-db-3dt005-password` 읽기 성공
- Access TCP `localhost:15432` 정상
- SELECT 결과 `3dt005|4` 성공
- CREATE/INSERT는 `read-only transaction`으로 정상 차단
- API token 호출 정상
- secret 값은 출력하지 않음

## 12. 결과 공유 양식

```text
- OS:
- Azure login 상태:
- Key Vault password 읽기 성공 여부:
- DNS resolve 결과:
- Access TCP tunnel 결과:
- SELECT 결과:
- CREATE TABLE 차단 결과:
- INSERT 차단 결과:
- API 연결 결과, 해당자만:
- secret 미출력 확인:
- 최종 결론:
```
