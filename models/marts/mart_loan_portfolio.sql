{{ config(
    materialized = 'table',
    cluster_by = ['loan_type', 'loan_status', 'branch_id'],
    tags = ['mart', 'loan_portfolio']
) }}

with loans as (

    select
        loan_id,
        customer_id,
        account_id,
        branch_id,
        loan_type,
        loan_status,
        sanctioned_amount,
        outstanding_amount,
        interest_rate,
        tenure_months,
        total_payment_count,
        successful_payment_count,
        failed_payment_count,
        successful_payment_amount,
        successful_principal_amount,
        successful_interest_amount

    from {{ ref('int_loan_summary') }}

),

branches as (

    select
        branch_id,
        branch_name,
        region

    from {{ ref('dim_branch') }}

),

final as (

    select
        l.branch_id,
        b.branch_name,
        b.region,
        l.loan_type,
        l.loan_status,

        count(*) as loan_count,
        count(distinct l.customer_id) as customer_count,

        sum(l.sanctioned_amount) as total_sanctioned_amount,
        sum(l.outstanding_amount) as total_outstanding_amount,

        sum(l.successful_payment_amount) as successful_payment_amount,
        sum(l.successful_principal_amount) as successful_principal_amount,
        sum(l.successful_interest_amount) as successful_interest_revenue,

        sum(l.total_payment_count) as total_payment_count,
        sum(l.successful_payment_count) as successful_payment_count,
        sum(l.failed_payment_count) as failed_payment_count,

        avg(l.interest_rate) as average_interest_rate,
        avg(l.tenure_months) as average_tenure_months,

        safe_divide(
            sum(l.outstanding_amount),
            nullif(sum(l.sanctioned_amount), 0)
        ) as portfolio_outstanding_ratio,

        safe_divide(
            sum(l.successful_payment_count),
            nullif(sum(l.total_payment_count), 0)
        ) as repayment_success_rate,

        safe_divide(
            sum(l.failed_payment_count),
            nullif(sum(l.total_payment_count), 0)
        ) as payment_failure_rate,

        current_timestamp() as dbt_loaded_at

    from loans as l

    left join branches as b
        on l.branch_id = b.branch_id

    group by
        l.branch_id,
        b.branch_name,
        b.region,
        l.loan_type,
        l.loan_status

)

select *
from final