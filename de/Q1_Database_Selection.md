# Q1: Database Selection & Architecture Rationale

## 1. Database Identification & Type

- **Database Engine Used:** **PostgreSQL** (Managed Object-Relational Database System hosted via Cloud / Neon / Netlify DB, orchestrated via Prisma ORM v7 using `@prisma/adapter-pg`).
- **Database Paradigm:** **Relational Database Management System (RDBMS)**.
- **Architectural Role:** Centralized, ACID-compliant persistence store serving a cross-platform client ecosystem comprising:
  1. A **Unity 3D miniature house visualizer** (C# client running on desktop/mobile).
  2. A **React Web Application** (Beneficiary self-service estimator and Admin management dashboard).
  3. A **Node.js/Express REST API** (Backend calculation engine running on Netlify serverless functions).

---

## 2. Why PostgreSQL is Suitable for the Project Data & Usage

### A. What the Project Data Looks Like
The project data in the **Virtual House Visualizer and Cost Estimator** is **strictly structured and tabular**:
1. **Dimension / Master Tables:**
   - **`HouseType`**: Rigid attributes defining standard rural housing layouts (e.g., `code: "1BHK"`, `areaSqFt: 270`, `code: "2BHK"`, `areaSqFt: 450`).
   - **`State`**: Standardized jurisdictional base construction rates mandated by government schedules of rates (e.g., `name: "Chhattisgarh"`, `baseRate: 1200` INR/sq.ft).
   - **`Material`**: Categorized construction components with calibrated cost multipliers (e.g., `category: "wall"`, `code: "flyash"`, `multiplier: 0.90`).
2. **Transactional & Security Tables:**
   - **`User`** & **`Admin`**: Strongly typed identity records containing unique emails, salted bcrypt password hashes, and automated timestamps.

The data has **zero schema variability** and relies entirely on deterministic arithmetic relationships (`Cost = Area × BaseRate × WallMultiplier × RoofMultiplier`). A relational model guarantees this structural rigidity without schema drift.

---

### B. Read and Write Patterns & Data Volume Expectations

- **Read vs. Write Ratio:** **Heavy Read-Optimized Workload (~95% Reads, ~5% Writes)**.
  - **Reads:** Every time a rural beneficiary or technician changes a parameter in the Unity 3D visualizer or the React web app (e.g., toggling wall material from red clay brick to flyash brick, or switching between 1BHK and 2BHK), the application performs reads against `HouseType`, `Material`, and `State`.
  - **Writes:** Writes are low-frequency administrative operations (updating state rates when the state public works department revises schedule rates, registering an admin or registering beneficiaries).
- **Data Volume Expectations:**
  - **Master Data:** Compact and high-density (36 Indian States/UTs, 5–10 standardized PMAY-G rural house floorplans, ~20 approved wall/roof material combinations). This entire master dataset fits comfortably in memory buffers (PostgreSQL Shared Buffers).
  - **User & Transaction Records:** Expected to grow to $10^4$ to $10^5$ registered beneficiaries across districts, requiring fast B-tree index lookups on email and identity fields.

---

### C. Strong Consistency & ACID Transaction Requirements

Strong consistency is non-negotiable for this system:
1. **Financial & Subsidy Integrity:** Beneficiaries under rural housing assistance programs plan their loans and material procurement based on calculated estimates. Inconsistent or stale read anomalies (e.g., reading an outdated state base rate while multiplying with a new material coefficient) would lead to erroneous budget allocations.
2. **Immediate Consistency Across Client Form Factors:** If an administrator updates the baseline rate for *Madhya Pradesh* from ₹1,150 to ₹1,200 via the React Admin dashboard, the change must immediately reflect across all concurrent Unity 3D sessions and web clients. Relational ACID guarantees that dirty reads, phantom reads, and non-repeatable reads are eliminated at the chosen isolation level (`READ COMMITTED`).

---

## 3. Alternative Databases Considered & Why They Were Rejected

| Alternative Database | Model Type | Why It Was Considered | Why It Was Rejected for This Project |
|---|---|---|---|
| **MongoDB** | Document Store (NoSQL) | Popular for rapid Node.js development and dynamic JSON manipulation. | **Rejected:** Data is strictly tabular and fixed. Storing independent documents for each house estimation or repeating rate data creates high redundancy and risk of data anomalies. MongoDB lacks native composite unique constraints across multiple fields without complex compound indexing, and does not enforce relational schema integrity out of the box. |
| **SQLite** | Embedded Serverless RDBMS | Used during the early local prototyping phase inside the standalone Unity build. | **Rejected for Production:** SQLite locks the entire database file during writes, creating severe concurrency bottlenecks. Furthermore, because our production backend is deployed as serverless functions on Netlify, SQLite cannot be shared across ephemeral serverless instances without network storage, whereas PostgreSQL handles concurrent TCP connection pooling seamlessly. |
| **Neo4j** | Graph Database | Considered for modeling relationships between house components and stages. | **Rejected:** The domain model does not feature recursive graph traversals, social networks, or arbitrary pathfinding. Using a graph query engine for simple 1-to-N multiplier calculations would introduce unnecessary query complexity, memory overhead, and steep learning curves. |

---

## 4. Demonstrating Actual Project Data & Frequent Operations

### Sample Actual Project Data

```text
Table: "State"
 id |      name      | baseRate (₹/sq.ft)
----+----------------+--------------------
  1 | Chhattisgarh   |               1200
  2 | Madhya Pradesh |               1150
  3 | Odisha         |               1100

Table: "HouseType"
 id | code | areaSqFt
----+------+----------
  1 | 1BHK |      270
  2 | 2BHK |      450

Table: "Material"
 id | category |  code  | multiplier
----+----------+--------+------------
  1 | wall     | brick  |        1.0
  2 | wall     | flyash |        0.9
  3 | wall     | block  |        1.1
  4 | roof     | rcc    |        1.0
  5 | roof     | tin    |        0.7
```

---

### Top 3 Most Frequent Application Operations

#### 1. Estimation Calculation Query (`POST /api/estimate`)
Fetches all 4 dimensional entities in parallel to compute the total cost and stage breakdowns:
```javascript
// From backend/src/routes.js
const [house, wallMaterial, roofMaterial, stateRate] = await Promise.all([
  prisma.houseType.findUnique({ where: { code: houseType } }),
  prisma.material.findUnique({
    where: { category_code: { category: "wall", code: wall } },
  }),
  prisma.material.findUnique({
    where: { category_code: { category: "roof", code: roof } },
  }),
  prisma.state.findUnique({ where: { name: state } }),
]);

const total = Math.round(
  house.areaSqFt * stateRate.baseRate * wallMaterial.multiplier * roofMaterial.multiplier
);
```

Equivalent Direct SQL:
```sql
SELECT 
    h.code AS house_code,
    h."areaSqFt",
    s.name AS state_name,
    s."baseRate",
    mw.code AS wall_code,
    mw.multiplier AS wall_multiplier,
    mr.code AS roof_code,
    mr.multiplier AS roof_multiplier,
    ROUND(h."areaSqFt" * s."baseRate" * mw.multiplier * mr.multiplier) AS total_estimated_cost
FROM "HouseType" h, "State" s, "Material" mw, "Material" mr
WHERE h.code = '1BHK'
  AND s.name = 'Chhattisgarh'
  AND mw.category = 'wall' AND mw.code = 'brick'
  AND mr.category = 'roof' AND mr.code = 'rcc';
```

#### 2. Master Data Lookup for Client Dropdowns (`GET /api/rates`, `GET /api/materials`)
Executed when Unity 3D or the React UI initializes:
```javascript
// Fetch all active state rates
const rates = await prisma.state.findMany();

// Fetch all active material options
const materials = await prisma.material.findMany();
```

#### 3. User & Admin Authentication (`POST /api/user/login` and `/api/admin/login`)
```javascript
const user = await prisma.user.findUnique({
  where: { email: email.trim().toLowerCase() },
});
```
SQL equivalent performing an index-accelerated point lookup:
```sql
SELECT id, name, email, "passwordHash" 
FROM "User" 
WHERE email = 'beneficiary@pmayg.gov.in';
```
