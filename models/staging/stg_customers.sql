{{ config(
    materialized = 'view',
    tags = ['staging', 'customers']
) }}

with source_data as (

    select *
    from {{ source('banksphere_raw', 'customers') }}

),

standardized as (

    select
        nullif(trim(customer_id), '') as customer_id,
        nullif(trim(customer_name), '') as customer_name,
        lower(nullif(trim(email), '')) as email,

        cast(phone as string) as phone,

        initcap(nullif(trim(city), '')) as city,
        upper(nullif(trim(state), '')) as state,
        upper(nullif(trim(customer_segment), '')) as customer_segment,

        cast(date_of_birth as date) as date_of_birth,
        cast(signup_date as date) as signup_date,
        upper(nullif(trim(kyc_status), '')) as kyc_status,

        cast(updated_at as timestamp) as updated_at,
        current_timestamp() as dbt_loaded_at

    from source_data

)

select *
from standardized