# MapLibre 개발 타일 manifest 운영

이 문서는 SCRUM-9 MapLibre 전환의 1차 PR 범위인 PMTiles object, manifest, style JSON 업로드 기준을 정리한다. Flutter MapLibre UI, 장소 provider, 경로 provider 구현은 이 문서 범위가 아니다.

## 목표

Flutter 앱은 PMTiles 파일 URL을 직접 하드코딩하지 않고 manifest pointer를 읽는다. manifest가 현재 style과 tileset object를 가리키고, 롤백 시에는 manifest pointer만 이전 object로 되돌릴 수 있게 한다.

개발용 object storage는 MinIO를 사용한다. 운영 Azure Blob/CDN 전환 시에도 앱이 읽는 경계는 `manifest.json`으로 유지한다.

## Object layout

| 항목 | 기본값 |
| --- | --- |
| Bucket | `onmu-tiles` |
| PMTiles object | `pmtiles/korea-dev.pmtiles` |
| Manifest object | `tiles/manifest.json` |
| Style object | `styles/onmu-light.json` |
| Local manifest URL | `http://localhost:9000/onmu-tiles/tiles/manifest.json` |
| Public manifest URL | `https://tiles.onmu.cloud/manifest.json` |

PMTiles 파일은 저장소에 커밋하지 않는다. `.gitignore`는 `*.pmtiles`를 무시한다.

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

## CORS와 공개 읽기

스크립트는 bucket에 read-only anonymous download를 설정한다. CORS 기본 origin은 다음과 같다.

- `http://localhost:5173`
- `http://127.0.0.1:5173`
- `https://dev-api.onmu.cloud`
- `https://int-api.onmu.cloud`

필요하면 `-CorsAllowedOrigins`로 명시적으로 확장한다. wildcard origin을 운영 기준으로 쓰지 않는다.

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
- public `tiles.onmu.cloud` routing/CDN 설정
