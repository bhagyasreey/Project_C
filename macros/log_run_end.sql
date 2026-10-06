{% macro log_run_end(results) %}

    {% set success_count = 0 %}
    {% set error_count = 0 %}
    {% set skipped_count = 0 %}
    {% set warning_count = 0 %}

    {% for result in results %}

        {% if result.status | lower in ['success', 'pass'] %}
            {% set success_count = success_count + 1 %}

        {% elif result.status | lower in ['error', 'fail', 'failed'] %}
            {% set error_count = error_count + 1 %}

        {% elif result.status | lower in ['skipped', 'skip'] %}
            {% set skipped_count = skipped_count + 1 %}

        {% elif result.status | lower in ['warn', 'warning'] %}
            {% set warning_count = warning_count + 1 %}

        {% endif %}

    {% endfor %}

    {% if error_count > 0 %}
        {% set final_status = 'FAILED' %}
    {% elif warning_count > 0 %}
        {% set final_status = 'COMPLETED_WITH_WARNINGS' %}
    {% else %}
        {% set final_status = 'SUCCESS' %}
    {% endif %}

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
        'RUN_END',
        '{{ flags.WHICH | default("UNKNOWN", true) }}',
        '{{ target.name }}',
        '{{ target.database }}',
        '{{ target.schema }}',
        null,
        'DBT_INVOCATION',
        '{{ final_status }}',
        current_timestamp(),
        'BankSphere run completed. Total results: {{ results | length }}; successful: {{ success_count }}; errors: {{ error_count }}; warnings: {{ warning_count }}; skipped: {{ skipped_count }}'
    )

{% endmacro %}