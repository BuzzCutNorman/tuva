{{ config(
     enabled = var('claims_preprocessing_enabled',var('claims_enabled',var('tuva_marts_enabled',False)))
 | as_bool,
     tags = ['dqi', 'tuva_dqi_sev_2', 'dqi_service_categories', 'dqi_ccsr', 'dqi_cms_chronic_conditions',
            'dqi_tuva_chronic_conditions', 'dqi_cms_hccs', 'dqi_ed_classification',
            'dqi_financial_pmpm', 'dqi_quality_measures', 'dqi_readmission'],
     severity = 'warn'
   )
}}

with eligibility as (
    select distinct
        person_id
        , data_source
    from {{ ref('input_layer__eligibility') }}
)

, medical_claims as (
    select distinct
        person_id
        , data_source
    from {{ ref('input_layer__medical_claim') }}
)

, mc_records_check as (
    select
        data_source
        , count(*) as n_rows
    from medical_claims
    group by data_source
)

, elig_records_check as (
    select
        data_source
        , count(*) as n_rows
    from eligibility
    group by data_source
)

, overlap_check as (
    select
        m.data_source
        , count(e.person_id) as n_rows
    from medical_claims as m
    left outer join eligibility as e
    on m.person_id = e.person_id
    and m.data_source = e.data_source
    group by m.data_source
)

, final as (
    select
        oc.data_source
        , oc.n_rows as n_overlapping_records
        , case when (mc.n_rows = 0 or mc.n_rows is null) then 1 else 0 end as is_mc_empty
        , case when (ec.n_rows = 0 or ec.n_rows is null) then 1 else 0 end as is_elig_empty
    from overlap_check as oc
    left outer join mc_records_check as mc
    on oc.data_source = mc.data_source
    left outer join elig_records_check as ec
    on oc.data_source = ec.data_source
)

select
    data_source
    , n_overlapping_records
from final
where not (is_mc_empty = 1 or is_elig_empty = 1)
and n_overlapping_records = 0
