{{ config(
    enabled = var('clinical_enabled', False)
) }}

select
      m.data_source
    , coalesce(m.encounter_start_date,cast('1900-01-01' as date)) as source_date
    , 'ENCOUNTER' as table_name
    , 'Encounter ID' as drill_down_key
    , coalesce(encounter_id, 'NULL') as drill_down_value
    , 'DISCHARGE_DISPOSITION_DESCRIPTION' as field_name
    , case when m.discharge_disposition_description is not null then 'valid' else 'null' end as bucket_name
    , cast(null as {{ dbt.type_string() }}) as invalid_reason
    , cast(substring(discharge_disposition_description, 1, 255) as {{ dbt.type_string() }}) as field_value
    , '{{ var('tuva_last_run') }}' as tuva_last_run
from {{ ref('encounter') }} as m
