{% macro log_banksphere_configuration() %}

    {% set high_value_threshold =
        var('high_value_transaction_threshold', 100000)
    %}

    {% set analysis_start_date =
        var('analysis_start_date', '2025-01-01')
    %}

    {{ log(
        'BankSphere configuration details:',
        info=true
    ) }}

    {{ log(
        'Target name: ' ~ target.name,
        info=true
    ) }}

    {{ log(
        'BigQuery project: ' ~ target.database,
        info=true
    ) }}

    {{ log(
        'BigQuery dataset: ' ~ target.schema,
        info=true
    ) }}

    {{ log(
        'High-value transaction threshold: '
        ~ high_value_threshold,
        info=true
    ) }}

    {{ log(
        'Analysis start date: '
        ~ analysis_start_date,
        info=true
    ) }}

    {% if target.name == 'prod' %}

        {{ log(
            'Production target selected. Apply deployment controls.',
            info=true
        ) }}

    {% elif target.name == 'sit' %}

        {{ log(
            'SIT target selected. Integration validation is enabled.',
            info=true
        ) }}

    {% else %}

        {{ log(
            'Development target selected.',
            info=true
        ) }}

    {% endif %}

{% endmacro %}