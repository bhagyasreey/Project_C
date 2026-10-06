{{ config(
    materialized = 'ephemeral',
    tags = ['intermediate', 'transactions', 'ephemeral']
) }}

with transactions as (

    select
        transaction_id,
        account_id,
        customer_id,
        transaction_date,
        transaction_type,
        transaction_channel,
        transaction_amount,
        currency,
        transaction_status,
        reference_number,
        transaction_description,
        updated_at,
        dbt_loaded_at

    from {{ ref('stg_transactions') }}

),

classified as (

    select
        transaction_id,
        account_id,
        customer_id,
        transaction_date,
        transaction_type,
        transaction_channel,
        transaction_amount,
        currency,
        transaction_status,
        reference_number,
        transaction_description,

        case
            when transaction_status = 'SUCCESS' then true
            else false
        end as is_successful_transaction,

        case
            when transaction_status = 'FAILED' then true
            else false
        end as is_failed_transaction,

        case
            when transaction_status = 'REVERSED' then true
            else false
        end as is_reversed_transaction,

        {{ classify_transaction('transaction_type') }}
            as transaction_flow,

        case
            when transaction_channel = 'ATM'
                then 'ATM'

            when transaction_channel in (
                'MOBILE',
                'MOBILE_BANKING',
                'INTERNET',
                'INTERNET_BANKING',
                'ONLINE',
                'UPI'
            )
                then 'DIGITAL'

            when transaction_channel in (
                'BRANCH',
                'TELLER'
            )
                then 'BRANCH'

            else 'OTHER'
        end as channel_group,

        case
            when transaction_amount >=
                 {{ var(
                     'high_value_transaction_threshold',
                     100000
                 ) }}
                then true
            else false
        end as is_high_value_transaction,

        case
            when transaction_status = 'SUCCESS'
                 and {{ classify_transaction('transaction_type') }}
                     = 'INFLOW'
                then transaction_amount

            else cast(0 as numeric)
        end as successful_inflow_amount,

        case
            when transaction_status = 'SUCCESS'
                 and {{ classify_transaction('transaction_type') }}
                     = 'OUTFLOW'
                then transaction_amount

            else cast(0 as numeric)
        end as successful_outflow_amount,

        updated_at,
        dbt_loaded_at

    from transactions

)

select *
from classified