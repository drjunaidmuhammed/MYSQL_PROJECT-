USE FDA_PROJECT;
SELECT * FROM APPDOC;
SELECT * FROM APPDOCTYPE_LOOKUP;
SELECT * FROM APPLICATION;
SELECT * FROM chemtypelookup;
SELECT * FROM regactiondate;
SELECT * FROM doctype_lookup;
SELECT * FROM product;
select * from product_tecode;
select * from reviewclass_lookup;


-- Task 1: Identifying Approval Trends --
-- 1.1To determine the number of drugs approved each year --

select year(actiondate) as APPROVAL_YEAR, COUNT(APPLNO) as num_drugs_approved FROM regactiondate
where actiontype = 'AP' GROUP BY APPROVAL_YEAR;

/* 1.2  Identify the top three years that got the highest and lowest approvals, in descending and 
ascending order, respectively. */

-- DESCENDING LIMIT 3 --

select year(actiondate) as APPROVAL_YEAR, COUNT(APPLNO) as num_drugs_approved FROM regactiondate
where actiontype = 'AP' GROUP BY APPROVAL_YEAR ORDER BY num_drugs_approved DESC LIMIT 3;

-- ASCENDING LIMIT 3 --

select year(actiondate) as APPROVAL_YEAR, COUNT(APPLNO) as num_drugs_approved FROM regactiondate
where actiontype = 'AP' GROUP BY APPROVAL_YEAR ORDER BY num_drugs_approved ASC LIMIT 4;

-- 1.2 COMBINED with sorting order -- 

WITH YearlyApprovals AS (
    SELECT YEAR(actiondate) AS approval_year, COUNT(*) AS num_drugs_approved
    FROM regactiondate WHERE actiontype = 'Ap' GROUP BY approval_year)

SELECT approval_year, num_drugs_approved, 'Descending' AS sorting_order

FROM (
    SELECT approval_year, num_drugs_approved
    FROM YearlyApprovals
    ORDER BY num_drugs_approved DESC
    LIMIT 3
) AS TopThree

UNION

SELECT approval_year, num_drugs_approved, 'Ascending' AS sorting_order
FROM (
    SELECT approval_year, num_drugs_approved
    FROM YearlyApprovals
    ORDER BY num_drugs_approved ASC
    LIMIT 3
) AS BottomThree;

-- 1.3  approval trends over the years based on sponsors -- 

WITH YearlyApprovals AS (
    SELECT
        YEAR(r.actiondate) AS approval_year,
        a.sponsorapplicant,
        COUNT(*) AS num_drugs_approved
    FROM
        regactiondate r
    JOIN
        application a ON r.applno = a.applno
    WHERE
        r.actiontype = 'ap'
    GROUP BY
        approval_year, a.sponsorapplicant
)

SELECT
    approval_year,
    sponsorapplicant,
    num_drugs_approved
FROM
    YearlyApprovals
ORDER BY
    approval_year, num_drugs_approved DESC;

-- task 2 -- 
-- 2.1  Group products based on MarketingStatus. --

 SELECT
    p.productno,
    p.applno,
    p.productmktstatus,
    a.sponsorapplicant,
    r.actiontype,
    YEAR(r.actiondate) AS approval_year
FROM
    product p
JOIN
    application a ON p.applno = a.applno
JOIN
    regactiondate r ON p.applno = r.applno
WHERE
    r.actiontype = 'ap'  -- Consider only approved products
ORDER BY
    p.productmktstatus, p.productno;


-- 2.2  total number of applications for each MarketingStatus year-wise after the year 2010.-- 

SELECT
    YEAR(r.actiondate) AS approval_year,
    p.productmktstatus,
    COUNT(*) AS total_applications
FROM
    product p
JOIN
    regactiondate r ON p.applno = r.applno
WHERE
    YEAR(r.actiondate) > 2010
GROUP BY
    approval_year, p.productmktstatus;
    
    
-- 2.3  top MarketingStatus with the maximum number of applications and analyze its trend over time.---

 WITH TopMarketingStatus AS (
    SELECT
        p.productmktstatus,
        COUNT(*) AS total_applications
    FROM
        product p
    GROUP BY
        p.productmktstatus
    ORDER BY
        total_applications DESC limit 1)

SELECT
    YEAR(r.actiondate) AS approval_year,
    p.productmktstatus,
    COUNT(*) AS total_applications
FROM product p
JOIN regactiondate r ON p.applno = r.applno
JOIN
    TopMarketingStatus tms ON p.productmktstatus = tms.productmktstatus
GROUP BY
    approval_year, p.productmktstatus
ORDER BY
    approval_year;
    
 -- task 3 -- 
 -- 3.1 Categorize Products by dosage form and analyze their distribution --

 SELECT 
    p.dosage AS dosage_form,
    COUNT(*) AS product_count
FROM
    product p
GROUP BY
    p.dosage
ORDER BY
    product_count DESC;
    
    
    -- trail error  --
    SELECT
    p.dosage AS dosage_form,
    COUNT(*) AS product_count
FROM
    product p
ORDER BY
    product_count DESC;

-- 3.2Calculate the total number of approvals for each dosage form and identify the most successful forms. --
 
SELECT
    YEAR(r.actiondate) AS approval_year,
    p.dosage AS dosage_form,
    COUNT(*) AS total_approvals
FROM
    product p
JOIN
    regactiondate r ON p.applno = r.applno
WHERE
    r.actiontype = 'ap' -- Consider only approved products
GROUP BY
    p.dosage, approval_year
ORDER BY
    total_approvals DESC;
 -- 3.3 and 3.2 are same  ---
 

-- task 4 --
-- 4.1 Analyze drug approvals based on therapeutic evaluation code (TE_Code) --

WITH TopTherapeuticCodes AS (
    SELECT
        pt.TECODE,
        COUNT(pt.tecode) AS total_approvals
    FROM
        product_tecode pt
    JOIN
        regactiondate r ON pt.applno = r.applno
    WHERE
        r.actiontype = 'ap' -- Consider only approved products
    GROUP BY
        pt.TECODE
    ORDER BY
        total_approvals)  
        

SELECT
    ttc.TECODE,
    ttc.total_approvals
  FROM
    TopTherapeuticCodes ttc
JOIN
    product_tecode pt ON ttc.TECODE = pt.TECODE
ORDER BY
    ttc.total_approvals DESC;


-- distinct rows only 4.1 -- 
WITH TopTherapeuticCodes AS (
    SELECT
        pt.TECODE,
        COUNT(pt.tecode) AS total_approvals
    FROM
        product_tecode pt
    JOIN
        regactiondate r ON pt.applno = r.applno
    WHERE
        r.actiontype = 'ap' -- Consider only approved products
    GROUP BY
        pt.TECODE
    ORDER BY
        total_approvals DESC )

SELECT distinct
    ttc.TECODE,
    ttc.total_approvals
   FROM
    TopTherapeuticCodes ttc
JOIN
    product_tecode pt ON ttc.TECODE = pt.TECODE
ORDER BY
    ttc.total_approvals DESC;
    
    
    -- 4.2Determine the therapeutic evaluation code (TE_Code) with the highest number of Approvals in each year. --
WITH TopTECodesPerYear AS (
    SELECT
        YEAR(r.actiondate) AS approval_year,
        pt.TECode,
        COUNT(*) AS total_approvals
    FROM
        regactiondate r
    JOIN
        product_tecode pt ON r.applno = pt.applno
    WHERE
        r.actiontype = 'ap'  -- Consider only approved products
    GROUP BY
        approval_year, pt.TECode
    ORDER BY
        approval_year, total_approvals DESC)

SELECT
    approval_year,
    TECode,
    total_approvals
FROM
    TopTECodesPerYear
GROUP BY
    approval_year
ORDER BY
    approval_year, total_approvals DESC;
    
    -- trail 2 --
    WITH TopTECodesPerYear AS (
    SELECT
        YEAR(r.actiondate) AS approval_year,
        pt.tecode,
        COUNT(*) AS total_approvals
    FROM
        regactiondate r
    JOIN
        product_tecode pt ON r.applno = pt.applno
    WHERE
        r.actiontype = 'ap'  -- Consider only approved products
    GROUP BY
        approval_year, pt.tecode
    ORDER BY
        approval_year, total_approvals DESC)

SELECT
    approval_year,
    tecode,
    MAX(total_approvals) AS highest_approvals
FROM
    TopTECodesPerYear
GROUP BY
    approval_year, tecode
ORDER BY
    approval_year, highest_approvals DESC;



-- that's it thank you -------