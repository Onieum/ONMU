package com.onmu.api.domain;

import static org.assertj.core.api.Assertions.assertThat;

import org.junit.jupiter.api.Test;

class SettlementDraftEntityTests {
  @Test
  void lifecycleSetsUpdatedAtBeforePersistAndUpdate() {
    GroupEntity group = new GroupEntity("1", "정산 테스트 모임", null);
    PlanEntity plan = new PlanEntity("101", group, "정산 테스트 약속", null, "completed");
    SettlementDraftEntity draft = new SettlementDraftEntity("301", group, plan, "{}");

    draft.touchUpdatedAt();
    assertThat(draft.getUpdatedAt()).isNotNull();

    var persistedUpdatedAt = draft.getUpdatedAt();
    draft.setPayload("{\"memo\":\"updated\"}");
    draft.touchUpdatedAt();

    assertThat(draft.getUpdatedAt()).isNotNull();
    assertThat(draft.getUpdatedAt()).isAfterOrEqualTo(persistedUpdatedAt);
  }
}
