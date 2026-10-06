{{ config(
    materialized = 'view',
    tags = ['staging', 'transactions']
) }}

with source_data as (

    select *
    from {{ source('banksphere_raw', 'transactions') }}

),

standardized as (

    select
        nullif(trim(transaction_id), '') as transaction_id,
        nullif(trim(account_id), '') as account_id,
        nullif(trim(customer_id), '') as customer_id,

        cast(transaction_date as date) as transaction_date,

        upper(nullif(trim(transaction_type), '')) as transaction_type,
        upper(nullif(trim(channel), '')) as transaction_channel,

        safe_cast(amount as numeric) as transaction_amount,

        upper(nullif(trim(currency), '')) as currency,
        upper(nullif(trim(transaction_status), '')) as transaction_status,

        nullif(trim(reference_number), '') as reference_number,
        nullif(trim(description), '') as transaction_description,

        cast(updated_at as timestamp) as updated_at,
        current_timestamp() as dbt_loaded_at

    from source_data

)

select *
from standardized