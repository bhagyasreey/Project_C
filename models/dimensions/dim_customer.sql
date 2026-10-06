{{ config(
    materialized = 'table',
    tags = ['dimension', 'customer']
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
        kyc_status,
        updated_at

    from {{ ref('stg_customers') }}

)

select
    customer_id as customer_key,
    customer_id,
    customer_name,
    email,
    phone,
    city,
    state,
    customer_segment,
    date_of_birth,
    signup_date,
    kyc_status,

    date_diff(current_date(), date_of_birth, year) as customer_age,

    case
        when date_of_birth is null then 'UNKNOWN'
        when date_diff(current_date(), date_of_birth, year) < 25
            then 'UNDER_25'
        when date_diff(current_date(), date_of_birth, year) between 25 and 34
            then '25_TO_34'
        when date_diff(current_date(), date_of_birth, year) between 35 and 44
            then '35_TO_44'
        when date_diff(current_date(), date_of_birth, year) between 45 and 59
            then '45_TO_59'
        else '60_AND_ABOVE'
    end as age_group,

    date_diff(current_date(), signup_date, month)
        as customer_tenure_months,

    case
        when kyc_status in ('VERIFIED', 'COMPLETED', 'APPROVED')
            then true
        else false
    end as is_kyc_verified,

    updated_at,
    current_timestamp() as dbt_loaded_at

from customers