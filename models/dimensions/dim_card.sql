{{ config(
    materialized = 'table',
    tags = ['dimension', 'card']
) }}

with cards as (

    select
        card_id,
        account_id,
        customer_id,
        card_type,
        card_status,
        card_network,
        issue_date,
        expiry_date,
        credit_limit,
        updated_at

    from {{ ref('stg_cards') }}

)

select
    card_id as card_key,
    card_id,
    account_id,
    customer_id,
    card_type,
    card_status,
    card_network,
    issue_date,
    expiry_date,
    credit_limit,

    case
        when card_status = 'ACTIVE'
             and expiry_date >= current_date()
            then true
        else false
    end as is_active_card,

    case
        when expiry_date < current_date() then true
        else false
    end as is_expired,

    date_diff(expiry_date, current_date(), day)
        as days_until_expiry,

    updated_at,
    current_timestamp() as dbt_loaded_at

from cards