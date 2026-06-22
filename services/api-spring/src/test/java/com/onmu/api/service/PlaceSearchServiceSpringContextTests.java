package com.onmu.api.service;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.Mockito.mock;

import com.onmu.api.place.DevMockPlaceSearchProvider;
import com.onmu.api.place.PlaceSearchCache;
import org.junit.jupiter.api.Test;
import org.springframework.boot.test.context.runner.ApplicationContextRunner;

class PlaceSearchServiceSpringContextTests {
  private final ApplicationContextRunner contextRunner = new ApplicationContextRunner()
    .withBean(DevMockPlaceSearchProvider.class)
    .withBean(PlaceSearchCache.class, () -> mock(PlaceSearchCache.class))
    .withBean(PlaceSearchService.class);

  @Test
  void createsSpringBeanWithRuntimeConstructor() {
    contextRunner.run(context -> assertThat(context).hasSingleBean(PlaceSearchService.class));
  }
}
