{{ config(
    materialized = 'view',
    tags = ['staging', 'branches']
) }}

with source_data as (

    select *
    from {{ source('banksphere_raw', 'branches') }}

),

standardized as (

    select
        nullif(trim(branch_id), '') as branch_id,
        nullif(trim(branch_name), '') as branch_name,

        initcap(nullif(trim(city), '')) as city,
        upper(nullif(trim(state), '')) as state,
        upper(nullif(trim(branch_type), '')) as branch_type,
        cast(opened_date as date) as opened_date,
        upper(nullif(trim(region), '')) as region,

        cast(updated_at as timestamp) as updated_at,
        current_timestamp() as dbt_loaded_at

    from source_data

)

select *
from standardized