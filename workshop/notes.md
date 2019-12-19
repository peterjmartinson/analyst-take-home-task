Largest table is `procedures`, with over 300000 rows

1. The patient’s visit is an encounter for drug overdose
ENCOUNTERS.REASONDESCRIPTION is the diagnosis
ENCOUNTERS.REASONCODE is the SNOMED-CT diagnosis code

ENCOUNTERS.REASONDESCRIPTION = 'Drug overdose'
ENCOUNTERS.REASONCODE = '55680006'

2. The hospital encounter occurs after July 15, 1999
ENCOUNTERS.START > '1999-07-15'

3. The patient’s age at time of encounter is between 18 and 35 (Patient is considered to be 35 until turning 36)
AND TRUNC( (encounters.start - patients.birthdate) / 365.24 ) between 18 and 35

## Opioids

316049 Hydromorphone 325Mg
429503 Fentanyl – 100 MCG
406022 Oxycodone-acetaminophen 100 Ml


