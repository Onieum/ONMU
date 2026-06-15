# 릴리스 체크리스트

## 모바일

- [ ] Flutter `dev`, `staging`, `prod` flavor 설정 완료
- [ ] flavor별 API base URL 설정 완료
- [ ] push 알림 토큰 등록 테스트 완료
- [ ] 실제 기기에서 위치/사진/알림 권한 테스트 완료
- [ ] Firebase App Distribution 또는 TestFlight 빌드 배포 완료
- [ ] crash reporting 활성화

## 백엔드

- [ ] `/healthz`와 `/readyz` 제공
- [ ] 데이터베이스 migration Job 테스트 완료
- [ ] API 계약 테스트 통과
- [ ] 실시간 reconnect/resync 테스트 완료
- [ ] 워커 재시도가 idempotent하게 동작

## 인프라

- [ ] Azure Terraform 전환 계획과 리소스 소유권 문서 검토 완료
- [ ] `terraform fmt`, `terraform validate`, staging `plan` 검증 완료
- [ ] ACR image build와 push 완료
- [ ] Azure Container Apps 또는 AKS staging 배포 완료
- [ ] 관리형 PostgreSQL/PostGIS 연결 확인
- [ ] Redis 연결 확인
- [ ] 오브젝트 스토리지 업로드와 signed URL 흐름 확인
- [ ] tile manifest/style/PMTiles Range/CORS smoke 통과
- [ ] 관측성 대시보드 준비
- [ ] 알림 규칙 준비
- [ ] cutover/rollback 담당자와 판단 기준 확정

## 프로젝트 관리

- [ ] Jira epic 생성 완료
- [ ] Sprint 0과 Sprint 1 backlog 준비 완료
- [ ] GitHub 저장소와 Jira 연결 완료
- [ ] `dev`와 `main` 브랜치 보호 적용 완료
- [ ] GitHub Actions 필수 check 설정 완료
- [ ] Dependabot 업데이트 PR 흐름 확인 완료
- [ ] Notion 프로젝트 허브와 Jira synced database 연결 완료
