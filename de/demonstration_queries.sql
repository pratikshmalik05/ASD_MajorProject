-- ============================================================================
-- Data Engineering (DE) Major Project: DBMS Viva Demonstration SQL Script
-- Project: Virtual House Visualizer and Cost Estimator
-- Target Database: PostgreSQL
-- Author: Pratiksh Malik
-- ============================================================================

-- ----------------------------------------------------------------------------
-- SECTION 1: VERIFY SCHEMA & SAMPLE PROJECT DATA (For Question 1 & 2)
-- ----------------------------------------------------------------------------

-- 1.1 View Master States and Base Construction Rates
SELECT id, name, "baseRate" AS "baseRate_INR_per_sqft" 
FROM "State" 
ORDER BY id ASC;

-- 1.2 View Standardized House Types and Floor Areas
SELECT id, code, "areaSqFt" 
FROM "HouseType" 
ORDER BY id ASC;

-- 1.3 View Materials and Calibrated Cost Multipliers
SELECT id, category, code, multiplier 
FROM "Material" 
ORDER BY category DESC, id ASC;

-- 1.4 View User Identity Records (Protected with Bcrypt Hashes)
SELECT id, name, email, "createdAt" 
FROM "User" 
ORDER BY id DESC 
LIMIT 5;


-- ----------------------------------------------------------------------------
-- SECTION 2: CROSS-TABLE JOIN DEMONSTRATION (For Question 2)
-- Calculates dynamic total estimate and stage breakdown in a single SQL query
-- ----------------------------------------------------------------------------

SELECT 
    h.code AS house_model,
    h."areaSqFt" AS plinth_area_sqft,
    s.name AS state_jurisdiction,
    s."baseRate" AS base_sqft_rate_inr,
    mw.code AS wall_material,
    mw.multiplier AS wall_multiplier,
    mr.code AS roof_material,
    mr.multiplier AS roof_multiplier,
    -- Total Construction Cost:
    ROUND(h."areaSqFt" * s."baseRate" * mw.multiplier * mr.multiplier) AS total_estimate_inr,
    -- PMAY-G Statutory Stage Disbursements:
    ROUND((h."areaSqFt" * s."baseRate" * mw.multiplier * mr.multiplier) * 0.20) AS stage_foundation_20pct,
    ROUND((h."areaSqFt" * s."baseRate" * mw.multiplier * mr.multiplier) * 0.35) AS stage_walls_35pct,
    ROUND((h."areaSqFt" * s."baseRate" * mw.multiplier * mr.multiplier) * 0.25) AS stage_roof_25pct,
    ROUND((h."areaSqFt" * s."baseRate" * mw.multiplier * mr.multiplier) * 0.20) AS stage_finishing_20pct
FROM "HouseType" h
CROSS JOIN "State" s
JOIN "Material" mw ON mw.category = 'wall' AND mw.code = 'brick'
JOIN "Material" mr ON mr.category = 'roof' AND mr.code = 'rcc'
WHERE h.code = '2BHK' 
  AND s.name = 'Chhattisgarh';


-- ----------------------------------------------------------------------------
-- SECTION 3: CONSTRAINT DEMONSTRATIONS - LIVE ERROR REJECTION (For Question 4)
-- Run these queries live on screen to demonstrate active constraint rejection!
-- ----------------------------------------------------------------------------

-- TEST 3.1: Duplicate Unique Key Violation on User Email
-- Expected Result: ERROR 23505: duplicate key value violates unique constraint "User_email_key"
DO $$
BEGIN
    INSERT INTO "User" (name, email, "passwordHash", "updatedAt")
    VALUES ('Duplicate Test User', 'test@pmayg.gov.in', '$2b$12$eX4mpL3h45hP455w0rdH4sh1ngS4mpl3', NOW());
    
    INSERT INTO "User" (name, email, "passwordHash", "updatedAt")
    VALUES ('Rogue User Attempt', 'test@pmayg.gov.in', '$2b$12$eX4mpL3h45hP455w0rdH4sh1ngS4mpl3', NOW());
EXCEPTION WHEN unique_violation THEN
    RAISE NOTICE 'SUCCESSFULLY REJECTED: Database blocked duplicate email insertion!';
END $$;

-- TEST 3.2: Duplicate Composite Unique Key Violation on Material (category, code)
-- Expected Result: ERROR 23505: duplicate key value violates unique constraint "Material_category_code_key"
DO $$
BEGIN
    INSERT INTO "Material" (category, code, multiplier)
    VALUES ('wall', 'brick', 1.50);
EXCEPTION WHEN unique_violation THEN
    RAISE NOTICE 'SUCCESSFULLY REJECTED: Database blocked duplicate (wall, brick) composite key!';
END $$;

-- TEST 3.3: NOT NULL Constraint Violation
-- Expected Result: ERROR 23502: null value in column "baseRate" violates not-null constraint
DO $$
BEGIN
    INSERT INTO "State" (name, "baseRate")
    VALUES ('Invalid State', NULL);
EXCEPTION WHEN not_null_violation THEN
    RAISE NOTICE 'SUCCESSFULLY REJECTED: Database blocked NULL baseRate insertion!';
END $$;


-- ----------------------------------------------------------------------------
-- SECTION 4: MULTI-RECORD TRANSACTION ATOMICITY & ROLLBACK (For Question 4)
-- ----------------------------------------------------------------------------

-- 4.1 Successful Atomic Multi-Record Update
BEGIN;
    UPDATE "State" SET "baseRate" = 1250 WHERE name = 'Chhattisgarh';
    UPDATE "State" SET "baseRate" = 1200 WHERE name = 'Madhya Pradesh';
COMMIT;

-- Verify changes committed
SELECT name, "baseRate" FROM "State" WHERE name IN ('Chhattisgarh', 'Madhya Pradesh');

-- 4.2 Simulated Failed Transaction with Automatic Rollback
BEGIN;
    -- Step 1 succeeds in staging:
    UPDATE "State" SET "baseRate" = 9999 WHERE name = 'Odisha';
    
    -- Step 2 purposefully fails (violates unique constraint):
    INSERT INTO "State" (name, "baseRate") VALUES ('Chhattisgarh', 1400);

-- Because statement above causes an error, transaction is aborted:
ROLLBACK;

-- Verify that Odisha was NOT left in the corrupted state of 9999:
SELECT name, "baseRate" FROM "State" WHERE name = 'Odisha';


-- ----------------------------------------------------------------------------
-- SECTION 5: PERFORMANCE PROFILING & EXPLAIN ANALYZE (For Question 5)
-- Demonstrating B-tree index lookups vs sequential scan
-- ----------------------------------------------------------------------------

-- 5.1 Point Lookup utilizing B-Tree Unique Index on State(name)
EXPLAIN ANALYZE 
SELECT * FROM "State" 
WHERE name = 'Chhattisgarh';

-- 5.2 Point Lookup utilizing Composite B-Tree Unique Index on Material(category, code)
EXPLAIN ANALYZE 
SELECT * FROM "Material" 
WHERE category = 'wall' AND code = 'flyash';

-- 5.3 Point Lookup on User Email for Login Authentication
EXPLAIN ANALYZE 
SELECT id, name, email, "passwordHash" 
FROM "User" 
WHERE email = 'beneficiary@pmayg.gov.in';
