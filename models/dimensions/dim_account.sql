{{ config(
    materialized = 'table',
    tags = ['dimension', 'account']
) }}

with accounts as (

    select
        account_id,
        customer_id,
        branch_id,
        account_type,
        account_status,
        currency,
        opening_date,
        credit_limit,
        current_balance,
        updated_at

    from {{ ref('stg_accounts') }}

)

select
    account_id as account_key,
    account_id,
    customer_id,
    branch_id,
    account_type,
    account_status,
    currency,
    opening_date,
    credit_limit,
    current_balance,

    date_diff(current_date(), opening_date, month)
        as account_tenure_months,

    case
        when account_status = 'ACTIVE' then true
        else false
    end as is_active_account,

    case
        when account_status = 'DORMANT' then true
        else false
    end as is_dormant_account,

    case
        when account_status = 'CLOSED' then true
        else false
    end as is_closed_account,

    case
        when current_balance < 0 then true
        else false
    end as is_overdrawn,

    updated_at,
    current_timestamp() as dbt_loaded_at

from accounts