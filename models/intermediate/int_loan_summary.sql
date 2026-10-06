{{ config(
    materialized = 'view',
    tags = ['intermediate', 'loans', 'payments']
) }}

with loans as (

    select
        loan_id,
        customer_id,
        account_id,
        loan_type,
        loan_status,
        application_date,
        sanctioned_amount,
        interest_rate,
        tenure_months,
        outstanding_amount,
        updated_at

    from {{ ref('stg_loans') }}

),

accounts as (

    select
        account_id,
        customer_id as account_customer_id,
        branch_id,
        account_type,
        account_status

    from {{ ref('stg_accounts') }}

),

payment_summary as (

    select
        loan_id,

        count(*) as total_payment_count,

        countif(payment_status = 'SUCCESS')
            as successful_payment_count,

        countif(payment_status = 'FAILED')
            as failed_payment_count,

        sum(
            case
                when payment_status = 'SUCCESS'
                    then payment_amount
                else cast(0 as numeric)
            end
        ) as successful_payment_amount,

        sum(
            case
                when payment_status = 'SUCCESS'
                    then principal_amount
                else cast(0 as numeric)
            end
        ) as successful_principal_amount,

        sum(
            case
                when payment_status = 'SUCCESS'
                    then interest_amount
                else cast(0 as numeric)
            end
        ) as successful_interest_amount,

        min(
            case
                when payment_status = 'SUCCESS'
                    then payment_date
            end
        ) as first_successful_payment_date,

        max(
            case
                when payment_status = 'SUCCESS'
                    then payment_date
            end
        ) as last_successful_payment_date

    from {{ ref('stg_loan_payments') }}

    group by loan_id

),

final as (

    select
        l.loan_id,
        l.customer_id,
        l.account_id,

        a.branch_id,
        a.account_type,
        a.account_status,

        l.loan_type,
        l.loan_status,
        l.application_date,
        l.sanctioned_amount,
        l.interest_rate,
        l.tenure_months,
        l.outstanding_amount,

        coalesce(p.total_payment_count, 0)
            as total_payment_count,
        coalesce(p.successful_payment_count, 0)
            as successful_payment_count,
        coalesce(p.failed_payment_count, 0)
            as failed_payment_count,

        coalesce(p.successful_payment_amount, 0)
            as successful_payment_amount,
        coalesce(p.successful_principal_amount, 0)
            as successful_principal_amount,
        coalesce(p.successful_interest_amount, 0)
            as successful_interest_amount,

        p.first_successful_payment_date,
        p.last_successful_payment_date,

        l.sanctioned_amount - l.outstanding_amount
            as calculated_repaid_amount,

        {{ safe_divide_numeric(
        'l.outstanding_amount',
        'l.sanctioned_amount',
        0
        ) }} as outstanding_ratio,

        case
            when l.outstanding_amount <= l.sanctioned_amount
                then true
            else false
        end as is_outstanding_within_sanctioned_amount,

        case
            when l.customer_id = a.account_customer_id
                then true
            else false
        end as is_loan_customer_account_match,

        case
            when a.account_id is not null
                then true
            else false
        end as has_valid_account,

        l.updated_at,
       {{ audit_timestamp() }} as dbt_loaded_at

    from loans as l

    left join accounts as a
        on l.account_id = a.account_id

    left join payment_summary as p
        on l.loan_id = p.loan_id

)

select *
from final