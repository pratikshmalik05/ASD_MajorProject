# Data Engineering (DE) Major Project: DBMS Viva Documentation & Video Recording Guide

**Project Name:** Virtual House Visualizer and Cost Estimator  
**Domain:** Rural Housing (Ministry of Rural Development / PMAY-G Initiative)  
**Repository:** [https://github.com/pratikshmalik05/ASD_MajorProject](https://github.com/pratikshmalik05/ASD_MajorProject)  
**Author / Student:** Pratiksh Malik  

---

## 📋 Viva Video Submission Overview

For the Data Engineering (DE) Major Project evaluation, an **individual video response** must be recorded demonstrating your actual database implementation, schema, console queries, and code. Slides alone are not sufficient.

This directory (`de/`) contains comprehensive, project-specific technical documentation, runnable demonstration scripts, and a complete spoken video presentation script structured strictly around the **five mandatory DBMS Viva questions**.

---

## 🗂️ Directory Structure & Question Mapping

| File | Question Covered | Core Focus & Demonstrations |
|---|---|---|
| [`Q1_Database_Selection.md`](./Q1_Database_Selection.md) | **Q1: Database Choice & Workload** | PostgreSQL selection rationale, structured tabular workload, read vs. write ratios, ACID consistency requirements, rejected alternatives (MongoDB, SQLite, Neo4j), top 3 frequent queries. |
| [`Q2_Schema_and_Data_Model.md`](./Q2_Schema_and_Data_Model.md) | **Q2: Schema & Data Model Walkthrough** | Complete Entity-Relationship (ER) model, Entities, PK/FK mappings, Cardinalities (1:1, 1:N, M:N), resolution of multi-parameter estimation relationships, Prisma migrations, and cross-table join queries. |
| [`Q3_Normalization_and_Dependencies.md`](./Q3_Normalization_and_Dependencies.md) | **Q3: Normalization & Functional Dependencies** | Formal Normal Form audit (1NF $\to$ 2NF $\to$ 3NF $\to$ BCNF), functional dependency proofs ($X \to Y$), transitive/partial dependency elimination, and deliberate application-layer denormalization for stage allocations. |
| [`Q4_Data_Correctness_and_Transactions.md`](./Q4_Data_Correctness_and_Transactions.md) | **Q4: Data Correctness, Constraints & Transactions** | Database-level constraints (`PRIMARY KEY`, `UNIQUE`, `NOT NULL`, `CHECK`), application-layer validations, multi-statement transaction atomicity (`BEGIN ... COMMIT / ROLLBACK`), concurrency isolation (`READ COMMITTED`), and live constraint failure tests. |
| [`Q5_Performance_and_Scaling.md`](./Q5_Performance_and_Scaling.md) | **Q5: Performance, Indexing & Scaling** | B-tree index audit on high-cardinality keys, composite unique index optimization, query execution plan analysis (`EXPLAIN ANALYZE`), index overhead avoidance, and $100\times$ scalability strategy (caching, connection pooling, read replicas, partitioning). |
| [`demonstration_queries.sql`](./demonstration_queries.sql) | **Executable SQL Demonstration Script** | Complete runnable SQL file for PostgreSQL/psql/Prisma Studio to demonstrate tables, live seed data, constraint rejections, cross-table join calculations, transactions, and `EXPLAIN ANALYZE` plans during your video recording. |
| [`viva_presentation_script.md`](./viva_presentation_script.md) | **Word-for-Word Video Recording Script** | Timestamped speaking script with exact visual cues telling you when to switch between VS Code, terminal/database console, and browser/Unity. |

---

## 🎥 Video Recording Guidelines & Checklist

1. **Keep Your Screen Visible Throughout**: Have your screen shared showing:
   - Your code editor (VS Code displaying `backend/prisma/schema.prisma` and `backend/src/routes.js`).
   - Your database console / terminal (running PostgreSQL commands or Prisma Studio via `npx prisma studio`).
   - The live web application / Unity 3D interface generating an estimate.
2. **Do Not Rely on Generic Definitions**: Always anchor your answers in the **Virtual House Visualizer and Cost Estimator**. Mention table names (`State`, `HouseType`, `Material`, `User`, `Admin`), specific multipliers (`1.0` for brick, `0.9` for flyash, `1.1` for block), state base rates (e.g., ₹1,200/sq.ft for Chhattisgarh), and mathematical formulas.
3. **Show Live Rejections for Extra Credit**: Execute the invalid data insertion queries from [`demonstration_queries.sql`](./demonstration_queries.sql) live to show PostgreSQL rejecting duplicate emails (`23505 unique_violation`) or duplicate material category-codes.
4. **Estimated Video Duration**: 8 to 12 minutes total (~2 minutes per question).
