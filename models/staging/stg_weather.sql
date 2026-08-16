-- GHCN-Daily observations for the Las Vegas airport station. Source temperatures
-- are in tenths of a degree Celsius and precip in tenths of a millimetre; we
-- convert to Fahrenheit / millimetres here.

with source as (
    select * from {{ source('raw', 'weather') }}
)

select
    try_cast("DATE" as date)                        as observed_date,
    round(try_cast("TMAX" as double) / 10 * 9 / 5 + 32, 1) as tmax_f,
    round(try_cast("TMIN" as double) / 10 * 9 / 5 + 32, 1) as tmin_f,
    round(try_cast("TAVG" as double) / 10 * 9 / 5 + 32, 1) as tavg_f,
    round(try_cast("PRCP" as double) / 10, 1)       as precip_mm
from source
where try_cast("DATE" as date) is not null
