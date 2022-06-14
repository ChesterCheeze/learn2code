-- Prepair to create hdc and icd_code table by drop table first if exists for good measure.
DROP TABLE IF EXISTS hdc;
DROP TABLE IF EXISTS icd_code;

-- Create initial hdc table.
CREATE TABLE IF NOT EXISTS hdc
    (
        hospcode TEXT,
        pid TEXT,
        cid TEXT,
        birth TEXT,
        sex TEXT,
        nation TEXT,
        diagcode_opd TEXT,
        diagtype_opd TEXT,
        date_serv TEXT    
    );

-- Create icd_code table.
CREATE TABLE IF NOT EXISTS icd_code
    (
        diagcode TEXT,
        description_en TEXT,
        description_th TEXT,
        staging TEXT
    );

-- Set mode to csv for reading data from csv file.
.mode csv

-- Import data into hdc and icd_code table.
.import ./data/raw/df.csv hdc
.import ./data/raw/icd_code.csv icd_code

-- Delete header row.
DELETE FROM hdc WHERE hospcode = 'a.hospcode';
DELETE FROM icd_code WHERE diagcode = 'diagcode';


/* Calculate age by using birth and date_serv column and add age column to initial hdc table.
    - Move data in initial hdc table into temporary table call hdc_temp.
    - Drop initial hdc table.
    - Query data from hdc_temp and add age column.
    - Grouping age into age_group column.
*/
CREATE TABLE IF NOT EXISTS hdc_temp AS SELECT * FROM hdc;

DROP TABLE IF EXISTS hdc;

CREATE TABLE IF NOT EXISTS hdc AS 
    WITH age_calc AS 
        (
            SELECT 
                *,
                -- change from mid-year date to date_serv. 
                (JULIANDAY(date_serv)-JULIANDAY(birth))/365.25 AS age 
            FROM hdc_temp
        )
    SELECT 
        *,
        -- แบ่งเด็กที่อายุต่ำกว่า 5 เป็น 2 กลุ่ม คือ ไม่เกิน 2 ปี และ 2-4
        CASE
            WHEN age < 2.0 THEN 'less than 2'
            WHEN age >= 2.0 AND age < 5.0 THEN '2-4'
            WHEN age >= 5.0 AND age < 10.0 THEN '5-9'
            WHEN age >= 10.0 AND age < 15.0 THEN '10-14'
            WHEN age >= 15.0 AND age < 20.0 THEN '15-19'
            WHEN age >= 20.0 AND age < 25.0 THEN '20-24'
            WHEN age >= 25.0 AND age < 30.0 THEN '25-29'
            WHEN age >= 30.0 AND age < 35.0 THEN '30-34'
            WHEN age >= 35.0 AND age < 40.0 THEN '35-39'
            WHEN age >= 40.0 AND age < 45.0 THEN '40-44'
            WHEN age >= 45.0 AND age < 50.0 THEN '45-49'
            WHEN age >= 50.0 AND age < 55.0 THEN '50-54'
            WHEN age >= 55.0 AND age < 60.0 THEN '55-59'            
            WHEN age >= 60.0 AND age < 65.0 THEN '60-64'
            WHEN age >= 65.0 AND age < 70.0 THEN '65-69'
            WHEN age >= 70.0 AND age < 75.0 THEN '70-74'
            WHEN age >= 75.0 AND age < 80.0 THEN '75-79'
            WHEN age >= 80.0 AND age < 85.0 THEN '80-84'
            WHEN age >= 85.0 AND age < 90.0 THEN '85-89'
            WHEN age >= 90.0 AND age < 95.0 THEN '90-94'
            WHEN age >= 95.0 AND age < 100.0 THEN '95-99'
            WHEN age >= 100.0 THEN '100+'
            ELSE NULL
        END AS age_group      
    FROM 
        age_calc;

-- Drop hdc_temp table since new hdc table was created.
DROP TABLE IF EXISTS hdc_temp;

DROP TABLE IF EXISTS diag_type;

CREATE TABLE IF NOT EXISTS diag_type
    (
        diagtype_id TEXT,
        diagtype_des TEXT
    );

INSERT INTO diag_type (diagtype_id, diagtype_des)
VALUES
(1, 'PRINCIPLE DX (การวินิจฉัยโรคหลัก)'),
(2, 'CO-MORBIDITY(การวินิจฉัยโรคร่วม)'),
(3, 'COMPLICATION(การวินิจฉัยโรคแทรก)'),
(4, 'OTHER (อื่น ๆ)'),
(5, 'EXTERNAL CAUSE (สาเหตุภายนอก)'),
(6, 'Additional Code (รหัสเสริม)'),
(7, 'Morphology Code (รหัสเกี่ยวกับเนื้องอก)');

