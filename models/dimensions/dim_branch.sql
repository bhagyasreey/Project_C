{{ config(
    materialized = 'table',
    tags = ['dimension', 'branch']
) }}

with branches as (

    select
        branch_id,
        branch_name,
        city,
        state,
        branch_type,
        opened_date,
        region,
        updated_at

    from {{ ref('stg_branches') }}

)

select
    branch_id as branch_key,
    branch_id,
    branch_name,
    city,
    state,
    branch_type,
    opened_date,
    region,

    date_diff(current_date(), opened_date, year)
        as branch_age_years,

    case
        when opened_date <= current_date() then true
        else false
    end as is_opened,

    updated_at,
    current_timestamp() as dbt_loaded_at

from branches
