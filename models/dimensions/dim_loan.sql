{{ config(
    materialized = 'table',
    tags = ['dimension', 'loan']
) }}

with loans as (

    select
        loan_id,
        customer_id,
        account_id,
        branch_id,
        account_type,
        account_status,
        loan_type,
        loan_status,
        application_date,
        sanctioned_amount,
        interest_rate,
        tenure_months,
        outstanding_amount,
        outstanding_ratio,
        is_outstanding_within_sanctioned_amount,
        updated_at

    from {{ ref('int_loan_summary') }}

)

select
    loan_id as loan_key,
    loan_id,
    customer_id,
    account_id,
    branch_id,
    account_type,
    account_status,
    loan_type,
    loan_status,
    application_date,
    sanctioned_amount,
    interest_rate,
    tenure_months,
    outstanding_amount,
    outstanding_ratio,

    sanctioned_amount - outstanding_amount
        as calculated_repaid_amount,

    case
        when loan_status = 'ACTIVE' then true
        else false
    end as is_active_loan,

    case
        when loan_status = 'CLOSED' then true
        else false
    end as is_closed_loan,

    is_outstanding_within_sanctioned_amount,

    updated_at,
    current_timestamp() as dbt_loaded_at

from loans