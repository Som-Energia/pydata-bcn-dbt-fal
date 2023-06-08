{{ config(materialized="incremental") }}


with forecast_ree as (select * from {{ ref("forecast_ree") }})
select *
from forecast_ree

{% if is_incremental() %}

    -- this filter will only be applied on an incremental run
    where forecasted_at > (select max(forecasted_at) from {{ this }})

{% endif %}
