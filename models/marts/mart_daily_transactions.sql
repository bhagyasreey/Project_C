{{ config(
    materialized = 'table',
    partition_by = {
        "field": "transaction_date",
        "data_type": "date",
        "granularity": "day"
    },
    cluster_by = [
        "transaction_channel",
        "transaction_type",
        "branch_id"
    ],
    tags = ['mart', 'daily_transactions']
) }}

with transactions as (

    select
        transaction_date,
        branch_id,
        transaction_type,
        transaction_channel,
        channel_group,
        transaction_flow,
        transaction_status,
        transaction_amount,
        successful_inflow_amount,
        successful_outflow_amount,
        is_high_value_transaction

    from {{ ref('fact_transactions') }}
    where transaction_date >= date(
'{{ var("analysis_start_date", "2025-01-01") }}'
)

),

final as (

    select
        transaction_date,
        cast(format_date('%Y%m%d', transaction_date) as int64)
            as transaction_date_key,

        branch_id,
        transaction_type,
        transaction_channel,
        channel_group,
        transaction_flow,
        transaction_status,

        count(*) as transaction_count,

        countif(transaction_status = 'SUCCESS')
            as successful_transaction_count,

        countif(transaction_status = 'FAILED')
            as failed_transaction_count,

        countif(is_high_value_transaction)
            as high_value_transaction_count,

        sum(transaction_amount) as total_transaction_value,

        sum(
            case
                when transaction_status = 'SUCCESS'
                    then transaction_amount
                else cast(0 as numeric)
            end
        ) as successful_transaction_value,

        sum(successful_inflow_amount)
            as successful_inflow_value,

        sum(successful_outflow_amount)
            as successful_outflow_value,

        avg(
            case
                when transaction_status = 'SUCCESS'
                    then transaction_amount
            end
        ) as average_successful_transaction_value,

        safe_divide(
            countif(transaction_status = 'SUCCESS'),
            count(*)
        ) as successful_transaction_rate,

        current_timestamp() as dbt_loaded_at

    from transactions

    group by
        transaction_date,
        branch_id,
        transaction_type,
        transaction_channel,
        channel_group,
        transaction_flow,
        transaction_status

)

select *
from final