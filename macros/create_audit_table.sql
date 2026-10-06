{% macro create_audit_table() %}

    create table if not exists
        `{{ target.database }}.{{ target.schema }}.dbt_run_audit_log`
    (
        audit_id string,
        invocation_id string,
        event_type string,
        command_name string,
        target_name string,
        target_database string,
        target_schema string,
        resource_name string,
        resource_type string,
        event_status string,
        event_timestamp timestamp,
        event_message string
    )
    partition by date(event_timestamp)
    cluster by event_type, resource_name

{% endmacro %}