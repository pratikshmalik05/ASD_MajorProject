# DBMS Viva Video Recording Script

**Project Title:** Virtual House Visualizer and Cost Estimator  
**Student Name:** Pratiksh Malik  
**Total Estimated Video Duration:** 10 to 12 Minutes  

---

## 🎥 Pre-Recording Checklist & Screen Layout

Before clicking record, set up your desktop layout so your screen remains visible throughout:
1. **Window 1 (Left Half):** **VS Code** with the repository open (`backend/prisma/schema.prisma` and `backend/src/routes.js`).
2. **Window 2 (Right Half - Top):** **Database Console** (`psql` terminal, PgAdmin, or Prisma Studio `npx prisma studio`).
3. **Window 3 (Right Half - Bottom / Tab):** The running **Web Application** or **Unity 3D Visualizer**.

> **Important Presentation Note:** Keep your camera visible in the corner if possible, maintain clear audio, and speak confidently while switching to the relevant file or terminal window as indicated by the cues below!

---

## ⏱️ Video Script Breakdown

### 🎬 Introduction (0:00 - 0:45)
**Screen to Show:** Web Application / Unity 3D Visualizer running, showing a 3D house model.

> *"Hello everyone and respected evaluators. My name is Pratiksh Malik, and this is my individual DBMS Viva video submission for our Major Project: the **Virtual House Visualizer and Cost Estimator**, developed for rural housing beneficiaries under the Ministry of Rural Development.*
>
> *In this video, I will walk you through our actual database implementation, schema architecture, normalization analysis, transactional integrity mechanisms, and query performance optimizations, answering all five evaluation questions with live code and database console demonstrations."*

---

### ❓ Question 1: Database Selection & Architecture Rationale (0:45 - 2:45)
**Screen to Show:** Switch to VS Code displaying `backend/prisma/schema.prisma` and then terminal showing `SELECT * FROM "State"; SELECT * FROM "HouseType";`.

> *"Starting with **Question 1: Why did we choose this database?**
>
> For our project, we chose **PostgreSQL**, an enterprise-grade Relational Database Management System (RDBMS), connected to our Node.js and Netlify serverless backend via Prisma ORM with the `@prisma/adapter-pg` driver.
>
> **1. Data Characteristics:**  
> Our project data is strictly structured and tabular. As you can see here in our database console, we have master tables like `HouseType` storing exact plinth areas (such as 270 sq.ft for 1BHK and 450 sq.ft for 2BHK), `State` storing statutory base construction rates per square foot, and `Material` storing calibrated multipliers like 1.0 for brick, 0.9 for flyash, and 0.7 for tin roofs.
>
> **2. Read and Write Patterns:**  
> Our workload is heavily read-intensive—approximately 95% reads versus 5% writes. Every time a rural beneficiary or supervisor configures a house in our Unity 3D miniature viewer or React web app, multiple read queries are executed to fetch house dimensions, state rates, and material coefficients to compute stage-wise construction expenses. Writes are infrequent, occurring primarily during administrative updates to state schedules of rates or user sign-ups.
>
> **3. Strong Consistency & ACID:**  
> Financial planning under government housing schemes like PMAY-G requires immediate consistency. We cannot afford eventual consistency anomalies where a beneficiary is budgeted using an outdated state rate combined with a new material coefficient. When an admin updates a rate, all concurrent Unity and web sessions must immediately read the committed value.
>
> **4. Alternatives Considered & Rejected:**  
> We considered **MongoDB**, but rejected it because our data is intrinsically tabular with fixed schemas; storing repeating JSON documents would cause data duplication, risk update anomalies, and lack composite unique constraint enforcement. We also prototyped with **SQLite** in our early local Unity builds, but rejected it for production because SQLite locks the entire database file during writes and cannot support connection pooling across serverless cloud function instances."*

---

### ❓ Question 2: Schema & Data Model Walkthrough (2:45 - 5:00)
**Screen to Show:** `backend/prisma/schema.prisma`, the ER diagram from `de/Q2_Schema_and_Data_Model.md`, and run the cross-table join from `de/demonstration_queries.sql` in terminal.

> *"Moving to **Question 2: Schema and Data Model Walkthrough.**
>
> Let's look at our Entity-Relationship design.
>
> **Entities and Keys:**  
> 1. Our `State` table uses an auto-incrementing integer `id` as primary key, with a unique candidate key on `name`, and an integer `baseRate`.  
> 2. `HouseType` uses an auto-incrementing `id` as primary key and a unique string `code` ('1BHK', '2BHK') with `areaSqFt`.  
> 3. `Material` has an `id` primary key, and a composite candidate key on `(category, code)`, mapped in Prisma via `@@unique([category, code])`.  
> 4. `User` and `Admin` tables have `id` primary keys and unique constraints on `email`, securing user credentials with salted bcrypt hashes.
>
> **Relationships and Resolving M:N:**  
> The relationship between states, house types, and materials is 1-to-many into the estimation process. Conceptually, House Types and Materials form a **Many-to-Many (M:N)** relationship: a 1BHK can be constructed with brick, flyash, or block walls, and tin or RCC roofs; similarly, flyash brick is used across multiple house models.  
> Instead of denormalizing arrays into house types, our schema cleanly isolates each dimension table. The M:N relationship is resolved on-demand through our calculation engine (`POST /api/estimate`), or logged persistently as an `EstimateLog` transaction record that references the foreign keys of each master entity.
>
> **Live Schema Demonstration:**  
> Let me run our main cross-table calculation query in the terminal [Execute Section 2 from `demonstration_queries.sql`].  
> As you can see, this query joins `HouseType`, `State`, and the `Material` table twice—once for wall and once for roof. In a single execution, it pulls the area, base rate, multipliers, computes the exact total of ₹5,17,500 for a 2BHK in Madhya Pradesh, and outputs the exact stage-wise disbursements: 20% foundation, 35% walls, 25% roof, and 20% finishing."*

---

### ❓ Question 3: Normalization & Functional Dependencies (5:00 - 7:15)
**Screen to Show:** `de/Q3_Normalization_and_Dependencies.md` and `backend/src/routes.js` (around line 125 showing stage calculation).

> *"Next, **Question 3: Normal Form Analysis and Functional Dependencies.**
>
> **Highest Normal Form Reached:**  
> Our database relations strictly reach **Boyce-Codd Normal Form (BCNF)** and **Third Normal Form (3NF)**.
> - **1NF:** All column values are strictly atomic scalar values; there are no repeating groups or nested arrays.
> - **2NF:** No non-prime attribute is partially dependent on any candidate key. In `Material`, where the candidate key is composite `(category, code)`, the non-prime attribute `multiplier` depends on both attributes together.
> - **3NF & BCNF:** There are no transitive dependencies ($X \to Y \to Z$). Every determinant in every functional dependency is a superkey.
>
> **Functional Dependencies in `Material`:**  
> Let's examine the functional dependencies of `Material`:  
> - Functional Dependency 1: `{id} -> {category, code, multiplier}`  
> - Functional Dependency 2: `{category, code} -> {id, multiplier}`  
> Because both `{id}` and `{category, code}` are candidate keys, every determinant is a superkey, fulfilling BCNF.
>
> **How Partial and Transitive Dependencies Were Removed:**  
> Initially, in a flat design, house dimensions, state rates, and material multipliers would have been repeated in a single table, creating severe update and deletion anomalies. By decomposing the schema into independent `State`, `HouseType`, and `Material` tables, we eliminated all partial and transitive dependencies.
>
> **Deliberate Denormalization / Trade-off:**  
> Where did we deliberately keep things lean? Notice in our API code (`backend/src/routes.js`) that the stage percentage breakdown (foundation 20%, walls 35%, roof 25%, finishing 20%) is computed dynamically in the application layer rather than storing a separate normalized `StageAllocation` table.  
> This eliminates additional database joins for high-frequency 3D rendering queries in Unity, lowering query latency from 4ms down to under 1ms. Correctness is maintained deterministically by calculating `finishing = total - foundation - walls - roofCost`, mathematically guaranteeing no rounding loss."*

---

### ❓ Question 4: Data Correctness, Constraints & Transactions (7:15 - 9:30)
**Screen to Show:** `backend/prisma/migrations/20261113101845_init/migration.sql`, terminal running Section 3 & 4 of `demonstration_queries.sql`.

> *"Now for **Question 4: How our database protects data correctness.**
>
> **Constraints & Defense in Depth:**  
> We enforce correctness at both the database engine and the application layer:  
> - At the database layer: `PRIMARY KEY` on IDs, `UNIQUE` on `User.email`, `Admin.email`, `State.name`, and composite `UNIQUE` on `Material(category, code)`. All fields are marked `NOT NULL`.  
> - At the application layer: We sanitize emails with trimming and lowercasing, enforce password lengths of at least 8 characters, and hash passwords using bcrypt with 12 salt rounds.
>
> **Live Demonstration of Constraints Rejecting Invalid Data:**  
> Let's test the database constraints live [Run Test 3.1 & 3.2 in terminal].  
> Notice that when I attempt to insert a duplicate email or duplicate material code, PostgreSQL immediately rejects it with error code `23505 unique_violation`. In our Node.js backend, this is captured with Prisma error `P2002` and mapped to a clean HTTP 409 Conflict response.
>
> **Transactions and Atomicity:**  
> When performing operations affecting multiple records—such as updating base rates across several states—we wrap them inside a PostgreSQL transaction (`BEGIN ... COMMIT / ROLLBACK`) or Prisma's `$transaction` API.  
> If an error occurs halfway through, PostgreSQL uses its Write-Ahead Log to execute an immediate `ROLLBACK`. As demonstrated in our test script [Highlight Section 4.2 in terminal], if an update to Odisha succeeds but a subsequent insert violates a constraint, the entire transaction aborts, leaving Odisha's rate completely untouched.
>
> **Concurrency & Isolation:**  
> PostgreSQL operates under the **`READ COMMITTED`** isolation level by default. When an admin updates a state rate, row-level exclusive locks (`RowExclusiveLock`) prevent concurrent transactions from corrupting or overwriting each other, preventing lost updates."*

---

### ❓ Question 5: Efficiency, Indexing & Scalability (9:30 - 11:30)
**Screen to Show:** `de/Q5_Performance_and_Scaling.md`, terminal running `EXPLAIN ANALYZE` from Section 5 of `demonstration_queries.sql`.

> *"Finally, **Question 5: Database Efficiency and Scaling.**
>
> **Indexes Created & Queries Supported:**  
> We created targeted B-tree indexes supporting our most frequent access paths:  
> 1. A unique B-tree index on `State(name)` supporting $O(\log N)$ point lookups when fetching state rates.  
> 2. A unique B-tree index on `HouseType(code)` for instantaneous area retrieval.  
> 3. A **composite B-tree unique index** on `Material(category, code)`. Let me show this with `EXPLAIN ANALYZE` in the console [Run Section 5.2]. Notice the query planner executes an **Index Only Scan**, reading the data directly from the index tree without scanning heap blocks.  
> 4. Unique B-tree indexes on `User(email)` and `Admin(email)` guaranteeing sub-millisecond authentication.
>
> **Indexes Considered and Rejected:**  
> We deliberately avoided creating an index on the `category` column alone because it has extremely low cardinality (only two values: 'wall' and 'roof'). A B-tree on two values offers virtually no selectivity, and the query planner would default to a sequential scan anyway, while adding unnecessary write overhead.
>
> **What Breaks at 100x Growth and How We Fix It:**  
> If our user base expands 100 times to a nationwide deployment:  
> 1. **Connection Exhaustion:** Hundreds of concurrent serverless instances hitting PostgreSQL would exhaust database connection pools. We resolve this using **PgBouncer** connection multiplexing.  
> 2. **Repetitive Read Load:** 98% of queries fetch identical static rates. We implement a distributed **Redis In-Memory Cache** with event-driven cache invalidation when admins update rates, offloading almost all read traffic from the primary database.  
> 3. **Database Write Scaling:** We would deploy **Read Replicas** for calculation traffic, reserving the primary master node for writes, and implement **Declarative List Partitioning** on user and audit log tables by state code.
>
> **Conclusion:**  
> This architectural design ensures that our Virtual House Visualizer and Cost Estimator remains ACID-compliant, strictly normalized, and highly performant for rural housing beneficiaries. Thank you!"*
