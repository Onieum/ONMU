-- SCRUM-41 seed record media MinIO public-read connection.
-- V9 seed rows stay immutable; this migration moves record media URLs to the Spring public media route.

with media_seed(record_public_id, storage_key, width, height) as (
  values
    ('memory-1001', 'dev/media/records/memory-1001/image-1.png', 1200, 900),
    ('memory-1002', 'dev/media/records/memory-1002/image-1.png', 1200, 900),
    ('memory-1004', 'dev/media/records/memory-1004/image-1.png', 1200, 900)
)
update record_media rm
set
  storage_key = media_seed.storage_key,
  public_url = '/api/v1/media/public?key=' || replace(media_seed.storage_key, '/', '%2F'),
  width = media_seed.width,
  height = media_seed.height,
  payload = jsonb_build_object(
    'seedMedia', true,
    'source', 'data/dev-media/record-media-manifest.json'
  )
from records r, media_seed
where rm.record_id = r.id
  and r.public_id = media_seed.record_public_id
  and rm.sort_order = 1;
