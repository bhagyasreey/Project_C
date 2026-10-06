{% macro log_run_start() %}

    insert into
        `{{ target.database }}.{{ target.schema }}.dbt_run_audit_log`
    (
        audit_id,
        invocation_id,
        event_type,
        command_name,
        target_name,
        target_database,
        target_schema,
        resource_name,
        resource_type,
        event_status,
        event_timestamp,
        event_message
    )

    values
    (
        generate_uuid(),
        '{{ invocation_id }}',
        'RUN_START',
        '{{ flags.WHICH | default("UNKNOWN", true) }}',
        '{{ target.name }}',
        '{{ target.database }}',
        '{{ target.schema }}',
        null,
        'DBT_INVOCATION',
        'STARTED',
        current_timestamp(),
        'BankSphere dbt invocation started'
    )

{% endmacro %}