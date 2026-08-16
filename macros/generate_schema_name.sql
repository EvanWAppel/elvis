{#
    Use a custom `+schema:` verbatim instead of dbt's default
    `<target_schema>_<custom>` concatenation. This lets the CI seed fixtures land
    in the `raw` schema exactly (so `source('raw', ...)` resolves to them), while
    models with no custom schema stay in the target schema (`main`).
#}
{% macro generate_schema_name(custom_schema_name, node) -%}
    {%- if custom_schema_name is none -%}
        {{ target.schema }}
    {%- else -%}
        {{ custom_schema_name | trim }}
    {%- endif -%}
{%- endmacro %}
