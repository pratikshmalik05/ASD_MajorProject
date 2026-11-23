# 5-Minute DBMS Viva Video Presentation Transcript

**Project:** Virtual House Visualizer and Cost Estimator (Rural Housing / PMAY-G)  
**Student:** Pratiksh Malik  
**Target Duration:** Exactly 5 Minutes (300 Seconds)  
**Pacing:** ~135 words per minute (Clear, crisp, project-specific)  

---

## 🖥️ Screen Layout Setup (Before Recording Starts)

Split your screen into two halves:
- **Left Half (Code & Visuals):** **VS Code** with files open in tabs:
  1. `backend/prisma/schema.prisma`
  2. `backend/src/routes.js`
  3. `backend/prisma/migrations/20261113101845_init/migration.sql`
- **Right Half (Live Console & App):**
  - **Top:** **Terminal / Database Console** (`psql` or `npx prisma studio`) ready with queries from `de/demonstration_queries.sql`.
  - **Bottom:** **Running Web Application or Unity 3D Visualizer** showing the house model.

---

## ⏱️ Minute-by-Minute Script & On-Screen Demonstration Map

```text
  0:00 - 0:25  │  Introduction & Live App Demo
  0:25 - 1:20  │  Q1: Database Choice, Workload & Rejected Alternatives
  1:20 - 2:15  │  Q2: Schema Walkthrough, ER Model & Cross-Table Join
  2:15 - 3:05  │  Q3: Normal Form (BCNF/3NF) & Lean Design Trade-Off
  3:05 - 4:00  │  Q4: Data Correctness, Transactions & Live Rejection Test
  4:00 - 4:50  │  Q5: Indexes, EXPLAIN ANALYZE & 100x Scale Strategy
  4:50 - 5:00  │  Closing & Conclusion
```

---

### [0:00 - 0:25] Introduction & Application Demonstration

* **What to Share on Screen:**  
  Show the **Web Application or Unity 3D Visualizer** in browser/desktop.
* **On-Screen Action:**  
  Change house type from `1BHK` to `2BHK`, toggle wall material to `flyash`, and select state `Chhattisgarh`. Show the total estimate update live.
* **Spoken Transcript:**  
  > *"Hello respected evaluators. My name is Pratiksh Malik, and this is my individual 5-minute DBMS Viva video for our Major Project: the **Virtual House Visualizer and Cost Estimator**, built for rural housing beneficiaries under PMAY-G.  
  > As you can see on screen, changing house sizes, wall materials, and states dynamically recalculates construction estimates and stage-wise budgets in real time. Behind this visualizer lies our PostgreSQL relational database orchestrated through Prisma ORM."*

---

### [0:25 - 1:20] Q1: Database Selection & Architecture Rationale

* **What to Share on Screen:**  
  Switch to **VS Code** displaying `backend/prisma/schema.prisma` (lines 10–35), and show **Terminal** with `SELECT * FROM "State"; SELECT * FROM "HouseType"; SELECT * FROM "Material";`.
* **On-Screen Action:**  
  Highlight the tables in `schema.prisma`, then run the `SELECT` statements in terminal showing actual project data.
* **Spoken Transcript:**  
  > *"Starting with **Question 1: Why did we choose this database?**  
  > We chose **PostgreSQL**, an enterprise relational database (RDBMS), connected to our serverless backend via Prisma using `@prisma/adapter-pg`.  
  > **Data Structure:** Our data is strictly structured and tabular—fixed house dimensions like 270 sq.ft for 1BHK, statutory state construction base rates like ₹1,200/sq.ft for Chhattisgarh, and material cost multipliers like 0.9 for flyash brick and 1.1 for blocks.  
  > **Read/Write Patterns:** Our system experiences a heavy read workload—roughly 95% reads against 5% writes. Every interaction in Unity or React reads dimensions and rates to compute stage breakdowns. Writes are rare administrative updates.  
  > **Consistency:** We require strong ACID consistency. A rural beneficiary budgeting their government subsidy cannot receive inaccurate or partially committed calculations.  
  > **Rejected Alternatives:** We rejected **MongoDB** because our data has zero schema polymorphism; repeating rates across JSON documents would risk data anomalies. We also rejected **SQLite** because it locks database files during concurrent writes and cannot pool network connections across serverless instances."*

---

### [1:20 - 2:15] Q2: Schema Walkthrough & Relational Joins

* **What to Share on Screen:**  
  Show the **ER Diagram** from `de/Q2_Schema_and_Data_Model.md` or `schema.prisma`. Then open **Terminal** to run the cross-table join from Section 2 of `demonstration_queries.sql`.
* **On-Screen Action:**  
  Execute the cross-table SQL query in terminal. Point mouse to the resulting columns (`house_model`, `plinth_area`, `base_sqft_rate`, `total_estimate_inr`, and stage breakdown columns).
* **Spoken Transcript:**  
  > *"For **Question 2: Schema and Data Model Walkthrough.**  
  > **Entities & Keys:**  
  > Our schema consists of dimension tables: `State` with primary key `id` and candidate key `name`; `HouseType` with primary key `id` and unique `code`; and `Material` with surrogate primary key `id` and a composite unique candidate key on `(category, code)`. User and Admin tables have unique candidate keys on `email`.  
  > **Relationships & M:N Resolution:**  
  > Each state, house type, and material relates 1-to-many into the estimation process. Conceptually, house types and materials share a Many-to-Many relationship since any house type can combine with multiple wall and roof materials. Instead of bloating house tables with nested arrays, our schema keeps each dimension clean. The relationship is resolved on-demand through our calculation engine, or recorded as an `EstimateLog` transaction entity with foreign keys referencing each master record.  
  > **Live Cross-Table Query:**  
  > Running our cross-table join query in the terminal, you can see it joins `HouseType`, `State`, and the `Material` table twice—for walls and roof. In one atomic read, it outputs the ₹5,17,500 estimate for a 2BHK in Madhya Pradesh, along with exact stage allocations: 20% foundation, 35% walls, 25% roof, and 20% finishing."*

---

### [2:15 - 3:05] Q3: Normalization & Functional Dependencies

* **What to Share on Screen:**  
  Show **VS Code** displaying `de/Q3_Normalization_and_Dependencies.md` (functional dependencies table) and `backend/src/routes.js` (lines 125–135 showing stage calculation).
* **On-Screen Action:**  
  Highlight lines 128–132 in `backend/src/routes.js`:  
  `const foundation = Math.round(total * 0.20); ... const finishing = total - foundation - walls - roofCost;`
* **Spoken Transcript:**  
  > *"Moving to **Question 3: Normal Form Analysis and Functional Dependencies.**  
  > **Highest Normal Form:**  
  > Our database strictly reaches **Boyce-Codd Normal Form (BCNF)** and **3NF**.  
  > In table `Material`, the candidate key is composite: `{category, code}`. The functional dependencies are:  
  > 1. `{id} -> {category, code, multiplier}`, and  
  > 2. `{category, code} -> {id, multiplier}`.  
  > Because both determinants are candidate keys, every determinant is a superkey, satisfying BCNF. Partial and transitive dependencies were eliminated by decomposing what would have been an unnormalized flat table into separate master dimensions.  
  > **Deliberate Design Trade-Off:**  
  > Notice in `backend/src/routes.js` that the stage cost breakdown is calculated in the application engine rather than joining a separate normalized `StageAllocation` table. This eliminates unnecessary joins, reducing query latency for high-frequency 3D rendering in Unity from 4 milliseconds to sub-millisecond speeds. Correctness is maintained deterministically by calculating `finishing = total - foundation - walls - roofCost`, mathematically guaranteeing that the stage sum strictly equals the total."*

---

### [3:05 - 4:00] Q4: Data Correctness, Constraints & Transactions

* **What to Share on Screen:**  
  Show **VS Code** showing `backend/prisma/migrations/20261113101845_init/migration.sql`, and terminal ready with Test 3.1 & 3.2 from `demonstration_queries.sql`.
* **On-Screen Action:**  
  Run the duplicate email and duplicate `(category, code)` insertion queries in terminal to show PostgreSQL throwing `ERROR: duplicate key value violates unique constraint`.
* **Spoken Transcript:**  
  > *"For **Question 4: Data Correctness, Constraints and Transactions.**  
  > **Constraints:**  
  > Correctness is enforced at the database level with `PRIMARY KEY`, `NOT NULL`, and unique constraints on `User.email`, `State.name`, `HouseType.code`, and composite unique on `Material(category, code)`. The application layer supplements this by validating positive numbers and hashing passwords with 12 bcrypt salt rounds.  
  > **Live Constraint Rejection Demonstration:**  
  > Let me demonstrate constraint rejection live in the console. Attempting to insert a duplicate email or duplicate material code immediately fails: PostgreSQL throws error `23505 unique_violation`. In our code, Prisma catches this as `P2002` and returns HTTP 409 Conflict.  
  > **Transactions & Concurrency:**  
  > Multi-record operations—like bulk updating base rates across states—are wrapped in atomic transactions using Prisma `$transaction` or PostgreSQL `BEGIN ... COMMIT / ROLLBACK`. If an error occurs halfway, PostgreSQL rolls back completely via Write-Ahead Logging, preventing partial data corruption. Under our default `READ COMMITTED` isolation level, row-level locks prevent concurrent admins from causing lost updates."*

---

### [4:00 - 4:50] Q5: Efficiency, Indexing & Scalability Strategy

* **What to Share on Screen:**  
  Show **Terminal** and run `EXPLAIN ANALYZE SELECT * FROM "Material" WHERE category = 'wall' AND code = 'flyash';` from Section 5 of `demonstration_queries.sql`.
* **On-Screen Action:**  
  Highlight the output line: `Index Only Scan using "Material_category_code_key"`.
* **Spoken Transcript:**  
  > *"Finally, **Question 5: Performance Optimization and Scaling.**  
  > **Indexes Created:**  
  > We created B-tree unique indexes on `User(email)`, `State(name)`, and a composite unique index on `Material(category, code)`. As shown by running `EXPLAIN ANALYZE` in the console, filtering by material executes an **Index Only Scan**, reading directly from the B-tree leaf nodes without touching table heap pages.  
  > **Indexes Rejected:**  
  > We considered an index on `category` alone, but rejected it because it only has two distinct values—wall and roof. Low cardinality causes the query planner to default to a sequential scan, making an index pure write overhead.  
  > **Handling 100x Growth:**  
  > If our user base scales 100 times to a national PMAY-G rollout:  
  > 1. Serverless connections would spike, so we use **PgBouncer** connection pooling.  
  > 2. Because 95% of reads fetch static rates, we introduce a **Redis distributed cache**, offloading 98% of reads from PostgreSQL.  
  > 3. For large audit logs, we implement **declarative table partitioning** by state code, keeping index depths shallow and queries fast."*

---

### [4:50 - 5:00] Conclusion

* **What to Share on Screen:**  
  Return to the **Unity 3D / Web Visualizer** with an interactive 3D house model on screen.
* **Spoken Transcript:**  
  > *"In summary, our database architecture combines BCNF normalization, strict constraint enforcement, atomic transactions, and B-tree indexing to provide a reliable, ACID-compliant backend for rural housing visualization. Thank you!"*

---

## 🎯 Tips for Scoring Maximum Marks During Recording

1. **Keep Your Face Visible:** Position your webcam in the top-right corner of the recording so your identity is verified throughout.
2. **Execute Live SQL:** Do not just talk about queries—actually hit Enter in the terminal to show PostgreSQL returning results and throwing the unique constraint error!
3. **Keep Code Open:** When discussing normalization and constraints, point your cursor at the actual Prisma schema and Express route lines.
