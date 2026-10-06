{{ config(
    materialized = 'view',
    tags = ['intermediate', 'accounts', 'reference_data']
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

),

reference_codes as (

    select
        upper(trim(product_code)) as product_code,
        upper(trim(product_group)) as product_group,
        trim(description) as product_description

    from {{ ref('banking_reference_codes') }}

),

final as (

    select
        a.account_id,
        a.customer_id,
        a.branch_id,
        a.account_type,
        a.account_status,
        a.currency,
        a.opening_date,
        a.credit_limit,
        a.current_balance,

        r.product_code,
        r.product_group,
        r.product_description,

        case
            when r.product_code is not null then true
            else false
        end as has_valid_product_mapping,

        a.updated_at,
        current_timestamp() as dbt_loaded_at

    from accounts as a

    left join reference_codes as r
        on replace(upper(trim(a.account_type)), ' ', '_')
           = r.product_code

)

select *
from final  