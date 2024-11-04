{{ config(
    enabled = var('claims_enabled', var('tuva_marts_enabled', False)) | as_bool
) }}

select *
from {{ ref('pharmacy__generic_available_list') }}