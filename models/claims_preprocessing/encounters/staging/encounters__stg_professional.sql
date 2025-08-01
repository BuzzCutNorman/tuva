{{ config(
     enabled = var('claims_preprocessing_enabled',var('claims_enabled',var('tuva_marts_enabled',False))) | as_bool
   )
}}

select
  claim_id
, claim_line_number
, claim_line_id
, service_type
, data_source
, '{{ var('tuva_last_run') }}' as tuva_last_run
from {{ ref('service_category__stg_professional') }} as a
