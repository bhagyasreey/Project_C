{{ config(
    severity = 'warn',
    warn_if = '>0',
    error_if = '>100',
    store_failures = true
) }}

select
    account_id,
    customer_id,
    current_balance

from {{ ref('dim_account') }}

where current_balance < -1000000
