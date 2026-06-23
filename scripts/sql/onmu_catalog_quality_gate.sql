\echo 'ONMU_CATALOG quality gate: row/count only. Do not paste DB URLs or row dumps into reports.'

select
  count(*) as catalog_row_count,
  count(*) filter (where latitude is not null and longitude is not null) as coordinate_row_count,
  count(*) filter (where place_point is not null) as map_visible_point_count,
  count(*) filter (where provider_payload ? 'importBatchId') as import_batch_id_count
from external_places
where provider = 'ONMU_CATALOG';

select
  count(*) as invalid_coordinate_count
from external_places
where provider = 'ONMU_CATALOG'
  and (
    latitude is null
    or longitude is null
    or latitude not between 33 and 39
    or longitude not between 124 and 132
  );

select
  count(*) as duplicate_provider_place_id_count
from (
  select provider_place_id
  from external_places
  where provider = 'ONMU_CATALOG'
  group by provider_place_id
  having count(*) > 1
) duplicates;

select
  category,
  count(*) as row_count,
  count(*) filter (where latitude is not null and longitude is not null) as coordinate_row_count
from external_places
where provider = 'ONMU_CATALOG'
group by category
order by row_count desc, category asc;

select
  count(*) filter (
    where nullif(homepage_url, '') is not null
  ) as homepage_url_count,
  count(*) filter (
    where provider_payload ? 'imageUrl'
      or provider_payload ? 'imageUrls'
      or provider_payload ? 'image_url'
      or provider_payload ? 'firstimage'
      or provider_payload ? 'firstImage'
  ) as image_reference_count
from external_places
where provider = 'ONMU_CATALOG';

with catalog as (
  select
    category,
    lower(concat_ws(
      ' ',
      name,
      category,
      address,
      road_address,
      provider_payload::text
    )) as text_value
  from external_places
  where provider = 'ONMU_CATALOG'
    and latitude is not null
    and longitude is not null
)
select
  '서울 가볼만한곳' as smoke_case,
  count(*) filter (
    where text_value like '%서울%'
      and (
        category in ('관광명소', '문화공간', '행사')
        or text_value like '%공원%'
        or text_value like '%박물관%'
        or text_value like '%미술관%'
        or text_value like '%전시%'
        or text_value like '%전망대%'
        or text_value like '%산책로%'
      )
  ) as candidate_count
from catalog
union all
select
  '강남 맛집' as smoke_case,
  count(*) filter (
    where text_value like '%강남%'
      and (
        category = '식당'
        or text_value like '%음식%'
        or text_value like '%식당%'
        or text_value like '%맛집%'
        or text_value like '%한식%'
        or text_value like '%양식%'
        or text_value like '%중식%'
        or text_value like '%일식%'
      )
  ) as candidate_count
from catalog
union all
select
  '을지로 카페' as smoke_case,
  count(*) filter (
    where text_value like '%을지로%'
      and (
        text_value like '%카페%'
        or text_value like '%커피%'
        or text_value like '%디저트%'
        or text_value like '%베이커리%'
        or text_value like '%브런치%'
      )
  ) as candidate_count
from catalog;
