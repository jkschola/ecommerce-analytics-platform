-- macros/get_recency_reference_date.sql

{% macro get_recency_reference_date() %}
    {% if target.name == 'prod' %}
        current_timestamp()
    {% else %}
        '{{ var("recency_reference_date") }}'::timestamp
    {% endif %}
{% endmacro %}