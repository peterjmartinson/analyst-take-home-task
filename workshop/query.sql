-- Cohort
SELECT DISTINCT
  patients.id as patient_id
, patients.birthdate
, patients.last
, patients.first
, encounters.id as encounter_id
, encounters.start
, TRUNC( (encounters.start - patients.birthdate) / 365.24 ) AS age_at_encounter
, encounters.reasoncode
, encounters.reasondescription
FROM
  encounters
  INNER JOIN patients
    ON patients.id = encounters.patient
WHERE encounters.reasoncode = '55680006'
  AND encounters.start > '1999-07-15'
  AND TRUNC( (encounters.start - patients.birthdate) / 365.24 ) between 18 and 35



-- Additional Fields
WITH overdose_encounter AS
(
SELECT DISTINCT
  patients.id as patient_id
, patients.birthdate
, patients.deathdate
, patients.last AS patient_lastname
, patients.first AS patient_firstname
, encounters.id as encounter_id
, encounters.start AS hospital_encounter_date
, encounters.stop AS hospital_discharge_date
, TRUNC( (encounters.start - patients.birthdate) / 365.24 ) AS age_at_visit
, encounters.reasoncode
, encounters.reasondescription
, CASE
    WHEN patients.deathdate::DATE = encounters.stop::DATE
    THEN 1
    ELSE 0
  END AS death_at_visit_ind
, active_medications.code AS active_med_code
, active_medications.description AS active_med_description
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
    AND ( active_medications.stop IS NULL or active_medications.stop >= encounters.start)
WHERE encounters.reasoncode = '55680006'
  AND encounters.start > '1999-07-15'
  AND TRUNC( (encounters.start - patients.birthdate) / 365.24 ) between 18 and 35
)
SELECT DISTINCT
  overdose_encounter.patient_id
, overdose_encounter.encounter_id
, overdose_encounter.hospital_encounter_date
, overdose_encounter.age_at_visit
, overdose_encounter.death_at_visit_ind
, COUNT(DISTINCT overdose_encounter.active_med_code) AS count_current_meds
, MAX(overdose_encounter.is_opioid) AS current_opioid_ind
-- , overdose_encounter.count_current_meds
, '' as CURRENT_OPIOID_IND
, '' as READMISSION_90_DAY_IND
, '' as READMISSION_30_DAY_IND
, '' as FIRST_READMISSION_DATE
FROM
  overdose_encounter
GROUP BY
  overdose_encounter.patient_id
, overdose_encounter.encounter_id
, overdose_encounter.hospital_encounter_date
, overdose_encounter.age_at_visit
, overdose_encounter.death_at_visit_ind
ORDER BY
  patient_id
