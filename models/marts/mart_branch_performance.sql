{{ config(
    materialized = 'table',
    cluster_by = ['branch_id', 'region'],
    tags = ['mart', 'branch_performance']
) }}

with branches as (

    select
        branch_id,
        branch_name,
        city,
        state,
        region,
        branch_type,
        opened_date

    from {{ ref('dim_branch') }}

),

account_summary as (

    select
        branch_id,
        count(*) as total_account_count,
        countif(account_status = 'ACTIVE') as active_account_count,
        countif(account_status = 'DORMANT') as dormant_account_count,
        sum(coalesce(current_balance, 0)) as total_account_balance

    from {{ ref('dim_account') }}

    group by branch_id

),

transaction_summary as (

    select
        branch_id,

        count(*) as total_transaction_count,

        countif(is_successful_transaction)
            as successful_transaction_count,

        sum(
            case
                when is_successful_transaction
                    then transaction_amount
                else cast(0 as numeric)
            end
        ) as successful_transaction_value,

        count(distinct customer_id)
            as transacting_customer_count,

        max(transaction_date)
            as latest_transaction_date

    from {{ ref('fact_transactions') }}

    group by branch_id

),

loan_summary as (

    select
        branch_id,

        count(*) as total_loan_count,

        countif(loan_status = 'ACTIVE')
            as active_loan_count,

        sum(coalesce(sanctioned_amount, 0))
            as total_sanctioned_amount,

        sum(coalesce(outstanding_amount, 0))
            as total_outstanding_amount

    from {{ ref('dim_loan') }}

    group by branch_id

),

final as (

    select
        b.branch_id,
        b.branch_name,
        b.city,
        b.state,
        b.region,
        b.branch_type,
        b.opened_date,

        coalesce(a.total_account_count, 0)
            as total_account_count,

        coalesce(a.active_account_count, 0)
            as active_account_count,

        coalesce(a.dormant_account_count, 0)
            as dormant_account_count,

        coalesce(a.total_account_balance, 0)
            as total_account_balance,

        coalesce(t.total_transaction_count, 0)
            as total_transaction_count,

        coalesce(t.successful_transaction_count, 0)
            as successful_transaction_count,

        coalesce(t.successful_transaction_value, 0)
            as successful_transaction_value,

        coalesce(t.transacting_customer_count, 0)
            as transacting_customer_count,

        t.latest_transaction_date,

        coalesce(l.total_loan_count, 0)
            as total_loan_count,

        coalesce(l.active_loan_count, 0)
            as active_loan_count,

        coalesce(l.total_sanctioned_amount, 0)
            as total_sanctioned_amount,

        coalesce(l.total_outstanding_amount, 0)
            as total_outstanding_amount,

        safe_divide(
            coalesce(t.successful_transaction_count, 0),
            nullif(coalesce(t.total_transaction_count, 0), 0)
        ) as successful_transaction_rate,

        safe_divide(
            coalesce(a.active_account_count, 0),
            nullif(coalesce(a.total_account_count, 0), 0)
        ) as active_account_rate,

        current_timestamp() as dbt_loaded_at

    from branches as b

    left join account_summary as a
        on b.branch_id = a.branch_id

    left join transaction_summary as t
        on b.branch_id = t.branch_id

    left join loan_summary as l
        on b.branch_id = l.branch_id

)

select *
from final