WITH youtube_list_farthest_event AS 
( 
  SELECT DISTINCT * EXCEPT(rn)
  FROM (
        SELECT *
          , ROW_NUMBER() OVER(PARTITION BY user_pseudo_id, video_title ORDER BY watched_step DESC, event_datetime ASC) AS rn
        FROM `ASUO_Youtube.Youtube_Web_Behavior`)
        WHERE rn = 1 
          and autoplay_ind = 0 
          -- and youtube_list_ind =1
)
,

unique_visitor_contact_id AS 
(
  SELECT DISTINCT edplus_sf_contact_id
    , user_pseudo_id
  FROM `ASUO_Youtube.Youtube_SF_Interactions`
  WHERE edplus_sf_contact_id IS NOT NULL
)
--SELECT count(DISTINCT user_pseudo_id) FROM unique_visitor_contact_id
,
  
youtube_video_with_contact_id AS
(
  SELECT
    c.edplus_sf_contact_id,
    y.*
  FROM youtube_list_farthest_event y
    INNER JOIN unique_visitor_contact_id c
      ON y.user_pseudo_id = c.user_pseudo_id

)
,

youtube_video_interaction AS
(
  SELECT DISTINCT
    l1.interaction_id,
    l1.contact_id,
    l2.edplus_sf_contact_id as joined_contact,
    l1.fullVisitorID as event_fullVisitorID,
    l1.clientID as event_clientID,
    l1.date as event_date,
    l1.sessionID as event_sessionID,
    l1.visitID as event_visitID,
    l1.event_datetime,
    l1.eventAction,
    l1.hitNumber as event_hitNumber,
    l1.program_level as event_program_level,
    l1.degree_name as event_degree_name,
    l1.program_code as event_program_code,
    l1.plan_code as event_plan_code,
    l1.source_medium as event_source_medium,
    l1.pagePath as event_pagePath,
    l1.browser as event_browser,
    l1.deviceCategory as event_deviceCategory,
    l1.country as event_country,
    l1.region as event_region,
    l1.metro as event_metro,
    l1.city as event_city,
    l2.date AS youtube_date,
    l2.user_pseudo_id as youtube_client_id,
    l2.ga_session_id AS youtube_session_id,
    l2.event_datetime AS youtube_event_datetime,
    l2.video_title,
    l2.video_url,
    l2.video_action,
    l2.autoplay_ind,
    l2.video_autoplay,
    l2.source AS youtube_source,
    l2.medium AS youtube_medium,
    l2.hostname as youtube_hostname,
    l2.page_location as youtube_page_location,
    l2.browser as youtube_browser,
    l2.category as youtube_deviceCategory,
    l2.country as youtube_country,
    l2.region as youtube_region,
    l2.metro as youtube_metro,
    l2.city as youtube_city,
    l2.watched_step,
    l2.youtube_list_ind
  FROM `ASUO_Youtube.2_ASUO_Youtube_SF_Interactions` l1
    LEFT JOIN youtube_video_with_contact_id l2
      ON l1.contact_id = l2.edplus_sf_contact_id
  WHERE l1.event_datetime >= l2.event_datetime
)
,
numbered_video AS
(
  SELECT DISTINCT *
    , ROW_NUMBER() OVER(PARTITION BY interaction_id ORDER BY youtube_event_datetime ASC) AS first_video_rn
    ,COUNT(*) OVER(PARTITION BY interaction_id) AS count_video
  FROM youtube_video_interaction --youtube_video_interaction_filtered
) 
,

video_category AS
(
  SELECT
    * --EXCEPT(first_video_rn, count_video)
    , CASE
        WHEN count_video=1 THEN ' Last Video'
        WHEN first_video_rn=1 THEN 'First Video'
        WHEN first_video_rn=count_video THEN ' Last Video'
        ELSE '  Assisted'
      END AS video_category
  FROM numbered_video
)
,first_video_dimension AS
(
select  
    interaction_id as first_interaction_id,
    youtube_date AS first_youtube_date,
    youtube_session_id AS first_youtube_session_id,
    youtube_event_datetime AS first_youtube_event_datetime,
    video_title AS first_video_title,
    video_url AS first_youtube_link,
    video_action as first_youtube_video_action,
    youtube_source AS first_youtube_source,
    youtube_medium as first_youtube_medium,
    youtube_hostname as first_youtube_hostname,
    youtube_page_location as first_youtube_page_location,
    youtube_browser as first_youtube_browser,
    youtube_deviceCategory as first_youtube_deviceCategory,
    youtube_country as first_youtube_country,
    youtube_region as first_youtube_region,
    youtube_metro as first_youtube_metro,
    youtube_city as first_youtube_city
  FROM video_category
  WHERE first_video_rn = 1

)

,last_video_dimension AS
(
SELECT  
    interaction_id as last_interaction_id,
    youtube_date AS last_youtube_date,
    youtube_session_id AS last_youtube_session_id,
    youtube_event_datetime AS last_youtube_event_datetime,
    video_title AS last_video_title,
    video_url AS last_youtube_link,
    video_action AS last_youtube_eventAction,
    youtube_source AS last_youtube_source,
    youtube_medium as last_youtube_medium,
    youtube_hostname as last_youtube_hostname,
    youtube_page_location as last_youtube_page_location,
    youtube_browser as last_youtube_browser,
    youtube_deviceCategory as last_youtube_deviceCategory,
    youtube_country as last_youtube_country,
    youtube_region as last_youtube_region,
    youtube_metro as last_youtube_metro,
    youtube_city as last_youtube_city
  FROM video_category
  WHERE first_video_rn = count_video

)
,

all_dimensions_integrated AS
(
  SELECT l1.*
    , l2.* except(first_interaction_id)
    , l3.* except(last_interaction_id)
  FROM video_category l1
    LEFT JOIN first_video_dimension l2
      ON l1.interaction_id = l2.first_interaction_id 
    LEFT JOIN last_video_dimension l3
      ON l1.interaction_id = l3.last_interaction_id
)

SELECT DISTINCT *
FROM all_dimensions_integrated
