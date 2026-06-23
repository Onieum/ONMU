# ONMU Settlement 아키텍처

## 목적

정산은 `groups/{groupId}/plans/{planId}` 하위의 약속 단위 협업 도메인이다. 사용자는 진행중이거나 지난 약속에서 방문장소별 지출을 입력하고, 서버가 계산한 최소 이체 결과를 확인한 뒤, 수취 완료 확인까지 처리한다.

Flutter는 입력과 화면 상태만 담당하고, 계산과 원장 저장의 source of truth는 Spring Boot Main API다.

## 상태 모델

| 상태 | 설명 | 변경 가능 여부 | 채팅 노출 |
| --- | --- | --- | --- |
| `draft` | 약속 참여자들이 장소/항목/대상자를 편집하는 상태 | 가능 | `정산 입력 중` 배너 |
| `finalized` | 이체 방향과 금액이 확정된 상태 | 항목 편집 불가, transfer confirmation 가능 | 정산 공지 |
| `completed` | 수취자 전원이 수취 완료를 확인한 상태 | 불가 | 숨김 |

한 약속에는 활성 `draft` 또는 `finalized` 정산을 하나만 허용한다. `completed`는 결과 조회 대상이지만 채팅 상단 활성 공지에는 포함하지 않는다.

## 생성 가능 조건

정산 생성은 인증 사용자가 해당 모임 멤버이면서 해당 약속의 활성 참여자인 경우에만 가능하다.

약속 시간 조건:

- `startsAt`이 없으면 정산 생성 불가.
- `now < startsAt`이면 `settlement_plan_not_eligible`.
- `now >= startsAt`이면 진행중/지난 약속으로 보고 생성 가능.
- `endsAt`이 없으면 `startsAt`만 기준으로 판단한다.

## API Contract

| 기능 | API | 설명 |
| --- | --- | --- |
| draft 생성 또는 기존 active 정산 조회 | `POST /api/v1/groups/{groupId}/plans/{planId}/settlement-draft` | eligible plan에서 draft를 만든다. active draft가 있으면 기존 draft를, active finalized가 있으면 기존 finalized 정산을 반환한다 |
| active draft 조회 | `GET /api/v1/groups/{groupId}/plans/{planId}/settlement-draft` | active draft가 없으면 `404 settlement_draft_not_found` |
| draft 전체 저장 | `PATCH /api/v1/groups/{groupId}/plans/{planId}/settlement-draft` | section/item/target 전체를 저장한다. 저장 요청 단위 pessimistic lock 적용 |
| item 대상자 저장 | `PATCH /api/v1/groups/{groupId}/plans/{planId}/settlement-draft/items/{itemId}/targets` | 저장된 draft item의 대상자를 교체한다 |
| preview 계산 | `POST /api/v1/groups/{groupId}/plans/{planId}/settlements/preview` | 저장된 draft 기준 계산. DB write 없음 |
| 정산 확정 | `POST /api/v1/groups/{groupId}/plans/{planId}/settlements` | draft를 finalized settlement로 확정 |
| 현재 정산 조회 | `GET /api/v1/groups/{groupId}/plans/{planId}/settlements/current` | active draft 또는 active finalized 조회. completed만 남은 경우 `404 settlement_not_found` |
| 결과 상세 | `GET /api/v1/groups/{groupId}/plans/{planId}/settlements/{settlementId}` | 특정 settlement 결과 조회 |
| 정산 근거 | `GET /api/v1/groups/{groupId}/plans/{planId}/settlements/{settlementId}/basis` | section별 부담 계산과 transfer 근거 조회 |
| 송금 완료 | `POST /api/v1/groups/{groupId}/plans/{planId}/settlements/{settlementId}/transfers/{transferId}/sent` | 송금자만 호출 가능 |
| 수취 완료 | `POST /api/v1/groups/{groupId}/plans/{planId}/settlements/{settlementId}/transfers/{transferId}/received` | 수취자만 호출 가능 |

### Draft 저장 요청

```json
{
  "sections": [
    {
      "id": "section-extra",
      "schedulePlaceId": "place-101",
      "title": "퍼스트커피랩행궁",
      "payerUserId": "b7f2c0e0-2b7a-4d58-9d5f-1c9965f2f2a1",
      "items": [
        {
          "id": "item-401",
          "title": "커피",
          "amountWon": 12000,
          "splitType": "menu",
          "targetUserIds": [
            "b7f2c0e0-2b7a-4d58-9d5f-1c9965f2f2a1",
            "7f3b1b60-2cf7-4dd3-a4d4-b56c6f4f2a7c"
          ],
          "targetShares": [
            {
              "userId": "b7f2c0e0-2b7a-4d58-9d5f-1c9965f2f2a1",
              "amountWon": 8000
            },
            {
              "userId": "7f3b1b60-2cf7-4dd3-a4d4-b56c6f4f2a7c",
              "amountWon": 4000
            }
          ]
        }
      ]
    }
  ],
  "memo": "선택 메모"
}
```

요청 규칙:

- 금액 필드는 `amountWon`만 사용한다.
- `payerUserId`, `targetUserIds`는 사용자 DB UUID를 사용한다.
- `publicId`/친구 코드는 외부 공유와 검색용 식별자이며 정산 입력 식별자로 사용하지 않는다.
- 이름 필드로 결제자나 대상자를 resolve하지 않는다.
- `splitType`은 `equal`, `menu`만 허용한다.
- `targetUserIds`가 비어 있으면 약속 활성 참여자 전체를 대상으로 본다.
- `targetShares`가 있으면 사람별 부담 금액 직접 입력으로 처리한다.
- `targetShares[].amountWon` 합계는 item `amountWon`과 정확히 같아야 한다.
- `targetShares`와 `targetUserIds`가 함께 오면 `targetShares`가 우선한다.
- `amountWon <= 0`이면 `invalid_settlement_amount`.
- 대상자가 없으면 `missing_settlement_targets`.
- 사람별 부담 금액이 0 이하이면 `invalid_settlement_target_amount`.
- 같은 대상자가 중복되면 `duplicate_settlement_target`.
- `targetShares` 합계가 item 금액과 다르면 `settlement_target_amount_mismatch`.

## DB Schema

| 테이블 | 역할 |
| --- | --- |
| `settlement_drafts` | 약속별 active draft envelope, status, version, finalized settlement link |
| `settlements` | finalized/completed result envelope |
| `settlement_sections` | 방문장소 또는 기타 비용 section, section-level payer |
| `settlement_items` | section 안의 결제 항목, `amount_won`, split type |
| `settlement_item_targets` | item별 부담 대상자와 `amount_won` |
| `settlement_transfers` | finalized 결과의 최소 이체 목록과 transfer status |
| `settlement_confirmations` | `sent`, `received` confirmation event |

정산 금액 물리 컬럼은 `amount_won`이다. API도 `amountWon`만 노출한다.

## Lock / Concurrency

Draft mutation과 finalize는 plan의 active draft를 pessimistic write lock으로 조회한 뒤 처리한다.

정책:

- draft는 약속 참여자 누구나 전체 편집 가능하다.
- 같은 draft에 대한 동시 저장은 서버 transaction에서 직렬화한다.
- 동일 부분이 동시에 수정되면 마지막으로 commit된 저장 결과가 남는다.
- Flutter는 `settlement_write_conflict` 또는 lock 관련 409를 받으면 최신 draft를 다시 조회하고 “다른 참여자의 변경을 반영했어요. 다시 확인해 주세요.”로 안내한다.

## 계산 정책

서버는 다음 순서로 계산한다.

1. 각 item의 결제자는 section의 `payerUserId`다.
2. `targetShares`가 있는 item은 지정된 사람별 부담 금액을 그대로 사용한다.
3. `menu` item은 `targetShares`가 없으면 지정 대상자에게 균등 배분한다.
4. `equal` item은 `targetShares`가 없으면 약속 활성 참여자 전체에게 균등 배분한다.
5. 균등 배분의 나머지 원 단위는 대상자의 `publicId` 오름차순으로 1원씩 배분한다.
6. 사용자별 `paidTotal`, `owedTotal`, `net = paidTotal - owedTotal`을 계산한다.
7. `net < 0`인 사용자를 debtor, `net > 0`인 사용자를 creditor로 나누고 public id 오름차순으로 greedy matching한다.
8. 생성된 transfer가 없으면 finalize 즉시 `completed`로 전환한다.

## Side Effect

| 시점 | side effect |
| --- | --- |
| draft 생성 | 채팅 보조 상태에서 `정산 입력 중` 배너로 노출 가능 |
| finalized | `chat_activity_events` 정산 카드, 사용자별 notification, `settlement.finalized`, `notification.requested` outbox 기록 |
| completed | `settlement.completed` outbox 기록, 채팅 상단 정산 영역 숨김 |

Push provider credential은 정산 도메인 범위가 아니다. 실제 provider delivery는 notification/push 문서의 secret boundary를 따른다.

## Flutter Boundary

Flutter 책임:

- 약속 상세에서 진행중/지난 약속에만 정산 CTA 노출.
- 채팅 상단 draft 배너와 finalized 공지 표시.
- `+ -> 정산 생성하기`에서 진행중/지난 약속 선택 후 정산 화면 이동.
- 장소 section, 항목, 대상자 입력 UI.
- preview/finalized/completed 화면 상태 전환.
- transfer confirmation 버튼과 확인 dialog.
- 정산 근거 화면 이동.

Flutter 금지:

- 로컬에서 최종 이체 결과를 source of truth로 확정하지 않는다.
- 이름으로 사용자 dedupe/resolve를 하지 않는다.
- request/response body, 메모, 메뉴명, 금액 상세를 Sentry에 보내지 않는다.

## Error Contract

| code | 의미 |
| --- | --- |
| `settlement_plan_not_eligible` | 시작 전 약속이라 정산 생성 불가 |
| `settlement_draft_not_found` | active draft 없음 |
| `settlement_already_finalized` | draft가 이미 finalized |
| `settlement_already_completed` | completed settlement 변경 시도 |
| `settlement_write_conflict` | draft 동시 저장 충돌 또는 lock 충돌 |
| `invalid_settlement_amount` | 금액이 0 이하 |
| `missing_settlement_targets` | 부담 대상자 없음 |
| `settlement_participant_not_found` | 요청 사용자 또는 대상자가 약속 활성 참여자가 아님 |
| `invalid_settlement_target_amount` | 사람별 부담 금액이 0 이하 |
| `duplicate_settlement_target` | 같은 부담 대상자가 중복됨 |
| `settlement_target_amount_mismatch` | 사람별 부담 금액 합계가 item 금액과 다름 |
| `settlement_transfer_not_found` | transfer 없음 |
| `settlement_confirmation_forbidden` | transfer 송금자/수취자가 아닌 사용자의 확인 시도 |

Sentry 정책은 `frontend-architecture.md`의 오류 처리와 관측성 규칙을 따른다. 400/409 계열은 사용자 안내 중심으로 처리하고, 5xx/contract mismatch/unknown은 보고한다.

## Smoke 기준

1. 진행중 또는 지난 약속에서 draft를 생성한다.
2. 방문장소 section과 기타 비용 section에 항목을 추가한다.
3. preview가 DB write 없이 계산되는지 확인한다.
4. finalize 후 채팅 상단 공지와 notification/outbox가 생성되는지 확인한다.
5. 송금자 `sent`, 수취자 `received` confirmation을 처리한다.
6. 모든 수취자가 확인하면 `completed`로 전환되고 채팅 상단 공지가 사라지는지 확인한다.
7. completed 이후 current 정산 조회는 `404 settlement_not_found`이고, 특정 결과는 settlement id로 다시 조회 가능한지 확인한다.
