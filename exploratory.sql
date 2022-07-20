-- Exploratory
.echo on
.width
.header on
.mode box
.output output.txt

.print "Select 5 rows from hdc table."\n

SELECT * FROM opd LIMIT 5;

.print \n

.print "Explore patient's age." \n

SELECT MIN(age), MAX(age), AVG(age)
FROM opd;

SELECT * FROM opd WHERE age < 2 ORDER BY age;

SELECT *
FROM opd
WHERE age >100.0
GROUP BY diagtype_opd, pid
;

.print "Select all data in icd_code table." \n

SELECT * FROM icd_code;

.print \n

.print "Explore all diagcode_opd data in hdc table." \n

SELECT diagcode_opd, COUNT(diagcode_opd) AS count 
FROM opd 
GROUP BY diagcode_opd;

.print \n


-- Update value in diagcode_opd 

UPDATE opd
SET diagcode_opd = 'A500'
WHERE diagcode_opd = 'A50.0';

UPDATE opd
SET diagcode_opd = 'A510'
WHERE diagcode_opd = 'A51.0';

UPDATE opd
SET diagcode_opd = 'A512'
WHERE diagcode_opd = 'A51.2';

UPDATE opd
SET diagcode_opd = 'A513'
WHERE diagcode_opd = 'A51.3';

UPDATE opd
SET diagcode_opd = 'A514'
WHERE diagcode_opd = 'A51.4';

UPDATE opd
SET diagcode_opd = 'A515'
WHERE diagcode_opd = 'A51.5';

UPDATE opd
SET diagcode_opd = 'A528'
WHERE diagcode_opd = 'A52.8';

UPDATE opd
SET diagcode_opd = 'A529'
WHERE diagcode_opd = 'A52.9';

UPDATE opd
SET diagcode_opd = 'A530'
WHERE diagcode_opd = 'A53.0';

UPDATE opd
SET diagcode_opd = 'A539'
WHERE diagcode_opd = 'A53.9';

.print "Test join hdc table with icd_code table to get staging of disease." \n

SELECT a.diagcode_opd, b.description_en, b.description_th, staging
FROM
    opd a LEFT JOIN icd_code b ON a.diagcode_opd = b.diagcode
GROUP BY a.diagcode_opd;

.print "Explore data in diagtype_opd column." \n

SELECT diagtype_opd, COUNT(diagtype_opd) AS count
FROM opd 
GROUP BY diagtype_opd;

.print \n

UPDATE opd
SET diagtype_opd = NULL
WHERE diagtype_opd = (
    SELECT diagtype_opd 
    FROM opd 
    GROUP BY diagtype_opd
    LIMIT 1
    OFFSET 1
);

UPDATE opd
SET diagtype_opd = NULL
WHERE diagtype_opd = '"';

UPDATE opd
SET diagtype_opd = NULL
WHERE diagtype_opd = '.';

UPDATE opd
SET diagtype_opd = NULL
WHERE diagtype_opd = '0';

UPDATE opd
SET diagtype_opd = NULL
WHERE diagtype_opd = '8';

UPDATE opd
SET diagtype_opd = NULL
WHERE diagtype_opd = 'z';

.print "After update." \n

SELECT diagtype_opd, COUNT(diagtype_opd) 
FROM opd 
GROUP BY diagtype_opd
;

.print "Test join diagtype_opd with diagtype to get diag type description." \n

SELECT a.diagtype_opd, b.diagtype_des, COUNT(a.diagtype_opd) AS count
FROM opd a LEFT JOIN diag_type b ON a.diagtype_opd = b.diagtype_id
GROUP BY a.diagtype_opd;

.print "Count number of patient visiting opd in 2021." \n
-- คนหนึ่งคน ใน 1 ปี สามารถมี diag code ได้หลายรหัส ในกรณี ควรจะนับอยู่ในรหัส diag code ที่รุนแรงที่สุด ดังนั้นจะต้องมีการเพิ่มลำดับความรุนแรงของรหัสวินิจฉัย
-- โดยจัดกลุ่มเป็น primary secondary tertiary

--[opd_view] Create abstract table over hdc which exclude record where age over 100 since the record may not valid.
CREATE VIEW IF NOT EXISTS opd_view AS 
    SELECT 
        (hospcode || pid) AS unique_id,
        cid, 
        birth, 
        sex, 
        nation, 
        diagcode_opd, 
        diagtype_opd, 
        date_serv, 
        age, 
        age_group
    FROM 
        opd
    WHERE
        age < 100.0 AND age >= 0.0 --Include 0 age person
;

-- Number of individual patient in hdc table.
SELECT COUNT(DISTINCT(unique_id)) AS 'number of patients' FROM opd_view;

-- Number of patients with principle diagnosis.
SELECT * FROM (
SELECT 
    (unique_id || '_' || diagtype_opd) AS u_dxt,
    *
FROM hdc_view
WHERE diagtype_opd IS NOT NULL
ORDER BY (unique_id || '_' || diagtype_opd)
)
GROUP BY u_dxt
ORDER BY u_dxt;

SELECT 
    unique_id,
    birth,
    sex,
    nation,
    MAX(age),
    COUNT(DISTINCT(date_serv)) AS n_days_opd_visit,
    COUNT(DISTINCT(diagcode_opd)) AS n_icd_dx
FROM opd_view
GROUP BY unique_id
ORDER BY COUNT(DISTINCT(date_serv)) DESC;


-- Create pivot table to show list of icd-10 code of patients.
WITH table1 AS (
SELECT 
    unique_id,
    CASE WHEN row_num = 1 THEN diagcode_opd ELSE NULL END AS first_pDx,
    CASE WHEN row_num = 2 THEN diagcode_opd ELSE NULL END AS second_pDx,
    CASE WHEN row_num = 3 THEN diagcode_opd ELSE NULL END AS third_pDx,
    CASE WHEN row_num = 4 THEN diagcode_opd ELSE NULL END AS fourth_pDx,
    CASE WHEN row_num = 5 THEN diagcode_opd ELSE NULL END AS fifth_pDx
FROM 
    (SELECT
    ROW_NUMBER() OVER(PARTITION BY unique_id ORDER BY date_serv) AS row_num, 
    unique_id,
    date_serv,
    diagtype_opd,
    diagcode_opd
FROM hdc_view
WHERE diagtype_opd = '1'
GROUP BY unique_id, diagcode_opd
ORDER BY unique_id)
)
SELECT
    unique_id,
    GROUP_CONCAT(first_pDx,';') f_list,
    GROUP_CONCAT(second_pDx,';') s_list,
    GROUP_CONCAT(third_pDx,';') t_list,
    GROUP_CONCAT(fourth_pDx,';') ft_list
FROM table1
GROUP BY unique_id
;

--Person view
CREATE VIEW IF NOT EXISTS person AS
    SELECT
        unique_id,
        cid,
        birth,
        sex,
        nation,
        MAX(age) AS age,
        age_group
    FROM opd_view
    GROUP BY unique_id;

SELECT * FROM person;

-- Dataset 1 
WITH table64 AS (
SELECT
    ('id' || p.unique_id) AS record_id,
    p.cid,
    p.birth,
    p.sex,
    p.nation,
    p.age,
    p.age_group,
    o.diagtype_opd,
    o.diagcode_opd,
    MAX(o.date_serv) AS latest
FROM
    person p JOIN opd_view o ON p.unique_id = o.unique_id
WHERE o.diagtype_opd = '1' AND p.nation = '99' 
GROUP BY o.unique_id, o.diagcode_opd
ORDER BY o.unique_id
)
SELECT 
    t.*,
    i.description_en,
    i.description_th,
    i.staging
FROM 
    table64 t LEFT JOIN icd_code i ON t.diagcode_opd = i.diagcode
WHERE STRFTIME('%Y',t.latest) = '2012'
;

--[Dataset 1] Individual record.
WITH table1 AS (
SELECT  
    ('id' || unique_id) AS individual,
    cid,
    birth,
    sex,
    nation,
    'opd' AS gr,
    diagcode_opd AS dx_code,
    diagtype_opd AS dx_type,
    date_serv AS date,
    age,
    age_group,
    STRFTIME('%Y', date_serv) AS year
FROM opd_view
GROUP BY unique_id
UNION ALL
SELECT 
    ('id' || a.unique_id) AS individual,
    a.cid,
    a.birth,
    a.sex,
    a.nation,
    'ipd' AS gr,
    a.diagcode_ipd AS dx_code,
    a.diagtype_ipd AS dx_type,
    DATE(a.datetime_admit) AS date,
    a.age,
    a.age_group,
    STRFTIME('%Y', datetime_admit) AS year
FROM ipd_view a
WHERE a.unique_id NOT IN (
    SELECT unique_id FROM opd_view GROUP BY unique_id
    )
GROUP BY a.unique_id)
SELECT * FROM table1
;


-------------------------------------------------------------------------
--IPD Section
SELECT MIN(age), MAX(age), AVG(age)
FROM ipd;

CREATE VIEW IF NOT EXISTS ipd_view AS 
    SELECT 
        (hospcode || pid) AS unique_id,
        cid, 
        birth, 
        sex, 
        nation, 
        diagcode_ipd, 
        diagtype_ipd, 
        datetime_admit, 
        age, 
        age_group
    FROM 
        ipd
    WHERE
        age < 100.0 AND age > 0.0
;

SELECT * FROM ipd_view;

WITH table64 AS (
SELECT
    ('id' || p.unique_id) AS record_id,
    p.cid,
    p.birth,
    p.sex,
    p.nation,
    p.age,
    p.age_group,
    o.diagtype_opd,
    o.diagcode_opd,
    MAX(o.date_serv) AS latest
FROM
    person p JOIN opd_view o ON p.unique_id = o.unique_id
WHERE o.diagtype_opd = '1' AND p.nation = '99' 
GROUP BY o.unique_id, o.diagcode_opd
ORDER BY o.unique_id
)
SELECT 
    t.*,
    i.description_en,
    i.description_th,
    i.staging
FROM 
    table64 t LEFT JOIN icd_code i ON t.diagcode_opd = i.diagcode
WHERE STRFTIME('%Y',t.latest) = '2012'
;


SELECT * FROM hdc_view WHERE unique_id = '11371004171' ORDER BY date_serv;

SELECT * FROM icd_code WHERE diagcode IN ('A528', 'A529', 'A539');

SELECT unique_id, birth, sex, nation, diagcode_opd, diagtype_opd
FROM hdc_view
WHERE unique_id = '11371004171';
-- from unique 30218 divide into 3 group 1.Principle Dx (diagtype = 1) 2.Co-morbid (diagtype = 2) 3.Other (diagtype = 4)


SELECT 
    icd_code.diagcode, 
    icd_code.description_en, 
    icd_code.description_th,
    COUNT(hdc_view.diagcode_opd)
FROM
    hdc_view LEFT JOIN icd_code ON hdc_view.diagcode_opd = icd_code.diagcode
WHERE hdc_view.diagtype_opd = '1'
GROUP BY icd_code.diagcode;


CREATE VIEW IF NOT EXISTS principle_dx AS
SELECT unique_id, COUNT(diagcode_opd) AS n_dx 
FROM
    (SELECT unique_id, diagcode_opd, COUNT(date_serv) AS n_opd
    FROM hdc_view
    WHERE diagtype_opd = '1'
    GROUP BY unique_id, diagcode_opd
    ORDER BY COUNT(date_serv) DESC, unique_id)
GROUP BY unique_id
ORDER BY COUNT(diagcode_opd);

/*
    Set of data 
    Row      1 2 3 4 5 6 7
    Value    a b c d e f g
    OFFSET   0 1 2 3 4 5 6
    -------------------------
    Modulo operator donoted by '%'
    Even number % 2 will return 0
    Odd number % 2 will return 1     
*/

SELECT MIN(n_dx) AS min FROM principle_dx;

SELECT MAX(n_dx) AS max FROM principle_dx;

WITH median_nDx AS (
    SELECT 
        ROW_NUMBER() OVER() AS row_num,
        n_dx
    FROM principle_dx
)
SELECT AVG(n_dx) AS median FROM (
SELECT n_dx
FROM median_nDx
LIMIT 2 - (SELECT COUNT(*) FROM median_nDx)%2
OFFSET (SELECT (COUNT(*)-1)/2 FROM median_nDx));

--Ranking
CREATE VIEW icd_view AS 
    WITH table1 AS (
        SELECT 
        *,
        CASE
            WHEN diagcode IN ('A500','A501','A502','A503','A504','A505','A506','A507','A509') THEN 'Congenital'
            WHEN diagcode IN ('A510', 'A511', 'A512', 'A513', 'A514', 'A515', 'A519', 'A520', 'A521', 'A522', 'A523', 'A527', 'A528', 'A529', 'A530', 'A539', 'I980', 'M031', 'N290') THEN 'Acquired'
            WHEN diagcode IN ('O981') THEN 'Syphilis complicating pregnancy'
            ELSE description_en
        END AS maingroup,
        CASE
            WHEN diagcode = 'A500' THEN 'Early symptomatic'
            WHEN diagcode = 'A501' THEN 'Early latent'
            WHEN diagcode = 'A504' THEN 'Neurosyphilis'
            WHEN diagcode IN ('A503', 'A505') THEN 'Late symptomatic'
            WHEN diagcode IN ('A506', 'A507') THEN 'Late latent'
            WHEN diagcode IN ('A502', 'A509') THEN 'Unspecified'
            WHEN diagcode IN ('A510', 'A511', 'A512') THEN 'Primary'
            WHEN diagcode IN ('A513', 'A514') THEN 'Secondary'
            WHEN diagcode IN ('A515', 'A519') THEN 'Early'
            WHEN diagcode IN ('A521', 'A522', 'A523') THEN 'Neurosyphilis'
            WHEN diagcode IN ('A527', 'A528', 'A529', 'A530') THEN 'Late'
            WHEN diagcode IN ('A520', 'I980', 'M031', 'N290') THEN 'Tertiary'
            WHEN diagcode IN ('A539') THEN 'Unspecified'
            ELSE description_en
        END AS subgroup
        FROM icd_code)
    SELECT 
    *,
    CASE
        WHEN subgroup LIKE 'Unspecified' THEN 1.0
        WHEN subgroup LIKE 'Primary' THEN 2.0
        WHEN subgroup LIKE 'Secondary' THEN 3.0
        WHEN subgroup LIKE 'Early%' THEN 4.0
        WHEN subgroup LIKE 'Late%' THEN 5.0
        WHEN subgroup LIKE 'Tertiary' THEN 6.0
        WHEN subgroup LIKE 'Neurosyphilis' THEN 7.0
        WHEN subgroup LIKE '%pregnancy%' THEN 4.0
        ELSE NULL
    END AS score
    FROM table1
;

/* [Dataset 2] combine opd and ipd record without exclude duplicated record
    then join data with icd code.
*/
WITH level2 AS (
WITH table1 AS (
    SELECT  
        ('id' || unique_id) AS individual,
        cid,
        birth,
        sex,
        nation,
        age,
        age_group,
        'opd' AS service_type,
        diagcode_opd AS dx_code,
        diagtype_opd AS dx_type,
        date_serv AS date_attend,
        STRFTIME('%Y', date_serv) AS year_attend
    FROM opd_view
UNION ALL
    SELECT 
        ('id' || a.unique_id) AS individual,
        a.cid,
        a.birth,
        a.sex,
        a.nation,
        a.age,
        a.age_group,
        'ipd' AS service_type,
        a.diagcode_ipd AS dx_code,
        a.diagtype_ipd AS dx_type,
        DATE(a.datetime_admit) AS date_attend,
        STRFTIME('%Y', datetime_admit) AS year_attend
    FROM ipd_view a
    WHERE a.unique_id NOT IN (
        SELECT unique_id FROM opd_view GROUP BY unique_id
        ) --Exclude all unique_id that already exist in opd_view.
)
SELECT 
a.*, b.description_en, b.description_th, b.staging, b.maingroup, b.subgroup, b.score 
FROM table1 a LEFT JOIN icd_view b ON a.dx_code = b.diagcode
--WHERE dx_type = '1'
GROUP BY individual, year_attend, dx_code
ORDER BY individual
)
SELECT
(individual || '_' || year_attend) AS record_id,
individual,
cid,
birth,
sex,
nation,
age,
age_group,
year_attend,
date_attend,
service_type,
dx_code,
dx_type,
description_en,
description_th,
staging,
maingroup,
subgroup,
MAX(score)
FROM level2
--WHERE nation = '99'
GROUP BY individual, year_attend
;