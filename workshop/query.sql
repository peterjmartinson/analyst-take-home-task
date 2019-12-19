-- Cohort
SELECT DISTINCT
  patients.id as patient_id
, patients.birthdate
, patients.last
, patients.first
, encounters.id as encounter_id
, encounters.start
, TRUNC( (encounters.start - patients.birthdate) / 365.24 ) AS age_at_encounter
FROM
  encounters
  INNER JOIN patients
    ON patients.id = encounters.patient
WHERE encounters.reasoncode = '55680006'
  AND encounters.start > '1999-07-15'
  AND TRUNC( (encounters.start - patients.birthdate) / 365.24 ) between 18 and 35
