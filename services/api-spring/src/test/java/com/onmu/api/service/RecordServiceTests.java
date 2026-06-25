package com.onmu.api.service;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.argThat;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.onmu.api.domain.GroupEntity;
import com.onmu.api.domain.GroupRepository;
import com.onmu.api.domain.OotdFeatureEntity;
import com.onmu.api.domain.OotdFeatureRepository;
import com.onmu.api.domain.PlanEntity;
import com.onmu.api.domain.PlanParticipantEntity;
import com.onmu.api.domain.PlanParticipantRepository;
import com.onmu.api.domain.PlanRepository;
import com.onmu.api.domain.RecordEntity;
import com.onmu.api.domain.RecordMediaEntity;
import com.onmu.api.domain.RecordMediaRepository;
import com.onmu.api.domain.RecordRepository;
import com.onmu.api.domain.RecordTagEntity;
import com.onmu.api.domain.RecordTagRepository;
import com.onmu.api.domain.UserEntity;
import com.onmu.api.domain.UserRepository;
import com.onmu.api.domain.CharacterProfileEntity;
import com.onmu.api.domain.CharacterProfileRepository;
import com.onmu.api.web.dto.CreateMemoryRequest;
import com.onmu.api.web.dto.CreateRecordRequest;
import com.onmu.api.web.dto.MemoryResponse;
import com.onmu.api.web.dto.OotdCallbackRequest;
import com.onmu.api.web.dto.RecordMediaInput;
import java.time.Instant;
import java.util.Collections;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

@ExtendWith(MockitoExtension.class)
class RecordServiceTests {
  @Mock
  private RecordRepository recordRepository;
  @Mock
  private RecordMediaRepository recordMediaRepository;
  @Mock
  private RecordTagRepository recordTagRepository;
  @Mock
  private OotdFeatureRepository ootdFeatureRepository;
  @Mock
  private GroupRepository groupRepository;
  @Mock
  private PlanRepository planRepository;
  @Mock
  private PlanParticipantRepository planParticipantRepository;
  @Mock
  private UserRepository userRepository;
  @Mock
  private OutboxService outboxService;
  @Mock
  private CharacterProfileRepository characterProfileRepository;

  private RecordService service;
  private GroupEntity group;
  private PlanEntity plan;
  private UserEntity user;

  @BeforeEach
  void setUp() {
    service = new RecordService(
      recordRepository,
      recordMediaRepository,
      recordTagRepository,
      ootdFeatureRepository,
      groupRepository,
      planRepository,
      planParticipantRepository,
      userRepository,
      outboxService,
      new ObjectMapper(),
      characterProfileRepository
    );
    user = org.mockito.Mockito.mock(UserEntity.class);
    org.mockito.Mockito.lenient().when(user.getId()).thenReturn(java.util.UUID.fromString("11111111-1111-1111-1111-111111111111"));
    org.mockito.Mockito.lenient().when(userRepository.findByIdAndDeletedAtIsNull(user.getId())).thenReturn(Optional.of(user));
    group = new GroupEntity("1", "ONMU 개발 모임", user);
    plan = new PlanEntity("101", group, "ONMU API 계약 검증", Instant.parse("2026-06-12T01:00:00Z"), "scheduled");
  }

  @Test
  void creatingRecordRecordsOutboxEvent() {
    when(groupRepository.findByPublicId("1")).thenReturn(Optional.of(group));
    when(planRepository.findByGroupAndPublicId(group, "101")).thenReturn(Optional.of(plan));
    when(userRepository.checkPrivacyConsent(any())).thenReturn(true);
    when(groupRepository.isUserMember(eq("1"), any())).thenReturn(true);
    when(planRepository.isUserParticipant(eq("101"), any())).thenReturn(true);
    when(recordRepository.save(any(RecordEntity.class))).thenAnswer(invocation -> invocation.getArgument(0));

    var created = service.createRecord(user.getId(), "1", "101", new CreateRecordRequest(
      "오늘의 OOTD",
      "여름 휴가 룩",
      "participants",
      "OOTD",
      "오늘 입은 코디입니다.",
      "2026-06-09T14:00:00Z",
      List.of("여름", "바다"),
      List.of(new RecordMediaInput("IMAGE", "storage-key-1", "http://image-url", 800, 800, null, 0))
    ));

    assertThat(created).containsKey("id");
    assertThat(created.get("title")).isEqualTo("오늘의 OOTD");
    assertThat(created.get("body")).isEqualTo("오늘 입은 코디입니다.");
    assertThat(created.get("recordType")).isEqualTo("OOTD");
    assertThat(created.get("recordedAt")).isEqualTo("2026-06-09T14:00:00Z");
    assertThat(created.get("aiStatus")).isEqualTo("PENDING");

    verify(outboxService).record(
      eq("record.created"),
      eq("record"),
      any(),
      argThat(payload -> "1".equals(payload.get("groupId"))
        && "101".equals(payload.get("planId"))
        && payload.containsKey("recordId"))
    );
  }

  @Test
  void creatingRecordWithoutConsentSkipsOutboxEvent() {
    when(groupRepository.findByPublicId("1")).thenReturn(Optional.of(group));
    when(planRepository.findByGroupAndPublicId(group, "101")).thenReturn(Optional.of(plan));
    when(userRepository.checkPrivacyConsent(any())).thenReturn(false);
    when(groupRepository.isUserMember(eq("1"), any())).thenReturn(true);
    when(planRepository.isUserParticipant(eq("101"), any())).thenReturn(true);
    when(recordRepository.save(any(RecordEntity.class))).thenAnswer(invocation -> invocation.getArgument(0));

    var created = service.createRecord(user.getId(), "1", "101", new CreateRecordRequest(
      "오늘의 OOTD",
      "여름 휴가 룩",
      "participants",
      "OOTD",
      "오늘 입은 코디입니다.",
      "2026-06-09T14:00:00Z",
      List.of("여름", "바다"),
      List.of(new RecordMediaInput("IMAGE", "storage-key-1", "http://image-url", 800, 800, null, 0))
    ));

    assertThat(created).containsKey("id");
    assertThat(created.get("aiStatus")).isEqualTo("SKIPPED");

    org.mockito.Mockito.verifyNoInteractions(outboxService);
  }

  @Test
  void processingCallbackSavesOotdFeatures() {
    RecordEntity record = new RecordEntity(
      "rec_123",
      group,
      plan,
      user,
      "오늘의 OOTD",
      "participants",
      "{}",
      "[]"
    );
    when(recordRepository.findByPublicIdAndDeletedAtIsNull("rec_123")).thenReturn(Optional.of(record));
    when(ootdFeatureRepository.save(any(OotdFeatureEntity.class))).thenAnswer(invocation -> invocation.getArgument(0));
    when(userRepository.checkPrivacyConsent(any())).thenReturn(true);

    Map<String, Object> features = Map.of("color", "blue", "style", "casual");
    var updated = service.processOotdCallback(new OotdCallbackRequest(
      "rec_123",
      features,
      List.of("청바지", "티셔츠"),
      "http://new-image-url",
      null,
      "SUCCESS",
      null
    ));

    assertThat(updated).isNotNull();
    assertThat(updated.get("aiStatus")).isEqualTo("SUCCESS");
    verify(ootdFeatureRepository).save(argThat(entity -> "AI".equals(entity.getFeatureSource())));
    verify(recordTagRepository).save(argThat(tag -> "AI".equals(tag.getTagType()) && "청바지".equals(tag.getTagValue())));
  }

  @Test
  void processingCallbackFailureUpdatesStatusToFailed() {
    RecordEntity record = new RecordEntity(
      "rec_123",
      group,
      plan,
      user,
      "오늘의 OOTD",
      "participants",
      "{}",
      "[]"
    );
    when(recordRepository.findByPublicIdAndDeletedAtIsNull("rec_123")).thenReturn(Optional.of(record));
    when(ootdFeatureRepository.save(any(OotdFeatureEntity.class))).thenAnswer(invocation -> invocation.getArgument(0));
    when(userRepository.checkPrivacyConsent(any())).thenReturn(true);

    var updated = service.processOotdCallback(new OotdCallbackRequest(
      "rec_123",
      null,
      null,
      null,
      null,
      "FAILED",
      "AI extraction failed"
    ));

    assertThat(updated).isNotNull();
    assertThat(updated.get("aiStatus")).isEqualTo("FAILED");
    assertThat(updated.get("aiErrorReason")).isEqualTo("AI extraction failed");
    verify(ootdFeatureRepository).save(argThat(entity -> "AI_FAILED".equals(entity.getFeatureSource())));
  }

  @Test
  void creatingRecordWithoutGroupMembershipFails() {
    when(groupRepository.findByPublicId("1")).thenReturn(Optional.of(group));
    when(planRepository.findByGroupAndPublicId(group, "101")).thenReturn(Optional.of(plan));
    when(groupRepository.isUserMember(eq("1"), any())).thenReturn(false);

    org.junit.jupiter.api.Assertions.assertThrows(
      org.springframework.web.server.ResponseStatusException.class,
      () -> service.createRecord(user.getId(), "1", "101", new CreateRecordRequest(
        "오늘의 OOTD",
        "여름 휴가 룩",
        "participants",
        "OOTD",
        "오늘 입은 코디입니다.",
        "2026-06-09T14:00:00Z",
        List.of("여름", "바다"),
        List.of(new RecordMediaInput("IMAGE", "storage-key-1", "http://image-url", 800, 800, null, 0))
      ))
    );
  }

  @Test
  void creatingRecordWithoutPlanParticipationFails() {
    when(groupRepository.findByPublicId("1")).thenReturn(Optional.of(group));
    when(planRepository.findByGroupAndPublicId(group, "101")).thenReturn(Optional.of(plan));
    when(groupRepository.isUserMember(eq("1"), any())).thenReturn(true);
    when(planRepository.isUserParticipant(eq("101"), any())).thenReturn(false);

    org.junit.jupiter.api.Assertions.assertThrows(
      org.springframework.web.server.ResponseStatusException.class,
      () -> service.createRecord(user.getId(), "1", "101", new CreateRecordRequest(
        "오늘의 OOTD",
        "여름 휴가 룩",
        "participants",
        "OOTD",
        "오늘 입은 코디입니다.",
        "2026-06-09T14:00:00Z",
        List.of("여름", "바다"),
        List.of(new RecordMediaInput("IMAGE", "storage-key-1", "http://image-url", 800, 800, null, 0))
      ))
    );
  }

  @Test
  void getRecordDetailSuccessWhenPublicAndGroupMember() {
    RecordEntity record = new RecordEntity("rec_1", group, plan, user, "public title", "public", "{}", "[]");
    when(recordRepository.findByPublicIdAndDeletedAtIsNull("rec_1")).thenReturn(Optional.of(record));
    when(groupRepository.isUserMember("1", user.getId())).thenReturn(true);

    var detail = service.getRecordDetail(user.getId(), "rec_1");
    assertThat(detail).containsKey("id");
    assertThat(detail.get("title")).isEqualTo("public title");
  }

  @Test
  void getRecordDetailFailsWhenPrivateAndUserNotAuthor() {
    UserEntity otherUser = org.mockito.Mockito.mock(UserEntity.class);
    when(otherUser.getId()).thenReturn(java.util.UUID.fromString("22222222-2222-2222-2222-222222222222"));
    
    RecordEntity record = new RecordEntity("rec_1", group, plan, otherUser, "private title", "private", "{}", "[]");
    when(recordRepository.findByPublicIdAndDeletedAtIsNull("rec_1")).thenReturn(Optional.of(record));
    when(groupRepository.isUserMember("1", user.getId())).thenReturn(true);

    org.junit.jupiter.api.Assertions.assertThrows(
      org.springframework.web.server.ResponseStatusException.class,
      () -> service.getRecordDetail(user.getId(), "rec_1")
    );
  }

  @Test
  void getRecordDetailSuccessWhenPrivateAndUserIsAuthor() {
    RecordEntity record = new RecordEntity("rec_1", group, plan, user, "private title", "private", "{}", "[]");
    when(recordRepository.findByPublicIdAndDeletedAtIsNull("rec_1")).thenReturn(Optional.of(record));
    when(groupRepository.isUserMember("1", user.getId())).thenReturn(true);

    var detail = service.getRecordDetail(user.getId(), "rec_1");
    assertThat(detail.get("title")).isEqualTo("private title");
  }

  @Test
  void getRecordDetailFailsWhenParticipantsAndUserNotParticipant() {
    RecordEntity record = new RecordEntity("rec_1", group, plan, user, "participants title", "participants", "{}", "[]");
    when(recordRepository.findByPublicIdAndDeletedAtIsNull("rec_1")).thenReturn(Optional.of(record));
    when(groupRepository.isUserMember("1", user.getId())).thenReturn(true);
    when(planRepository.isUserParticipant("101", user.getId())).thenReturn(false);

    org.junit.jupiter.api.Assertions.assertThrows(
      org.springframework.web.server.ResponseStatusException.class,
      () -> service.getRecordDetail(user.getId(), "rec_1")
    );
  }

  @Test
  void getRecordDetailSuccessWhenParticipantsAndUserIsParticipant() {
    RecordEntity record = new RecordEntity("rec_1", group, plan, user, "participants title", "participants", "{}", "[]");
    when(recordRepository.findByPublicIdAndDeletedAtIsNull("rec_1")).thenReturn(Optional.of(record));
    when(groupRepository.isUserMember("1", user.getId())).thenReturn(true);
    when(planRepository.isUserParticipant("101", user.getId())).thenReturn(true);

    var detail = service.getRecordDetail(user.getId(), "rec_1");
    assertThat(detail.get("title")).isEqualTo("participants title");
  }

  @Test
  void creatingMemoryStoresCharacterSnapshotAndOutbox() {
    when(groupRepository.findByPublicId("1")).thenReturn(Optional.of(group));
    when(groupRepository.isUserMember("1", user.getId())).thenReturn(true);
    when(userRepository.checkPrivacyConsent(any())).thenReturn(true);

    CharacterProfileEntity profile = new CharacterProfileEntity(
      user.getId(), "female", "type_cool", "long_wave", "pink", "sharp", "blue", "skirt"
    );
    when(characterProfileRepository.findByUserId(user.getId())).thenReturn(Optional.of(profile));
    when(recordRepository.save(any(RecordEntity.class))).thenAnswer(invocation -> invocation.getArgument(0));

    CreateMemoryRequest request = new CreateMemoryRequest(
      "OOTD",
      "오늘의 스타일",
      "오늘의 무드 메모",
      "2026-06-10T12:00:00Z",
      List.of("데이트", "맑음"),
      List.of("http://test-image-url"),
      null,
      "PUBLIC",
      "short_hair",
      "blonde",
      "round",
      "green",
      Map.of()
    );

    MemoryResponse response = service.createMemory(user.getId(), "1", request);

    assertThat(response).isNotNull();
    assertThat(response.title()).isEqualTo("오늘의 스타일");
    assertThat(response.characterSnapshot()).isNotNull();

    Map<String, Object> snapshot = response.characterSnapshot();
    assertThat(snapshot.get("skin_tone")).isEqualTo("type_cool");
    assertThat(snapshot.get("hair_style")).isEqualTo("short_hair");
    assertThat(snapshot.get("hair_color")).isEqualTo("blonde");
    assertThat(snapshot.get("eye_style")).isEqualTo("round");
    assertThat(snapshot.get("eye_color")).isEqualTo("green");
    assertThat(snapshot.get("clothes")).isEqualTo("none");

    verify(outboxService).record(
      eq("record.created"),
      eq("record"),
      any(),
      argThat(payload -> {
        Map<String, Object> outboxSnapshot = (Map<String, Object>) payload.get("characterSnapshot");
        return outboxSnapshot != null 
          && "short_hair".equals(outboxSnapshot.get("hair_style"))
          && "none".equals(outboxSnapshot.get("clothes"));
      })
    );
  }

  @Test
  void crewOotdAppearancesIncludeProfileGenderFallback() {
    UserEntity crew = new UserEntity(
      java.util.UUID.fromString("22222222-2222-2222-2222-222222222222"),
      "crew"
    );
    CharacterProfileEntity crewProfile = new CharacterProfileEntity(
      crew.getId(),
      "male",
      "skin_2",
      "hair_style_1",
      "hair_color_0",
      "eye_style_0",
      "eye_color_0",
      "top_1"
    );

    when(groupRepository.findByPublicId("1")).thenReturn(Optional.of(group));
    when(groupRepository.isUserMember("1", user.getId())).thenReturn(true);
    when(planRepository.findByGroupAndPublicId(group, "101")).thenReturn(Optional.of(plan));
    when(planRepository.isUserParticipant("101", user.getId())).thenReturn(true);
    when(planParticipantRepository.findByPlanOrderByCreatedAtAsc(plan)).thenReturn(List.of(
      new PlanParticipantEntity(plan, user, "joined", "accepted"),
      new PlanParticipantEntity(plan, crew, "joined", "accepted")
    ));
    when(recordRepository.findByAuthorAndDeletedAtIsNullOrderByCreatedAtDesc(crew))
      .thenReturn(List.of());
    when(characterProfileRepository.findByUserId(crew.getId()))
      .thenReturn(Optional.of(crewProfile));

    var appearances = service.getCrewOotdAppearances(
      user.getId(),
      "1",
      "101",
      "2026-06-12"
    );

    assertThat(appearances).singleElement().satisfies(appearance ->
      assertThat(appearance.character())
        .containsEntry("gender", "male")
        .containsEntry("clothes", "top_1"));
  }

  @Test
  void getPersonalMemoriesReturnsSuccessfully() {
    RecordEntity record = new RecordEntity("rec_1", group, plan, user, "Personal Memory", "PUBLIC", "{}", "[]");
    when(recordRepository.findByAuthorAndDeletedAtIsNullOrderByCreatedAtDesc(user)).thenReturn(List.of(record));

    List<MemoryResponse> memories = service.getPersonalMemories(user.getId());
    assertThat(memories).hasSize(1);
    assertThat(memories.get(0).title()).isEqualTo("Personal Memory");
  }

  @Test
  void getGroupMemoriesReturnsSuccessfully() {
    when(groupRepository.findByPublicId("1")).thenReturn(Optional.of(group));
    when(groupRepository.isUserMember("1", user.getId())).thenReturn(true);
    RecordEntity record = new RecordEntity("rec_1", group, plan, user, "Group Memory", "PUBLIC", "{}", "[]");
    when(recordRepository.findByGroupAndDeletedAtIsNullOrderByCreatedAtDesc(group)).thenReturn(List.of(record));

    List<MemoryResponse> memories = service.getGroupMemories(user.getId(), "1");
    assertThat(memories).hasSize(1);
    assertThat(memories.get(0).title()).isEqualTo("Group Memory");
  }
}
