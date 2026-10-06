{{ config(
    severity = 'error',
    store_failures = true
) }}

select
    loan_id,
    customer_id,
    account_id,
    loan_status,
    sanctioned_amount,
    outstanding_amount

from {{ ref('dim_loan') }}

where outstanding_amount > sanctioned_amount