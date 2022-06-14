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

-- Exclude data where age over 100 since the data may not valid.
WITH table1 AS 
    (
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
    )
SELECT COUNT(DISTINCT(unique_id)) AS 'number of patient'
FROM table1;


-- from unique 30218 divide into 3 group 1.Principle Dx (diagtype = 1) 2.Co-morbid (diagtype = 2) 3.Other (diagtype = 4)

