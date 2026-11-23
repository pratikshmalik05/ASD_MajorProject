# Q4: Data Correctness, Constraints & Transactions

## 1. Database Constraints & Separation of Concerns

Data correctness in the **Virtual House Visualizer and Cost Estimator** is enforced through a defense-in-depth model dividing responsibilities between the **database layer** and the **application layer**.

```text
┌────────────────────────────────────────────────────────┐
│                   Application Layer                    │
│   (Node.js / Express Controllers & Middleware)         │
│   - Password strength validation (min 8 chars)         │
│   - Email trimming & lowercase normalization           │
│   - Admin setup key verification (x-admin-setup-key)   │
│   - Single-admin policy enforcement                    │
│   - Multiplier positivity & sanity boundary checks     │
└──────────────────────────┬─────────────────────────────┘
                           │ Prisma ORM Client
                           ▼
┌────────────────────────────────────────────────────────┐
│                   Database Layer                       │
│              (PostgreSQL RDBMS Engine)                 │
│   - PRIMARY KEY (SERIAL auto-increment)                │
│   - UNIQUE ("email") on User and Admin                 │
│   - UNIQUE ("name") on State                           │
│   - UNIQUE ("code") on HouseType                       │
│   - Composite UNIQUE ("category", "code") on Material  │
│   - NOT NULL constraints across all mandatory fields   │
│   - CHECK ("baseRate" > 0), CHECK ("areaSqFt" > 0)     │
└────────────────────────────────────────────────────────┘
```

---

### Detailed Comparison Table

| Rule / Business Logic | Enforcing Layer | Mechanism / Syntax | Failure Behavior |
|---|---|---|---|
| **Entity Identity** | Database | `PRIMARY KEY ("id")` | Ensures uniqueness, creates default B-tree index. |
| **Unique User Email** | Database & App | DB: `UNIQUE INDEX User_email_key`<br>App: `findUnique` check | DB throws code `P2002` (Postgres error `23505`); API returns `409 Conflict`. |
| **Unique Material Combination** | Database | `@@unique([category, code])` | Prevents duplicate `('wall', 'brick')` entries. |
| **Mandatory Attributes** | Database | `NOT NULL` in DDL (`String`, `Int` without `?`) | Rejects inserts with `null` or missing values (`23502 not_null_violation`). |
| **Positive Rates & Area** | Database & App | DB: `CHECK ("baseRate" > 0)`<br>App: `Number.isInteger(baseRate) && baseRate > 0` | App returns `400 Bad Request`; DB rejects invalid numbers. |
| **Password Security** | Application | `bcrypt.hash(password, 12)` | Hash length 60 chars; raw passwords never stored in DB. |
| **Single Initial Admin** | Application | `const count = await prisma.admin.count(); if (count > 0) return 403;` | Blocks rogue admin self-registration once system is initialized. |

---

## 2. Transactions & Multi-Record Atomicity

### Operation: Coordinated Rate Re-indexing Across Multiple States
When the Ministry of Rural Development issues an across-the-board inflation adjustment or when seeding multiple dependent master records, multiple rows must be modified **atomically**.

#### Prisma Multi-Operation Transaction:
```javascript
// Example: Atomic multi-state rate update with audit logging
const result = await prisma.$transaction(async (tx) => {
  // 1. Update Chhattisgarh rate
  const state1 = await tx.state.update({
    where: { name: "Chhattisgarh" },
    data: { baseRate: 1250 },
  });

  // 2. Update Madhya Pradesh rate
  const state2 = await tx.state.update({
    where: { name: "Madhya Pradesh" },
    data: { baseRate: 1200 },
  });

  // 3. Intentionally guarded operation (e.g. if invalid rate provided)
  if (state1.baseRate < 0 || state2.baseRate < 0) {
    throw new Error("Base rate cannot be negative");
  }

  return { state1, state2 };
});
```

#### Raw SQL Transaction Representation:
```sql
BEGIN;

UPDATE "State" 
SET "baseRate" = 1250 
WHERE name = 'Chhattisgarh';

UPDATE "State" 
SET "baseRate" = 1200 
WHERE name = 'Madhya Pradesh';

-- If any statement fails (e.g., connection lost, check constraint violated):
-- ROLLBACK;
-- Otherwise:
COMMIT;
```

### What Happens If It Fails Halfway?
- **Atomicity Guarantees:** PostgreSQL uses **Write-Ahead Logging (WAL)**. If the second `UPDATE` fails (due to a network interruption, power loss, or constraint error), PostgreSQL issues an automatic `ROLLBACK`.
- **Zero Partial Updates:** The database is returned to its exact pre-transaction state. *Chhattisgarh* does not remain at ₹1,250 while *Madhya Pradesh* fails; either all states update together, or none do.

---

## 3. Concurrency, Race Conditions & Isolation Levels

### Scenario: Concurrent Write Operations
Consider two administrators trying to update or insert state rates simultaneously:
- **Admin A** updates *Chhattisgarh* baseRate to `1300`.
- **Admin B** updates *Chhattisgarh* baseRate to `1350`.

### Isolation Level Used
- **Default PostgreSQL Isolation Level:** **`READ COMMITTED`**.
- **How It Works:**
  1. Each query in a transaction sees only data committed before the query began.
  2. When Admin A issues an `UPDATE` on row `id = 1`, PostgreSQL acquires an exclusive **Row-Level Write Lock (`RowExclusiveLock`)** on that specific row in table `"State"`.
  3. When Admin B attempts to update the same row simultaneously, Admin B's query is placed in a **waiting queue** until Admin A either `COMMIT`s or `ROLLBACK`s.
  4. Once Admin A commits, Admin B reads the freshly updated row and executes its update, preventing lost updates.

### Concurrency on Registration (Race Condition Handling)
If two users simultaneously attempt to register with the exact same email `test@user.com`:
```javascript
// Application checks exist, but under simultaneous execution both might pass:
// Database UNIQUE index acts as the ultimate concurrency fence:
CREATE UNIQUE INDEX "User_email_key" ON "User"("email");
```
When both try to write, the PostgreSQL engine serializes the index insertion. The second transaction immediately triggers error `23505: unique_violation`. In our code (`backend/src/userAuthRoute.js`), this is caught and mapped to a clean user response:
```javascript
} catch (error) {
  if (error.code === "P2002") {
    return res.status(409).json({
      error: "Email is already registered",
    });
  }
}
```

---

## 4. Live Demonstration: Constraints Rejecting Invalid Data (Extra Credit)

During your video recording, execute these statements in your terminal (or `psql`) to show the database engine actively protecting data correctness.

### Demonstration 1: Rejecting Duplicate Unique Key (User Email)
```sql
-- Attempting to insert a duplicate user email:
INSERT INTO "User" (name, email, "passwordHash", "updatedAt") 
VALUES ('Ramesh Kumar', 'beneficiary@pmayg.gov.in', 'dummy_hash_1', NOW());

-- Run a second time with the exact same email:
INSERT INTO "User" (name, email, "passwordHash", "updatedAt") 
VALUES ('Suresh Kumar', 'beneficiary@pmayg.gov.in', 'dummy_hash_2', NOW());
```
**PostgreSQL Console Output (Demonstrate this on screen!):**
```text
ERROR: duplicate key value violates unique constraint "User_email_key"
DETAIL: Key (email)=(beneficiary@pmayg.gov.in) already exists.
```

---

### Demonstration 2: Rejecting Duplicate Composite Unique Key in `Material`
```sql
-- Existing entry: category = 'wall', code = 'brick'
-- Attempting to insert duplicate category and code:
INSERT INTO "Material" (category, code, multiplier) 
VALUES ('wall', 'brick', 1.25);
```
**PostgreSQL Console Output:**
```text
ERROR: duplicate key value violates unique constraint "Material_category_code_key"
DETAIL: Key (category, code)=(wall, brick) already exists.
```

---

### Demonstration 3: Rejecting `NOT NULL` Violation
```sql
-- Attempting to create a State without a required baseRate:
INSERT INTO "State" (name) VALUES ('Punjab');
```
**PostgreSQL Console Output:**
```text
ERROR: null value in column "baseRate" of relation "State" violates not-null constraint
DETAIL: Failing row contains (4, Punjab, null).
```
These live demonstrations prove conclusively that data integrity does not rely on naive client assumptions, but is rigidly enforced at the database kernel level.
