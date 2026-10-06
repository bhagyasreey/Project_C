{% snapshot account_snapshot %}

{{
    config(
        target_schema = target.schema,
        unique_key = 'account_id',
        strategy = 'check',
        check_cols = [
            'customer_id',
            'branch_id',
            'account_type',
            'account_status',
            'currency',
            'credit_limit',
            'current_balance'
        ],
        tags = ['snapshot', 'account', 'check_strategy']
    )
}}

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

from {{ source('banksphere_raw', 'accounts') }}

{% endsnapshot %}