-- Exploratory
.echo on
.width
.header on
.mode box
.output output.txt

.print "Select 5 rows from hdc table."\n

SELECT * FROM hdc LIMIT 5;

.print \n

.print "Explore patient's age." \n

SELECT MIN(age), MAX(age), AVG(age)
FROM hdc;

SELECT *
FROM hdc
WHERE age >100.0;

.print "Select all data in icd_code table." \n

SELECT * FROM icd_code;

.print \n

.print "Explore all diagcode_opd data in hdc table." \n

SELECT diagcode_opd, COUNT(diagcode_opd) AS count 
FROM hdc 
GROUP BY diagcode_opd;

.print \n

.print "Count number of diag code in hdc table." \n

SELECT diagcode_opd, COUNT(diagcode_opd) AS count
FROM hdc
GROUP BY diagcode_opd;

.print \n

UPDATE hdc
SET diagcode_opd = 'A500'
WHERE diagcode_opd = 'A50.0';

UPDATE hdc
SET diagcode_opd = 'A510'
WHERE diagcode_opd = 'A51.0';

UPDATE hdc
SET diagcode_opd = 'A513'
WHERE diagcode_opd = 'A51.3';

UPDATE hdc
SET diagcode_opd = 'A514'
WHERE diagcode_opd = 'A51.4';

UPDATE hdc
SET diagcode_opd = 'A515'
WHERE diagcode_opd = 'A51.5';

UPDATE hdc
SET diagcode_opd = 'A539'
WHERE diagcode_opd = 'A53.9';

.print "Test join hdc table with icd_code table to get staging of disease." \n

SELECT a.diagcode_opd, b.description_en, b.description_th, staging
FROM
    hdc a LEFT JOIN icd_code b ON a.diagcode_opd = b.diagcode
GROUP BY a.diagcode_opd;

.print "Explore data in diagtype_opd column." \n

SELECT diagtype_opd, COUNT(diagtype_opd) AS count
FROM hdc 
GROUP BY diagtype_opd;

.print \n

UPDATE hdc
SET diagtype_opd = NULL
WHERE diagtype_opd = '"';

UPDATE hdc
SET diagtype_opd = NULL
WHERE diagtype_opd = '0';

UPDATE hdc
SET diagtype_opd = NULL
WHERE diagtype_opd = 'z';

.print "After update." \n

SELECT diagtype_opd, COUNT(diagtype_opd) 
FROM hdc 
GROUP BY diagtype_opd;

.print "Test join diagtype_opd with diagtype to get diag type description." \n

SELECT a.diagtype_opd, b.description, COUNT(a.diagtype_opd) AS count
FROM hdc a LEFT JOIN diag_type b ON a.diagtype_opd = b.diagtype
GROUP BY a.diagtype_opd;

.print "Count number of patient visiting opd in 2021." \n
-- คนหนึ่งคน ใน 1 ปี สามารถมี diag code ได้หลายรหัส ในกรณี ควรจะนับอยู่ในรหัส diag code ที่รุนแรงที่สุด ดังนั้นจะต้องมีการเพิ่มลำดับความรุนแรงของรหัสวินิจฉัย
-- โดยจัดกลุ่มเป็น primary secondary tertiary

--Create abstract table over hdc which exclude record where age over 100 since the record may not valid.
CREATE VIEW IF NOT EXISTS hdc_view AS 
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
        hdc
    WHERE
        age < 100.0
;

-- Number of individual patient in hdc table.
SELECT COUNT(DISTINCT(unique_id)) AS 'number of patients' FROM hdc_view;

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
FROM hdc_view
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

CREATE VIEW IF NOT EXISTS person AS
    SELECT
        unique_id,
        cid,
        birth,
        sex,
        nation,
        MAX(age) AS age,
        age_group
    FROM hdc_view
    GROUP BY unique_id;

-- Main data
WITH table1 AS (
SELECT
    p.unique_id,
    p.cid,
    p.birth,
    p.sex,
    p.nation,
    p.age,
    p.age_group,
    h.diagtype_opd,
    h.diagcode_opd
FROM
    person p JOIN hdc_view h ON p.unique_id = h.unique_id
WHERE h.diagtype_opd = '1' AND p.nation = '99' 
GROUP BY h.unique_id, h.diagcode_opd
ORDER BY h.unique_id
)
SELECT 
    t.*,
    i.description_en,
    i.description_th,
    i.staging
FROM 
    table1 t LEFT JOIN icd_code i ON t.diagcode_opd = i.diagcode 
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
    Value    1 2 3 4 5 6 7
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

