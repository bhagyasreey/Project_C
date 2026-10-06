{{ config(
    materialized = 'view',
    tags = ['intermediate', 'customers', 'activity']
) }}

with customers as (

    select
        customer_id,
        customer_name,
        email,
        phone,
        city,
        state,
        customer_segment,
        date_of_birth,
        signup_date,
        kyc_status

    from {{ ref('stg_customers') }}

),

account_summary as (

    select
        customer_id,

        count(*) as total_account_count,

        countif(account_status = 'ACTIVE') as active_account_count,

        countif(account_status = 'DORMANT') as dormant_account_count,

        countif(account_status = 'CLOSED') as closed_account_count,

        sum(coalesce(current_balance, 0)) as total_current_balance,

        sum(coalesce(credit_limit, 0)) as total_account_credit_limit,

        min(opening_date) as first_account_opening_date,

        max(opening_date) as latest_account_opening_date

    from {{ ref('stg_accounts') }}

    group by customer_id

),

transaction_summary as (

    select
        customer_id,

        count(*) as total_transaction_count,

        countif(is_successful_transaction) as successful_transaction_count,

        countif(is_failed_transaction) as failed_transaction_count,

        countif(is_high_value_transaction) as high_value_transaction_count,

        sum(
            case
                when is_successful_transaction
                    then transaction_amount
                else cast(0 as numeric)
            end
        ) as successful_transaction_value,

        sum(successful_inflow_amount) as total_successful_inflow,

        sum(successful_outflow_amount) as total_successful_outflow,

        min(
            case
                when is_successful_transaction
                    then transaction_date
            end
        ) as first_successful_transaction_date,

        max(
            case
                when is_successful_transaction
                    then transaction_date
            end
        ) as last_successful_transaction_date,

        countif(
            is_successful_transaction
            and transaction_date >= date_sub(current_date(), interval 90 day)
        ) as successful_transactions_last_90_days

    from {{ ref('int_account_transactions') }}

    group by customer_id

),

card_summary as (

    select
        customer_id,

        count(*) as total_card_count,

        countif(card_status = 'ACTIVE') as active_card_count,

        countif(card_status = 'BLOCKED') as blocked_card_count,

        countif(card_status = 'EXPIRED') as expired_card_count,

        sum(coalesce(credit_limit, 0)) as total_card_credit_limit

    from {{ ref('stg_cards') }}

    group by customer_id

),

loan_summary as (

    select
        customer_id,

        count(*) as total_loan_count,

        countif(loan_status = 'ACTIVE') as active_loan_count,

        countif(loan_status = 'CLOSED') as closed_loan_count,

        sum(coalesce(sanctioned_amount, 0)) as total_sanctioned_amount,

        sum(coalesce(outstanding_amount, 0)) as total_outstanding_amount

    from {{ ref('stg_loans') }}

    group by customer_id

),

final as (

    select
        c.customer_id,
        c.customer_name,
        c.email,
        c.phone,
        c.city,
        c.state,
        c.customer_segment,
        c.date_of_birth,
        c.signup_date,
        c.kyc_status,

        coalesce(a.total_account_count, 0) as total_account_count,
        coalesce(a.active_account_count, 0) as active_account_count,
        coalesce(a.dormant_account_count, 0) as dormant_account_count,
        coalesce(a.closed_account_count, 0) as closed_account_count,
        coalesce(a.total_current_balance, 0) as total_current_balance,
        coalesce(a.total_account_credit_limit, 0)
            as total_account_credit_limit,
        a.first_account_opening_date,
        a.latest_account_opening_date,

        coalesce(t.total_transaction_count, 0)
            as total_transaction_count,
        coalesce(t.successful_transaction_count, 0)
            as successful_transaction_count,
        coalesce(t.failed_transaction_count, 0)
            as failed_transaction_count,
        coalesce(t.high_value_transaction_count, 0)
            as high_value_transaction_count,
        coalesce(t.successful_transaction_value, 0)
            as successful_transaction_value,
        coalesce(t.total_successful_inflow, 0)
            as total_successful_inflow,
        coalesce(t.total_successful_outflow, 0)
            as total_successful_outflow,
        t.first_successful_transaction_date,
        t.last_successful_transaction_date,
        coalesce(t.successful_transactions_last_90_days, 0)
            as successful_transactions_last_90_days,

        coalesce(cd.total_card_count, 0) as total_card_count,
        coalesce(cd.active_card_count, 0) as active_card_count,
        coalesce(cd.blocked_card_count, 0) as blocked_card_count,
        coalesce(cd.expired_card_count, 0) as expired_card_count,
        coalesce(cd.total_card_credit_limit, 0) as total_card_credit_limit,

        coalesce(l.total_loan_count, 0) as total_loan_count,
        coalesce(l.active_loan_count, 0) as active_loan_count,
        coalesce(l.closed_loan_count, 0) as closed_loan_count,
        coalesce(l.total_sanctioned_amount, 0)
            as total_sanctioned_amount,
        coalesce(l.total_outstanding_amount, 0)
            as total_outstanding_amount,

        case
            when coalesce(t.successful_transactions_last_90_days, 0) = 0
                then true
            else false
        end as has_no_successful_transaction_last_90_days,

        case
            when coalesce(t.successful_transaction_value, 0)
                 >= {{ var('high_value_transaction_threshold', 100000) }}
                then true
            else false
        end as is_high_value_customer,

        current_timestamp() as dbt_loaded_at

    from customers as c

    left join account_summary as a
        on c.customer_id = a.customer_id

    left join transaction_summary as t
        on c.customer_id = t.customer_id

    left join card_summary as cd
        on c.customer_id = cd.customer_id

    left join loan_summary as l
        on c.customer_id = l.customer_id

)

select *
from final