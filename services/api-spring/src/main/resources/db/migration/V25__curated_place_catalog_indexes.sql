-- Curated place catalog provider lookup indexes.
-- Public/static catalog rows are imported out-of-band; Flyway only owns the schema/index support here.

create index if not exists idx_external_places_provider_category
  on external_places(provider, category);

create index if not exists idx_external_places_provider_lat_lng
  on external_places(provider, latitude, longitude)
  where latitude is not null and longitude is not null;

create index if not exists idx_external_places_provider_payload_gin
  on external_places using gin(provider_payload);
