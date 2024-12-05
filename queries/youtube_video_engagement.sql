with asuo_youtube_data_ga4 as (
SELECT distinct event_name,
    device.web_info.hostname hostname,
    device.web_info.browser,
    device.category,
    (SELECT value.string_value FROM unnest(event_params) WHERE key = 'page_location') as page_location,
    EXTRACT(datetime FROM TIMESTAMP_MICROS(event_timestamp) at time zone 'America/Phoenix') AS event_datetime,
    -- user_id,
    (SELECT value.string_value FROM unnest(event_params) WHERE key = 'ga_session_id') as ga_session_id,
    -- session_start,
    user_pseudo_id,
    parse_date("%Y%m%d", event_date) as date,
    -- (SELECT value.string_value FROM unnest(event_params) WHERE key = 'region') as region,
    (SELECT value.string_value FROM unnest(event_params) WHERE key = 'section') as section, -- NULL
    (SELECT value.string_value FROM unnest(event_params) WHERE key = 'action') as action, -- NULL
    (SELECT value.string_value FROM unnest(event_params) WHERE key = 'event') as event, -- youtube
    (SELECT value.string_value FROM unnest(event_params) WHERE key = 'type') as type, -- NULL
    (SELECT value.string_value FROM unnest(event_params) WHERE key = 'text') as text, -- NULL
    traffic_source.source,
    traffic_source.medium,
    (SELECT value.string_value FROM unnest(event_params) WHERE key = 'video_action') as video_action,
    (SELECT value.string_value FROM unnest(event_params) WHERE key = 'video_autoplay') as video_autoplay,
    (SELECT value.string_value FROM unnest(event_params) WHERE key = 'video_title') as video_title,
    (SELECT value.string_value FROM unnest(event_params) WHERE key = 'video_url') as video_url,
    case when (SELECT value.string_value FROM unnest(event_params) WHERE key = 'video_autoplay')='autoplay' then 1 else 0 end as autoplay_ind,
  geo.country,
  geo.region,
  geo.city,
  geo.metro,
  FROM `events_20*`
  WHERE _TABLE_SUFFIX BETWEEN '231101'AND '231130' -- FORMAT_DATE('%y%m%d', DATE_SUB(CURRENT_DATE('America/Phoenix'), INTERVAL 1 DAY))
  AND (device.web_info.hostname = 'asuonline.asu.edu')
  AND event_name='youtube'
),
youtube_summary as
(
  SELECT *
          ,CASE
          WHEN lower(video_action) = "start playing" THEN 1
          WHEN lower(video_action) = "reached 10%" THEN 2
          WHEN lower(video_action) = "reached 25%" THEN 3
          WHEN lower(video_action) = "reached 50%" THEN 4
          WHEN lower(video_action) = "reached 75%" THEN 5
          WHEN lower(video_action) = "reached 90%" THEN 6
          WHEN lower(video_action) = "reached 100%" THEN 7
      ELSE 0
  END AS watched_step
  FROM asuo_youtube_data_ga4
  WHERE video_title IS NOT NULL
)
,
youtube_specific_video as
(
  SELECT DISTINCT a.*
    , case when a.video_title = b.video_title then 1 else 0 end as youtube_list_ind
  FROM youtube_summary as a
    LEFT JOIN `edplus-adsat-analytics.ASUO_Youtube.ASUO_Youtube_Title_Sheet` as b
      ON a.video_title = b.video_title
)
SELECT DISTINCT *
FROM youtube_specific_video
