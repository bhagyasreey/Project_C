{{ config(
    materialized = 'table',
    partition_by = {
        "field": "payment_date",
        "data_type": "date",
        "granularity": "day"
    },
    cluster_by = [
        "loan_id",
        "customer_id",
        "payment_status"
    ],
    tags = ['fact', 'loan_payments']
) }}

with loan_payments as (

    select
        payment_id,
        loan_id,
        payment_date,
        payment_amount,
        principal_amount,
        interest_amount,
        payment_status,
        payment_channel,
        updated_at

    from {{ ref('stg_loan_payments') }}

),

loans as (

    select
        loan_id,
        customer_id,
        account_id,
        branch_id,
        loan_type,
        loan_status

    from {{ ref('int_loan_summary') }}

),

final as (

    select
        p.payment_id,

        p.loan_id as loan_key,
        l.customer_id as customer_key,
        l.account_id as account_key,
        l.branch_id as branch_key,

        p.loan_id,
        l.customer_id,
        l.account_id,
        l.branch_id,

        cast(format_date('%Y%m%d', p.payment_date) as int64)
            as payment_date_key,

        p.payment_date,
        l.loan_type,
        l.loan_status,

        p.payment_status,
        p.payment_channel,

        p.payment_amount,
        p.principal_amount,
        p.interest_amount,

        case
            when p.payment_status = 'SUCCESS' then true
            else false
        end as is_successful_payment,

        case
            when p.payment_status = 'FAILED' then true
            else false
        end as is_failed_payment,

        case
            when p.payment_status = 'SUCCESS' then p.payment_amount
            else cast(0 as numeric)
        end as successful_payment_amount,

        case
            when p.payment_status = 'SUCCESS' then p.principal_amount
            else cast(0 as numeric)
        end as successful_principal_amount,

        case
            when p.payment_status = 'SUCCESS' then p.interest_amount
            else cast(0 as numeric)
        end as successful_interest_amount,

        case
            when p.payment_status = 'SUCCESS' then 1
            else 0
        end as successful_payment_count,

        case
            when p.payment_status = 'FAILED' then 1
            else 0
        end as failed_payment_count,

        case
            when l.loan_id is not null then true
            else false
        end as has_valid_loan,

        p.updated_at as source_updated_at,
        current_timestamp() as dbt_loaded_at

    from loan_payments as p

    left join loans as l
        on p.loan_id = l.loan_id

)

select *
from final