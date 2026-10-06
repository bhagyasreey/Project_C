{% macro record_manual_operation(
    operation_name,
    operation_message='Manual BankSphere operation'
) %}

    {% set create_table_sql %}

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

    {% endset %}

    {% do run_query(create_table_sql) %}

    {% set insert_sql %}

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
            'MANUAL_OPERATION',
            'run-operation',
            '{{ target.name }}',
            '{{ target.database }}',
            '{{ target.schema }}',
            '{{ operation_name }}',
            'OPERATION',
            'SUCCESS',
            current_timestamp(),
            '{{ operation_message }}'
        )

    {% endset %}

    {% do run_query(insert_sql) %}

    {{ log(
        'Recorded BankSphere operation: ' ~ operation_name,
        info=true
    ) }}

{% endmacro %}