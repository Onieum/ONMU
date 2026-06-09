package com.onmu.api.service;

import static org.assertj.core.api.Assertions.assertThat;

import org.junit.jupiter.api.Test;

class PlaceSearchServiceTests {
  @Test
  void searchReturnsNeutralDevCandidates() {
    PlaceSearchService service = new PlaceSearchService();

    var results = service.search("카페", "1", "101");

    assertThat(results).hasSize(3);
    assertThat(results.get(0))
      .containsEntry("category", "cafe")
      .containsEntry("canAddCandidate", true);
    assertThat(results.get(0)).doesNotContainKeys("sco" + "re", "risk" + "Label", "risk" + "Tone");
  }
}
