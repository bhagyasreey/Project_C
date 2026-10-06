{% macro log_model_event(
    event_type,
    resource_name,
    resource_type='MODEL',
    event_status='INFO',
    event_message=''
) %}

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
        '{{ event_type }}',
        '{{ flags.WHICH | default("UNKNOWN", true) }}',
        '{{ target.name }}',
        '{{ target.database }}',
        '{{ target.schema }}',
        '{{ resource_name }}',
        '{{ resource_type }}',
        '{{ event_status }}',
        current_timestamp(),
        '{{ event_message }}'
    )

{% endmacro %}