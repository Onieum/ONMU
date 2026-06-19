-- PostGIS 기반 catalog map 조회 지원.
-- 정적 catalog row는 계속 별도 import가 담당하며, Flyway는 extension/schema/index 지원만 소유한다.
-- staging PostgreSQL Flexible Server에서 Flyway 앱 계정이 postgis extension을 만들 수 있는지는
-- 이 migration만으로 확정하지 않는다. 배포 전 preflight에서 allowlist/권한을 확인해야 한다.

create extension if not exists postgis;

alter table external_places
  add column if not exists place_point geometry(Point, 4326)
  generated always as (
    case
      when latitude is not null
        and longitude is not null
        and latitude between -90 and 90
        and longitude between -180 and 180
      then ST_SetSRID(ST_MakePoint(longitude::double precision, latitude::double precision), 4326)
      else null
    end
  ) stored;

alter table external_places
  add column if not exists place_geog geography(Point, 4326)
  generated always as (
    case
      when latitude is not null
        and longitude is not null
        and latitude between -90 and 90
        and longitude between -180 and 180
      then ST_SetSRID(ST_MakePoint(longitude::double precision, latitude::double precision), 4326)::geography
      else null
    end
  ) stored;

create index if not exists idx_external_places_place_point_gist
  on external_places using gist(place_point)
  where place_point is not null;

create index if not exists idx_external_places_place_geog_gist
  on external_places using gist(place_geog)
  where place_geog is not null;

create index if not exists idx_external_places_catalog_point_category
  on external_places(provider, category)
  where provider = 'ONMU_CATALOG' and place_point is not null;
