{{ config(
    materialized = 'incremental',
    incremental_strategy = 'merge',
    unique_key = 'transaction_id',
    partition_by = {
        "field": "transaction_date",
        "data_type": "date",
        "granularity": "day"
    },
    cluster_by = [
        "account_id",
        "customer_id",
        "transaction_type"
    ],
    on_schema_change = 'sync_all_columns',
    tags = ['fact', 'transactions', 'incremental']
) }}

with account_transactions as (

    select
        transaction_id,
        account_id,
        customer_id,
        transaction_customer_id,
        branch_id,

        transaction_date,
        transaction_type,
        transaction_channel,
        channel_group,
        transaction_flow,

        transaction_amount,
        transaction_currency,
        transaction_status,

        reference_number,
        transaction_description,

        is_successful_transaction,
        is_failed_transaction,
        is_reversed_transaction,
        is_high_value_transaction,
        successful_inflow_amount,
        successful_outflow_amount,

        has_valid_account,
        is_customer_account_match,
        is_currency_match,

        updated_at

    from {{ ref('int_account_transactions') }}

    {% if is_incremental() %}

    where updated_at >= timestamp_sub(
        (
            select coalesce(
                max(source_updated_at),
                timestamp('1900-01-01')
            )
            from {{ this }}
        ),
        interval 3 day
    )

    {% endif %}

),

final as (

    select
        transaction_id,

        account_id as account_key,
        customer_id as customer_key,
        branch_id as branch_key,

        account_id,
        customer_id,
        transaction_customer_id,
        branch_id,

        cast(format_date('%Y%m%d', transaction_date) as int64)
            as transaction_date_key,

        transaction_date,
        transaction_type,
        transaction_channel,
        channel_group,
        transaction_flow,

        transaction_amount,
        transaction_currency,
        transaction_status,

        reference_number,
        transaction_description,

        is_successful_transaction,
        is_failed_transaction,
        is_reversed_transaction,
        is_high_value_transaction,

        successful_inflow_amount,
        successful_outflow_amount,

        case
            when is_successful_transaction
                 and transaction_flow = 'INFLOW'
                then transaction_amount

            when is_successful_transaction
                 and transaction_flow = 'OUTFLOW'
                then -transaction_amount

            else cast(0 as numeric)
        end as signed_transaction_amount,

        case
            when is_successful_transaction then 1
            else 0
        end as successful_transaction_count,

        case
            when is_failed_transaction then 1
            else 0
        end as failed_transaction_count,

        case
            when is_high_value_transaction then 1
            else 0
        end as high_value_transaction_count,

        has_valid_account,
        is_customer_account_match,
        is_currency_match,

        updated_at as source_updated_at,
        current_timestamp() as dbt_loaded_at

    from account_transactions

)

select *
from final  