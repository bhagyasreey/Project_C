{{ config(
    materialized = 'table',
    tags = ['dimension', 'date']
) }}

with date_spine as (

    select calendar_date

    from unnest(
        generate_date_array(
            date('2020-01-01'),
            date(extract(year from current_date()) + 1, 12, 31),
            interval 1 day
        )
    ) as calendar_date

)

select
    cast(format_date('%Y%m%d', calendar_date) as int64) as date_key,
    calendar_date,

    extract(year from calendar_date) as calendar_year,
    extract(quarter from calendar_date) as calendar_quarter,
    extract(month from calendar_date) as month_number,
    format_date('%B', calendar_date) as month_name,
    format_date('%b', calendar_date) as month_short_name,

    extract(week from calendar_date) as week_number,
    extract(day from calendar_date) as day_of_month,
    extract(dayofyear from calendar_date) as day_of_year,
    extract(dayofweek from calendar_date) as day_of_week_number,
    format_date('%A', calendar_date) as day_name,
    format_date('%a', calendar_date) as day_short_name,

    date_trunc(calendar_date, month) as month_start_date,
    last_day(calendar_date, month) as month_end_date,
    date_trunc(calendar_date, quarter) as quarter_start_date,
    last_day(calendar_date, quarter) as quarter_end_date,
    date_trunc(calendar_date, year) as year_start_date,
    last_day(calendar_date, year) as year_end_date,

    format_date('%Y-%m', calendar_date) as year_month,

    case
        when extract(dayofweek from calendar_date) in (1, 7)
            then true
        else false
    end as is_weekend,

    case
        when extract(dayofweek from calendar_date) not in (1, 7)
            then true
        else false
    end as is_weekday,

    case
        when calendar_date = current_date() then true
        else false
    end as is_current_date,

    case
        when extract(year from calendar_date)
             = extract(year from current_date())
            then true
        else false
    end as is_current_year,

    case
        when date_trunc(calendar_date, month)
             = date_trunc(current_date(), month)
            then true
        else false
    end as is_current_month,

    current_timestamp() as dbt_loaded_at

from date_spine