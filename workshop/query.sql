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
),
readmissions AS
(
SELECT
  overdose_encounter.encounter_id
, encounters.id AS readmission_encounter_id
, encounters.start
, encounters.stop
, TRUNC(encounters.start - overdose_encounter.hospital_discharge_date) AS readmit_days
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
, dense_rank() over (partition by overdose_encounter.patient_id, overdose_encounter.encounter_id order by encounters.start) as SORT
FROM
  overdose_encounter
  INNER JOIN encounters
    ON encounters.patient = overdose_encounter.patient_id
WHERE encounters.start >= overdose_encounter.hospital_discharge_date
)
SELECT DISTINCT
  overdose_encounter.patient_id
, overdose_encounter.encounter_id
, overdose_encounter.hospital_encounter_date
, overdose_encounter.age_at_visit
, overdose_encounter.death_at_visit_ind
, COUNT(DISTINCT overdose_encounter.active_med_code) AS count_current_meds
, MAX(overdose_encounter.is_opioid) AS current_opioid_ind
, MAX(readmissions.ninety_day_readmission) AS readmission_90_day_ind
, MAX(readmissions.thirty_day_readmission) AS readmission_30_day_ind
, first_readmission.start AS first_readmission_date
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
, overdose_encounter.death_at_visit_ind
, first_readmission.start
ORDER BY
  patient_id
