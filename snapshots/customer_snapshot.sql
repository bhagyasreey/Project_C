{% snapshot customer_snapshot %}

{{
    config(
        target_schema = target.schema,
        unique_key = 'customer_id',
        strategy = 'timestamp',
        updated_at = 'updated_at',
        hard_deletes = 'new_record',
        tags = ['snapshot', 'customer', 'timestamp_strategy']
    )
}}

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

from {{ source('banksphere_raw', 'customers') }}

{% endsnapshot %}