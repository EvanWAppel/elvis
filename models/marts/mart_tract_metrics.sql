-- Whole-tract numerators and denominators; city selection never clips either.
with totals as (
    select topic, geoid, sum(record_count) as observed_count
    from {{ ref('stg_tract_counts') }}
    group by 1, 2
), combined as (
    select
        c.topic, t.*, c.coverage, c.period, c.rate_allowed,
        case
            when c.coverage = 'available' then coalesce(n.observed_count, 0)
            -- Partial/out-of-scope observations can be shown as observed records,
            -- but cannot support a zero or a population-normalized rate.
            else n.observed_count
        end as record_count
    from {{ ref('stg_census_tracts') }} t
    join {{ ref('stg_tract_coverage') }} c using (geoid)
    left join totals n on n.geoid = c.geoid and n.topic = c.topic
)
select *,
    case when coverage = 'available' and rate_allowed and population > 0
         then record_count * 1000.0 / population end as rate_per_1000
from combined
