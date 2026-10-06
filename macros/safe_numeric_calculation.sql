{% macro safe_divide_numeric(numerator, denominator, default_value=0) %}

    coalesce(
        safe_divide(
            cast({{ numerator }} as numeric),
            nullif(cast({{ denominator }} as numeric), 0)
        ),
        cast({{ default_value }} as numeric)
    )

{% endmacro %}


{% macro audit_timestamp() %}

    current_timestamp()

{% endmacro %}