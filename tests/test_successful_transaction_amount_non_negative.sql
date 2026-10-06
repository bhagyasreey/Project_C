{{ config(
    severity = 'error',
    store_failures = true
) }}

select
    transaction_id,
    account_id,
    customer_id,
    transaction_date,
    transaction_status,
    transaction_amount

from {{ ref('fact_transactions') }}

where transaction_status = 'SUCCESS'
  and transaction_amount < 0