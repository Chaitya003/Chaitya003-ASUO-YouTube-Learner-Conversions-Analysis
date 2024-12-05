with asuo_youtube_user_conversions_ga4 as (
SELECT distinct event_name,
    device.web_info.hostname hostname,
    device.web_info.browser,
    device.category,
    (SELECT value.string_value FROM unnest(event_params) WHERE key = 'page_location') as page_location,
    EXTRACT(datetime FROM TIMESTAMP_MICROS(event_timestamp) at time zone 'America/Phoenix') AS event_datetime,
    user_pseudo_id,
    parse_date("%Y%m%d", event_date) as date,
    (SELECT value.string_value FROM unnest(event_params) WHERE key = 'edplus_sf_contact_id') as edplus_sf_contact_id,
    (SELECT value.string_value FROM unnest(event_params) WHERE key = 'sf_interaction_id') as sf_interaction_id,
    (SELECT value.string_value FROM unnest(event_params) WHERE key = 'section') as section,
    (SELECT value.string_value FROM unnest(event_params) WHERE key = 'action') as action,
    (SELECT value.string_value FROM unnest(event_params) WHERE key = 'event') as event,
    (SELECT value.string_value FROM unnest(event_params) WHERE key = 'type') as type,
    (SELECT value.string_value FROM unnest(event_params) WHERE key = 'text') as text,
    (SELECT value.string_value FROM unnest(event_params) WHERE key = 'career') as career, 
    (SELECT value.string_value FROM unnest(event_params) WHERE key = 'program_name') as program_name, -- degree_name
    (SELECT value.string_value FROM unnest(event_params) WHERE key = 'program_code') as program_code, -- program_code+plan_code
    (SELECT value.int_value FROM unnest(event_params) WHERE key = 'ga_session_id') as ga_session_id,
    traffic_source.source,
    traffic_source.medium,
    geo.country,
    geo.region,
    geo.city,
    geo.metro,
    case when event_name = 'sf_asuo_rfisubmit' then 'RFI'
      when event_name = 'sf_asuo_funnel' then 'App Start' 
     end as eventAction,
    case when event_name = 'sf_asuo_rfisubmit' then "RFI" 
        when event_name = 'sf_asuo_funnel'
          AND device.web_info.hostname = 'edpl.us' then "Legacy"
        when event_name = 'sf_asuo_funnel'
          AND device.web_info.hostname = 'api.adms-aaa.apps.asu.edu' then "New American"
        when event_name = 'sf_asuo_funnel'
          AND device.web_info.hostname = 'api-qa.adms-aaa.apps.asu.edu' then "New American - QA"
        when event_name = 'sf_asuo_funnel' then "Unknown"
      end as application_portal,
  FROM `events_20*`
  WHERE _TABLE_SUFFIX BETWEEN '231101'AND '231130' -- select FORMAT_DATE('%y%m%d', DATE_SUB(CURRENT_DATE('America/Phoenix'), INTERVAL 1 DAY))
  AND user_pseudo_id in (SELECT DISTINCT user_pseudo_id from `ASUO_Youtube.Youtube_Web_Behavior` where autoplay_ind=0)
  AND (
          (event_name = 'sf_asuo_rfisubmit'
          OR event_name = 'sf_asuo_funnel')
        )
),
interactions_numbered as
(
  SELECT DISTINCT * , 
        ROW_NUMBER() OVER (PARTITION BY sf_interaction_id
        ORDER BY event_datetime) as row_number
  FROM asuo_youtube_user_conversions_ga4
  WHERE sf_interaction_id IS NOT NULL
)
,
interactions_cleaned as
(
  SELECT DISTINCT * EXCEPT(row_number)
  FROM interactions_numbered
  WHERE row_number = 1
)
SELECT DISTINCT *
FROM interactions_cleaned
