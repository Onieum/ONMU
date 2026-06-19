# MapLibre 개발 타일 manifest 운영

이 문서는 SCRUM-9 MapLibre 전환의 1차 PR 범위인 PMTiles object, manifest, style JSON 업로드 기준을 정리한다. Flutter MapLibre UI, 장소 provider, 경로 provider 구현은 이 문서 범위가 아니다.

## 목표

Flutter 앱은 PMTiles 파일 URL을 직접 하드코딩하지 않고 manifest pointer를 읽는다. manifest가 현재 style과 tileset object를 가리키고, 롤백 시에는 manifest pointer만 이전 object로 되돌릴 수 있게 한다.

개발용 object storage는 MinIO를 사용한다. 현재 팀의 release/pre-prod tile smoke는 Azure Blob Storage와 Azure Front Door 기준이며, 이 문서의 Cloudflare/Windows gateway 경로는 legacy dev opt-in으로만 사용한다. 운영 Azure Blob/Front Door 전환 시에도 앱이 읽는 경계는 `manifest.json`으로 유지한다.

## Object layout

| 항목 | 기본값 |
| --- | --- |
| Bucket | `onmu-tiles` |
| PMTiles object | `pmtiles/korea-dev.pmtiles` |
| Manifest object | `tiles/manifest.json` |
| Style object | `styles/onmu-light.json` |
| Local manifest URL | `http://localhost:9000/onmu-tiles/tiles/manifest.json` |
| Staging Front Door manifest URL | `https://fde-onmustagingkrc001-hgbmd5cah5bke7c9.a01.azurefd.net/manifest.json` |
| Future custom-domain manifest URL | `https://tiles.onmu.cloud/manifest.json` |

PMTiles 파일은 저장소에 커밋하지 않는다. `.gitignore`는 `*.pmtiles`를 무시한다.

## Public tile gateway

이 절은 Windows dev용 legacy tile gateway 설명이다. `tiles.onmu.cloud`를 Azure Front Door custom domain으로 넘긴 뒤에는 이 Cloudflare/Windows gateway 경로를 release/pre-prod smoke에 사용하지 않는다. 과거 Windows dev에서는 Cloudflare Tunnel에서 바로 MinIO bucket path로 rewrite할 수 없어 Windows 서버에 작은 local gateway를 두었다.

```text
tiles.onmu.cloud
  -> Cloudflare Tunnel onmu-dev-api
  -> http://localhost:19100
  -> http://localhost:9000/onmu-tiles/{objectKey}
```

gateway는 다음 공개 경로만 MinIO object로 전달한다.

| Public path | MinIO object |
| --- | --- |
| `/manifest.json` | `tiles/manifest.json` |
| `/styles/*.json` | `styles/*.json` |
| `/pmtiles/*.pmtiles` | `pmtiles/*.pmtiles` |

Windows 서버에서는 다음 스크립트로 gateway를 시작한다.

```powershell
powershell -NoProfile -ExecutionPolicy Bypass `
  -File scripts\windows\start-map-tiles-gateway.ps1
```

Cloudflare ingress는 legacy Windows dev에서만 `infra/cloudflare/cloudflared-local.yml`의 `tiles.onmu.cloud -> http://localhost:19100` 구성을 사용한다. Azure staging/release smoke에서는 Front Door default endpoint를 기본값으로 보며, `tiles.onmu.cloud`는 custom domain cutover가 끝난 뒤에만 기본 smoke 기준으로 승격한다. local smoke만 필요하면 Flutter에 `ONMU_TILE_MANIFEST_URL=http://localhost:9000/onmu-tiles/tiles/manifest.json`를 주입해 gateway 없이 검증할 수 있다.

## Seed script

Windows PowerShell에서 실행한다.

```powershell
powershell -NoProfile -ExecutionPolicy Bypass `
  -File scripts\windows\seed-map-tiles-minio.ps1 `
  -PmtilesSourceUrl $env:ONMU_PMTILES_SOURCE_URL
```

이미 받은 로컬 PMTiles 파일이 있으면 URL 대신 파일 경로를 전달한다.

```powershell
powershell -NoProfile -ExecutionPolicy Bypass `
  -File scripts\windows\seed-map-tiles-minio.ps1 `
  -PmtilesFile C:\path\to\korea-dev.pmtiles
```

스크립트는 host에 `mc` 설치를 요구하지 않는다. Docker의 임시 `minio/mc` 컨테이너를 사용하며, `OBJECT_STORAGE_ENDPOINT`가 `localhost` 또는 `127.0.0.1`이면 컨테이너 내부 호출용으로 `host.docker.internal`로 변환한다.

업로드 시 필요한 MinIO credential은 `MINIO_ROOT_USER`, `MINIO_ROOT_PASSWORD` 또는 동명 파라미터로만 전달한다. 값은 출력하지 않는다.

## Dry-run smoke

실제 PMTiles source URL이 없을 때는 작은 임시 파일로 wiring만 확인할 수 있다. 이 검증은 실제 PMTiles 성공을 의미하지 않는다.

```powershell
$dummy = Join-Path $env:TEMP "onmu-dummy.pmtiles"
[System.IO.File]::WriteAllText($dummy, "dummy-pmtiles-smoke", [System.Text.UTF8Encoding]::new($false))
powershell -NoProfile -ExecutionPolicy Bypass `
  -File scripts\windows\seed-map-tiles-minio.ps1 `
  -PmtilesFile $dummy `
  -DryRun
Remove-Item -LiteralPath $dummy -Force
```

dry-run은 manifest/style/CORS JSON 생성과 출력 구조를 검증하지만 MinIO에 업로드하지 않는다.

## Manifest contract

`tiles/manifest.json`은 다음 정보를 포함한다.

- `current`: 현재 PMTiles object, style URL, bounds/center, cache metadata
- `rollback`: 이전 manifest 또는 이전 PMTiles object로 되돌릴 때 사용할 자리
- `styleUrl`: MapLibre style JSON URL
- `tileset.url`: `pmtiles://` 형식의 PMTiles URL
- `bounds`: Korea dev bounds
- `center`: Korea dev center
- `generatedAt`: UTC 생성 시각

앱은 manifest URL만 환경별로 주입받고, PMTiles object URL은 manifest에서 읽는다.

## Style

`styles/onmu-light.json`은 MapLibre style JSON이다. source는 `pmtiles://.../pmtiles/korea-dev.pmtiles` 형식을 사용한다. 색상은 ONMU 화면과 충돌하지 않도록 밝은 beige/coral 계열로 시작한다.

Protomaps basemap 계층 이름을 기준으로 작성했으므로, 실제 PMTiles schema가 다르면 style layer의 `source-layer`를 후속 PR에서 조정한다.

### Water layer 스타일링

`water` source-layer는 바다뿐 아니라 하천 line, 내륙 수역 polygon, 일반화된 river/stream/canal polygon을 함께 담을 수 있다. 단일 fill layer로 전체를 칠하면 서울/성남/광주처럼 바다가 아닌 내륙이 바다색 면으로 크게 보일 수 있으므로, 생성되는 style은 수역을 다음처럼 나눈다.

- `water`: `Polygon` 중 `ocean`, `bay`, `lake`, `reservoir` 계열만 낮은 줌부터 fill한다.
- `water-river-area`: `river`, `stream`, `canal` polygon은 `minzoom=12`부터 낮은 opacity로 fill한다.
- `water-river-line`: `river`, `stream`, `canal` line은 `minzoom=9`부터 얇은 line으로 표시한다.

업로드 전에는 최소한 다음 위치를 웹/에뮬레이터에서 확인한다.

- 서울/성남/광주 경계 주변: 내륙이 넓은 바다색 면으로 보이지 않아야 한다.
- 한강/팔당호 주변: 큰 수역은 사라지지 않고 하천은 과하게 두껍지 않아야 한다.
- 해안/만 주변: `ocean`/`bay`가 배경과 구분되어야 한다.

### POI와 녹지 label 밀도

현재 모바일 지도 UX는 후보 marker와 경로 line이 앱에서 강조되고, basemap은 길 찾기 맥락을 보조하는 역할이다. `seed-map-tiles-minio.ps1`가 생성하는 `onmu-light` style은 지도 앱에 가까운 읽기감을 위해 다음 계층을 분리한다.

- `landuse-park`: 공원, 숲, 잔디, 정원 계열을 기존 landuse보다 녹색 계열로 분리한다.
- `transit-station-labels`: 지하철역, 철도역, 버스 정류장 계열 POI label을 일반 POI보다 먼저 표시한다.
- `poi-labels`: 일반 POI label은 낮은 opacity와 작은 글자 크기로 유지해 후보 번호 marker와 route line을 가리지 않게 한다.

이 변경은 style JSON 생성 로직만 바꾼다. 실제 Azure Blob/Front Door object 반영은 Android 지도 smoke와 rollback 기준을 확인한 뒤 별도 운영 단계에서 수행한다.

style 생성 구조만 확인하려면 업로드 없이 dry-run을 먼저 실행한다.

```powershell
.\scripts\windows\seed-map-tiles-minio.ps1 `
  -PmtilesSourceUrl https://tiles.onmu.cloud/pmtiles/korea-dev.pmtiles `
  -DryRun `
  -KeepTemp
```

`DryRun`은 MinIO object를 바꾸지 않는다. 실제 `styles/onmu-light.json` 또는 `tiles/manifest.json` 업로드는 화면 검증과 rollback 대상을 확인한 뒤 별도 운영 단계로 진행한다.

## CORS와 공개 읽기

스크립트는 bucket에 read-only anonymous download를 설정한다. CORS 기본 origin은 다음과 같다.

- `http://localhost:5173`
- `http://127.0.0.1:5173`
- `http://localhost:5174`
- `http://127.0.0.1:5174`
- `http://localhost:5175`
- `http://127.0.0.1:5175`
- `https://staging-api.onmu.cloud`

`https://dev-api.onmu.cloud`와 `https://int-api.onmu.cloud` origin은 legacy/dev opt-in 또는 integration 경로를 명시 점검할 때만 추가한다.

tile gateway는 위 origin에 대해 `Access-Control-Allow-Origin`을 반환한다. `Range` 요청 검증을 위해 `Access-Control-Expose-Headers`에는 `Accept-Ranges`, `Content-Length`, `Content-Range`, `Content-Type`, `ETag`, `Last-Modified`, `Cache-Control`을 유지한다.

필요하면 tile gateway 시작 시 `ONMU_TILE_ALLOWED_ORIGINS` 또는 `-AllowedOrigins`로 명시적으로 확장한다. MinIO seed CORS는 `-CorsAllowedOrigins`로 확장할 수 있다. wildcard origin을 운영 기준으로 쓰지 않는다.

public gateway 반영 뒤에는 브라우저 개발 origin별로 manifest/style/Range CORS를 확인한다.

```powershell
$origin = "http://127.0.0.1:5175"
Invoke-WebRequest "https://fde-onmustagingkrc001-hgbmd5cah5bke7c9.a01.azurefd.net/manifest.json" -Headers @{ Origin = $origin }
Invoke-WebRequest "https://fde-onmustagingkrc001-hgbmd5cah5bke7c9.a01.azurefd.net/styles/onmu-light.json" -Headers @{ Origin = $origin }
curl.exe -i "https://fde-onmustagingkrc001-hgbmd5cah5bke7c9.a01.azurefd.net/pmtiles/korea-dev.pmtiles" `
  -H "Origin: $origin" `
  -H "Range: bytes=0-15"
```

## 환경변수

| 환경변수 | 용도 |
| --- | --- |
| `ONMU_PMTILES_SOURCE_URL` | PMTiles source URL. 값은 문서/PR/log에 남기지 않는다. |
| `ONMU_TILE_BUCKET` | 기본값 `onmu-tiles` |
| `ONMU_PMTILES_OBJECT_KEY` | 기본값 `pmtiles/korea-dev.pmtiles` |
| `ONMU_TILE_MANIFEST_OBJECT_KEY` | 기본값 `tiles/manifest.json` |
| `ONMU_TILE_STYLE_OBJECT_KEY` | 기본값 `styles/onmu-light.json` |
| `ONMU_TILE_LOCAL_MANIFEST_URL` | 로컬 manifest URL |
| `ONMU_TILE_PUBLIC_MANIFEST_URL` | 공개 manifest URL |
| `ONMU_TILE_PUBLIC_BASE_URL` | 공개 tile object base URL |
| `ONMU_TILE_STYLE_TILESET_URL` | style JSON에 넣을 `pmtiles://` URL override |
| `ONMU_TILE_CACHE_CONTROL` | object cache-control |

MinIO 접속은 기존 `OBJECT_STORAGE_ENDPOINT`, `MINIO_ROOT_USER`, `MINIO_ROOT_PASSWORD`를 사용한다. credential 값은 출력하지 않는다.

## Rollback

1. 이전 PMTiles object를 지우지 않고 유지한다.
2. manifest의 `rollback.previousManifestUrl` 또는 `rollback.previousPmtilesObjectKey`에 되돌릴 대상을 기록한다.
3. 문제가 생기면 이전 manifest를 `tiles/manifest.json`으로 다시 업로드하거나, 같은 object key로 검증된 PMTiles를 재업로드한다.
4. Flutter는 manifest pointer만 다시 읽으면 된다.

## 남은 작업

- 실제 Korea dev PMTiles source URL 확보
- 실제 PMTiles schema 기준 style layer 검증
- Flutter MapLibre UI에서 manifest fetch 후 `pmtiles://` protocol 등록
- `tiles.onmu.cloud` Azure Front Door custom domain 전환과 Android MapLibre smoke
