{{ config(
    materialized = 'view',
    tags = ['staging', 'cards']
) }}

with source_data as (

    select *
    from {{ source('banksphere_raw', 'cards') }}

),

standardized as (

    select
        nullif(trim(card_id), '') as card_id,
        nullif(trim(account_id), '') as account_id,
        nullif(trim(customer_id), '') as customer_id,

        upper(nullif(trim(card_type), '')) as card_type,
        upper(nullif(trim(card_status), '')) as card_status,
        upper(nullif(trim(network), '')) as card_network,

        cast(issue_date as date) as issue_date,
        cast(expiry_date as date) as expiry_date,
        safe_cast(credit_limit as numeric) as credit_limit,

        cast(updated_at as timestamp) as updated_at,
        current_timestamp() as dbt_loaded_at

    from source_data

)

select *
from standardized