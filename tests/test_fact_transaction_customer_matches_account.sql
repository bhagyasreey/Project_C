{{ config(
    severity = 'error',
    store_failures = true
) }}

select
    transaction_id,
    account_id,
    transaction_customer_id,
    customer_id as account_customer_id

from {{ ref('fact_transactions') }}

where transaction_customer_id is null
   or customer_id is null
   or transaction_customer_id != customer_id