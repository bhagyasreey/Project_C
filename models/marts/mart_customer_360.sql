{{ config(
    materialized = 'table',
    cluster_by = ['customer_id', 'customer_segment'],
    tags = ['mart', 'customer_360'],

    pre_hook = [
        "{{ log_model_event(
            'MODEL_START',
            'mart_customer_360',
            'MODEL',
            'STARTED',
            'Starting mart_customer_360 build'
        ) }}"
    ],

    post_hook = [
        "{{ log_model_event(
            'MODEL_END',
            'mart_customer_360',
            'MODEL',
            'SUCCESS',
            'Completed mart_customer_360 build'
        ) }}"
    ]
) }}
with customer_activity as (

    select *
    from {{ ref('int_customer_activity') }}

),

final as (

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

        total_account_count,
        active_account_count,
        dormant_account_count,
        closed_account_count,
        total_current_balance,
        total_account_credit_limit,
        first_account_opening_date,
        latest_account_opening_date,

        total_transaction_count,
        successful_transaction_count,
        failed_transaction_count,
        high_value_transaction_count,
        successful_transaction_value,
        total_successful_inflow,
        total_successful_outflow,
        first_successful_transaction_date,
        last_successful_transaction_date,
        successful_transactions_last_90_days,

        total_card_count,
        active_card_count,
        blocked_card_count,
        expired_card_count,
        total_card_credit_limit,

        total_loan_count,
        active_loan_count,
        closed_loan_count,
        total_sanctioned_amount,
        total_outstanding_amount,

        has_no_successful_transaction_last_90_days,
        is_high_value_customer,

        total_successful_inflow - total_successful_outflow
            as net_transaction_flow,

        case
            when has_no_successful_transaction_last_90_days
                 and active_account_count > 0
                then 'DORMANT_ACTIVITY'

            when is_high_value_customer
                then 'HIGH_VALUE'

            when active_loan_count > 0
                then 'ACTIVE_BORROWER'

            when successful_transaction_count > 0
                then 'TRANSACTING'

            else 'INACTIVE'
        end as customer_activity_classification,

        current_timestamp() as dbt_loaded_at

    from customer_activity

)

select *
from final