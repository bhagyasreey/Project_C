{{ config(
    materialized = 'table',
    cluster_by = ['customer_id', 'customer_segment'],
    tags = ['mart', 'customer_profitability']
) }}

with customers as (

    select
        customer_id,
        customer_name,
        customer_segment,
        city,
        state

    from {{ ref('dim_customer') }}

),

transaction_revenue as (

    select
        customer_id,

        sum(
            case
                when is_successful_transaction
                     and transaction_type in ('FEE', 'CHARGE')
                    then transaction_amount
                else cast(0 as numeric)
            end
        ) as transaction_fee_revenue,

        sum(
            case
                when is_successful_transaction
                    then transaction_amount
                else cast(0 as numeric)
            end
        ) as successful_transaction_value,

        countif(is_successful_transaction)
            as successful_transaction_count

    from {{ ref('fact_transactions') }}

    group by customer_id

),

loan_revenue as (

    select
        customer_id,

        sum(successful_interest_amount)
            as loan_interest_revenue,

        sum(successful_principal_amount)
            as principal_repaid,

        sum(successful_payment_amount)
            as total_successful_loan_payments

    from {{ ref('fact_loan_payments') }}

    group by customer_id

),

customer_balances as (

    select
        customer_id,
        sum(coalesce(current_balance, 0)) as total_deposit_balance,
        sum(coalesce(credit_limit, 0)) as total_account_credit_limit

    from {{ ref('dim_account') }}

    group by customer_id

),

loan_exposure as (

    select
        customer_id,
        sum(coalesce(sanctioned_amount, 0)) as total_sanctioned_amount,
        sum(coalesce(outstanding_amount, 0)) as total_outstanding_amount

    from {{ ref('dim_loan') }}

    group by customer_id

),

final as (

    select
        c.customer_id,
        c.customer_name,
        c.customer_segment,
        c.city,
        c.state,

        coalesce(t.transaction_fee_revenue, 0)
            as transaction_fee_revenue,

        coalesce(l.loan_interest_revenue, 0)
            as loan_interest_revenue,

        coalesce(t.transaction_fee_revenue, 0)
            + coalesce(l.loan_interest_revenue, 0)
            as estimated_customer_revenue,

        coalesce(t.successful_transaction_value, 0)
            as successful_transaction_value,

        coalesce(t.successful_transaction_count, 0)
            as successful_transaction_count,

        coalesce(l.principal_repaid, 0)
            as principal_repaid,

        coalesce(l.total_successful_loan_payments, 0)
            as total_successful_loan_payments,

        coalesce(b.total_deposit_balance, 0)
            as total_deposit_balance,

        coalesce(b.total_account_credit_limit, 0)
            as total_account_credit_limit,

        coalesce(e.total_sanctioned_amount, 0)
            as total_sanctioned_amount,

        coalesce(e.total_outstanding_amount, 0)
            as total_outstanding_amount,

        case
            when
                coalesce(t.transaction_fee_revenue, 0)
                + coalesce(l.loan_interest_revenue, 0)
                >= {{ var('high_value_transaction_threshold', 100000) }}
                then true
            else false
        end as is_high_revenue_customer,

        current_timestamp() as dbt_loaded_at

    from customers as c

    left join transaction_revenue as t
        on c.customer_id = t.customer_id

    left join loan_revenue as l
        on c.customer_id = l.customer_id

    left join customer_balances as b
        on c.customer_id = b.customer_id

    left join loan_exposure as e
        on c.customer_id = e.customer_id

)

select *
from final