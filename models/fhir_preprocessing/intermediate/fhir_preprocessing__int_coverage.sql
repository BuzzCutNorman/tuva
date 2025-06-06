{{ config(
     enabled = var('fhir_preprocessing_enabled',False) | as_bool
   )
}}
with base as (

    select
          person_id as patient_internal_id
        /* create hash due to FHIR limit of 64 characters for max length of strings */
        , {{ dbt_utils.generate_surrogate_key(['eligibility_id']) }} as resource_internal_id
        , payer as organization_name
        , {{ quote_column('plan') }} as coverage_plan
        , payer_type
        , enrollment_start_date as coverage_period_start
        , enrollment_end_date as coverage_period_end
        , coalesce(subscriber_relation,'self') as coverage_relationship
        , 'active' as coverage_status
        , coalesce(subscriber_id,member_id) as coverage_subscriber_id
        , data_source
    from {{ ref('fhir_preprocessing__stg_core__eligibility') }}

)

/* Map to standardized codes for product type */
, add_product as (

    select
          patient_internal_id
        , resource_internal_id
        , organization_name
        , coverage_plan
        , payer_type
        , coverage_period_start
        , coverage_period_end
        , coverage_relationship
        , coverage_status
        , coverage_subscriber_id
        , data_source
        , case
            when lower(payer_type) like '%commercial%' then 'PPO'
            when lower(payer_type) like '%self%' then 'PPO'
            when lower(payer_type) like '%medicare%' then 'MCR'
            when lower(payer_type) like '%medicaid%' then 'MCD'
            when lower(coverage_plan) like '%pos&' then 'POS'
            when lower(coverage_plan) like '%cep%' then 'CEP'
            when lower(coverage_plan) like '%hmo%' then 'HMO'
            when lower(coverage_plan) like '%MP%' then 'MP'
            when lower(coverage_plan) like '%MC%' then 'MC'
            when lower(coverage_plan) like '%SN1%' then 'SN1'
            when lower(coverage_plan) like '%SN2%' then 'SN2'
            when lower(coverage_plan) like '%SN3%' then 'SN3'
            when lower(coverage_plan) like '%MCS%' then 'MCS'
            when lower(coverage_plan) like '%MMP%' then 'MMP'
            when lower(coverage_plan) like '%MDE%' then 'MDE'
            when lower(coverage_plan) like '%MD%' then 'MD'
            when lower(coverage_plan) like '%MLI%' then 'MLI'
            when lower(coverage_plan) like '%MRB%' then 'MRB'
            when lower(coverage_plan) like '%MMO%' then 'MMO'
            when lower(coverage_plan) like '%MOS%' then 'MOS'
            when lower(coverage_plan) like '%MPO%' then 'MPO'
            when lower(coverage_plan) like '%MEP%' then 'MEP'
          end as coverage_type_product
    from base

)

select
      patient_internal_id
    , resource_internal_id
    , organization_name
    , coverage_plan
    , coverage_period_start
    , coverage_period_end
    , coverage_relationship
    , coverage_status
    , coverage_subscriber_id
    , data_source
    , coverage_type_product
from add_product
