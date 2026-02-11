with source as (
    select * from {{ source('google_analytics', 'sessions') }}
),
renamed as (
    select
        session_id,
        user_id,
        session_date,
        page_views,
        session_duration_seconds,
        source as traffic_source,
        medium as traffic_medium,
        campaign as campaign_name,
        _loaded_at as loaded_at_timestamp
    from source
)
select * from renamed