WITH overdose_encounter AS
(
SELECT
  patients.id        AS patient_id
, encounters.id      AS encounter_id
, encounters.start   AS hospital_encounter_date
, encounters.stop    AS hospital_discharge_date
, TRUNC( (encounters.start - patients.birthdate) / 365.24 ) AS age_at_visit
, CASE
    WHEN patients.deathdate IS NOT NULL
    THEN 1
    ELSE 0
  END AS is_deceased
, CASE
    WHEN patients.deathdate::DATE = encounters.stop::DATE -- Assuming discharge date = inpatient death date
    THEN '1' -- Must be a varchar due to 'N/A' below
    ELSE '0'
  END AS death_at_visit_ind
, active_medications.code AS active_med_code
, CASE
    WHEN active_medications.code IN (316049, 406022, 429503)
    THEN 1
    ELSE 0
  END AS is_opioid
FROM
  encounters
  INNER JOIN patients
    ON patients.id = encounters.patient
  LEFT OUTER JOIN medications AS active_medications
    ON active_medications.patient = patients.id
    AND active_medications.start <= encounters.start
    AND
    (
      active_medications.stop IS NULL
      or
      active_medications.stop >= encounters.start
    )
WHERE encounters.reasoncode = '55680006' -- Drug overdose
  AND encounters.start > '1999-07-15'
  AND TRUNC( (encounters.start - patients.birthdate) / 365.24 ) between 18 and 35
),
readmissions AS
(
SELECT
  overdose_encounter.encounter_id
, encounters.id AS readmission_encounter_id
, encounters.start
, CASE
    WHEN TRUNC(encounters.start - overdose_encounter.hospital_discharge_date) <= 30
    THEN 1
    ELSE 0
  END AS thirty_day_readmission
, CASE
    WHEN TRUNC(encounters.start - overdose_encounter.hospital_discharge_date) <= 90
    THEN 1
    ELSE 0
  END AS ninety_day_readmission
, DENSE_RANK() OVER (PARTITION BY overdose_encounter.patient_id, overdose_encounter.encounter_id ORDER BY encounters.start ASC) AS sort
FROM
  overdose_encounter
  INNER JOIN encounters
    ON encounters.patient = overdose_encounter.patient_id
WHERE encounters.reasoncode = '55680006' -- Drug overdose
  AND TRUNC(encounters.start - overdose_encounter.hospital_discharge_date) between 0 and 90
)
SELECT DISTINCT
  overdose_encounter.patient_id
, overdose_encounter.encounter_id
, overdose_encounter.hospital_encounter_date
, overdose_encounter.age_at_visit
, CASE
    WHEN overdose_encounter.is_deceased = 0
    THEN 'N/A'
    ELSE overdose_encounter.death_at_visit_ind
  END AS death_at_visit_ind
, COUNT(DISTINCT overdose_encounter.active_med_code) AS count_current_meds
, MAX(overdose_encounter.is_opioid)                  AS current_opioid_ind
, CASE
    WHEN readmissions.encounter_id IS NULL
    THEN 0
    ELSE MAX(readmissions.ninety_day_readmission)
  END AS readmission_90_day_ind
, CASE
    WHEN readmissions.encounter_id IS NULL
    THEN 0
    ELSE MAX(readmissions.thirty_day_readmission)
  END AS readmission_30_day_ind
, CASE
    WHEN readmissions.encounter_id IS NULL
    THEN 'N/A'
    ELSE TO_CHAR(first_readmission.start, 'YYYY-MM-DD')
  END AS first_readmission_date
-- , first_readmission.start                            AS first_readmission_date
FROM
  overdose_encounter
  LEFT OUTER JOIN readmissions
    ON readmissions.encounter_id = overdose_encounter.encounter_id
  LEFT OUTER JOIN readmissions AS first_readmission
    ON first_readmission.encounter_id = overdose_encounter.encounter_id
    AND first_readmission.sort = 1
GROUP BY
  overdose_encounter.patient_id
, overdose_encounter.encounter_id
, overdose_encounter.hospital_encounter_date
, overdose_encounter.age_at_visit
, overdose_encounter.is_deceased
, overdose_encounter.death_at_visit_ind
, readmissions.encounter_id
, first_readmission.start
ORDER BY
  overdose_encounter.patient_id
, overdose_encounter.encounter_id
;
