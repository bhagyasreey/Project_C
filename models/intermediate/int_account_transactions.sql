{{ config(
    materialized = 'view',
    tags = ['intermediate', 'transactions', 'accounts']
) }}

with classified_transactions as (

    select *
    from {{ ref('int_transaction_classification') }}

),

accounts as (

    select
        account_id,
        customer_id as account_customer_id,
        branch_id,
        account_type,
        account_status,
        currency as account_currency,
        opening_date,
        credit_limit,
        current_balance

    from {{ ref('stg_accounts') }}

),

enriched as (

    select
        t.transaction_id,
        t.account_id,

        t.customer_id as transaction_customer_id,
        a.account_customer_id as customer_id,

        a.branch_id,
        a.account_type,
        a.account_status,
        a.account_currency,
        a.opening_date as account_opening_date,
        a.credit_limit as account_credit_limit,
        a.current_balance,

        t.transaction_date,
        t.transaction_type,
        t.transaction_channel,
        t.channel_group,
        t.transaction_flow,
        t.transaction_amount,
        t.currency as transaction_currency,
        t.transaction_status,
        t.reference_number,
        t.transaction_description,

        t.is_successful_transaction,
        t.is_failed_transaction,
        t.is_reversed_transaction,
        t.is_high_value_transaction,
       
        t.successful_inflow_amount,
        t.successful_outflow_amount,

        case
            when t.customer_id is null then false
            when t.customer_id = a.account_customer_id then true
            else false
        end as is_customer_account_match,

        case
            when a.account_id is null then false
            else true
        end as has_valid_account,

        case
            when t.currency = a.account_currency then true
            else false
        end as is_currency_match,

        t.updated_at,
        t.dbt_loaded_at

    from classified_transactions as t

    left join accounts as a
        on t.account_id = a.account_id

)

select *
from enriched