{{ config(
    materialized = 'view',
    tags = ['staging', 'loan_payments']
) }}

with source_data as (

    select *
    from {{ source('banksphere_raw', 'loan_payments') }}

),

standardized as (

    select
        nullif(trim(payment_id), '') as payment_id,
        nullif(trim(loan_id), '') as loan_id,

        cast(payment_date as date) as payment_date,

        safe_cast(payment_amount as numeric) as payment_amount,
        safe_cast(principal_amount as numeric) as principal_amount,
        safe_cast(interest_amount as numeric) as interest_amount,

        upper(nullif(trim(payment_status), '')) as payment_status,
        upper(nullif(trim(payment_channel), '')) as payment_channel,

        cast(updated_at as timestamp) as updated_at,
        current_timestamp() as dbt_loaded_at

    from source_data

)

select *
from standardized