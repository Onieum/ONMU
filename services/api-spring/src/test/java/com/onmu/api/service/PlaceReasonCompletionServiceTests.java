package com.onmu.api.service;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.Mockito.when;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.onmu.api.domain.GroupEntity;
import com.onmu.api.domain.PlaceCandidateEntity;
import com.onmu.api.domain.PlaceCandidateRepository;
import com.onmu.api.domain.PlanEntity;
import com.onmu.api.web.dto.PlaceReasonCallbackRequest;
import java.time.Instant;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.http.HttpStatus;
import org.springframework.web.server.ResponseStatusException;

@ExtendWith(MockitoExtension.class)
class PlaceReasonCompletionServiceTests {
  @Mock
  private PlaceCandidateRepository placeCandidateRepository;

  private ObjectMapper objectMapper;
  private PlaceReasonCompletionService service;
  private GroupEntity group;
  private PlanEntity plan;

  @BeforeEach
  void setUp() {
    objectMapper = new ObjectMapper();
    service = new PlaceReasonCompletionService(placeCandidateRepository, objectMapper);
    group = new GroupEntity("1", "ONMU 개발 모임", null);
    plan = new PlanEntity("101", group, "지도 UX 검증", Instant.parse("2026-06-22T00:00:00Z"), "scheduled");
  }

  @Test
  void completedCallbackUpdatesSafeSummaryReasonsAndRecommendationMetadata() throws Exception {
    PlaceCandidateEntity candidate = new PlaceCandidateEntity(
      "201",
      group,
      plan,
      "온무식당",
      "한식",
      "서울",
      "{\"summary\":\"기존 설명\",\"reasons\":[\"기존 이유\"],\"recommendation\":{\"aiStatus\":\"queued\"}}"
    );
    when(placeCandidateRepository.findByPublicId("201")).thenReturn(Optional.of(candidate));

    Map<String, Object> result = service.completeFromWorker(new PlaceReasonCallbackRequest(
      "1",
      "101",
      "201",
      "completed",
      "여럿이 식사 후보로 비교하기 쉬운 장소예요.",
      List.of("현재 후보들과 동선 비교가 쉬워요.", "지도 기준 접근성이 안정적이에요."),
      Map.of("reasonSource", "azure_openai", "modelConfigured", true),
      "job-1",
      "prompt-1",
      null
    ));

    Map<String, Object> payload = objectMapper.readValue(candidate.getPayload(), Map.class);
    assertThat(result)
      .containsEntry("candidateId", "201")
      .containsEntry("aiStatus", "completed")
      .containsEntry("reasonCount", 2);
    assertThat(payload)
      .containsEntry("summary", "여럿이 식사 후보로 비교하기 쉬운 장소예요.");
    assertThat(payload.get("reasons")).asList()
      .containsExactly("현재 후보들과 동선 비교가 쉬워요.", "지도 기준 접근성이 안정적이에요.");
    assertThat(payload.get("recommendation"))
      .isInstanceOfSatisfying(Map.class, recommendation ->
        assertThat(recommendation)
          .containsEntry("version", "ai-place-v1")
          .containsEntry("aiStatus", "completed")
          .containsEntry("reasonSource", "azure_openai")
          .containsEntry("jobRunId", "job-1")
          .containsEntry("promptRunId", "prompt-1")
      );
  }

  @Test
  void failedCallbackKeepsExistingReasonsAndStoresFailureMetadata() throws Exception {
    PlaceCandidateEntity candidate = new PlaceCandidateEntity(
      "201",
      group,
      plan,
      "온무식당",
      "한식",
      "서울",
      "{\"reasons\":[\"기존 이유\"]}"
    );
    when(placeCandidateRepository.findByPublicId("201")).thenReturn(Optional.of(candidate));

    service.completeFromWorker(new PlaceReasonCallbackRequest(
      "1",
      "101",
      "201",
      "failed",
      null,
      List.of("provider 내부 진단은 노출하지 않음"),
      Map.of("reasonSource", "azure_openai"),
      "job-1",
      "prompt-1",
      "AZURE_OPENAI_PLACE_REASON_FAILED"
    ));

    Map<String, Object> payload = objectMapper.readValue(candidate.getPayload(), Map.class);
    assertThat(payload.get("reasons")).asList().containsExactly("기존 이유");
    assertThat(payload.get("recommendation"))
      .isInstanceOfSatisfying(Map.class, recommendation ->
        assertThat(recommendation)
          .containsEntry("aiStatus", "failed")
          .containsEntry("errorCode", "AZURE_OPENAI_PLACE_REASON_FAILED")
      );
  }

  @Test
  void callbackRejectsCandidateOutsideReportedPlanScope() {
    PlaceCandidateEntity candidate = new PlaceCandidateEntity(
      "201",
      group,
      plan,
      "온무식당",
      "한식",
      "서울",
      "{}"
    );
    when(placeCandidateRepository.findByPublicId("201")).thenReturn(Optional.of(candidate));

    assertThatThrownBy(() -> service.completeFromWorker(new PlaceReasonCallbackRequest(
      "1",
      "999",
      "201",
      "completed",
      "요약",
      List.of("이유"),
      Map.of(),
      null,
      null,
      null
    )))
      .isInstanceOfSatisfying(ResponseStatusException.class, exception ->
        assertThat(exception.getStatusCode()).isEqualTo(HttpStatus.NOT_FOUND)
      );
  }
}
