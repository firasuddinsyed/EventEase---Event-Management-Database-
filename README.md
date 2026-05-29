# 🗄️ EventEase — Event Management Database

A fully normalized MySQL database for end-to-end event management — covering bookings, vendors, food trucks, performances, competitions, payments, and lost & found. Built as a capstone project for BUAN 6320 Database Foundations at UT Dallas.

---

## 📊 Project Stats

| Component | Count |
|---|---|
| Tables | 25 |
| Triggers | 6 |
| Stored Procedures | 5 |
| Functions | 5 |
| Complex Queries | 11 |
| Sample Records | 100+ persons, 16 events, 20 food trucks, 80+ menu items |

---

## 🛠️ Tech Stack

`MySQL 8.0` `SQL` `ER Modeling` `Stored Procedures` `Triggers` `Functions`

---

## 📁 Repository Structure

```
EventEase-Event-Management-Database/
├── EventEase_Complete_Schema_FINAL.sql   # Full schema — run this to set up the database
├── Trigger_Verification.sql              # Sequential test script for all 6 triggers
├── ER_Diagram.png                        # Entity Relationship Diagram (25 tables)
└── EventEase_Report_Firasuddin_Syed.docx # Full project report
```

---

## 🚀 Getting Started

**Prerequisites:** MySQL 8.0+ and MySQL Workbench

```sql
-- Open MySQL Workbench and run the full schema file
-- It will automatically:
--   1. Drop and recreate the EventEase database
--   2. Create all 25 tables with FK constraints
--   3. Insert sample data
--   4. Create all triggers, stored procedures, and functions

source EventEase_Complete_Schema_FINAL.sql;
```

After running, verify all tables populated correctly — the script includes `SELECT *` statements for all 25 tables in Section 7B.

---

## 🗺️ ER Diagram

![ER Diagram](ER_Diagram.png)

---

## 📐 Database Structure

### Core Tables
| Table | Description |
|---|---|
| `EventRecord` | Central event table — name, organizer, dates, location |
| `Person` | Universal person record for all roles |
| `Venue` | Venue details with capacity |
| `Locations` | Physical addresses |
| `EventProgram` | Programs/sessions within events |

### Role Linking Tables
| Table | Description |
|---|---|
| `Person_Staff` | Staff members linked to events with role type |
| `Person_Attendee` | Attendee registrations with ticket type and check-in status |
| `Person_Sponsor` | Sponsor contributions with auto-calculated tier |
| `Person_Vendor` | Vendor participation per event |

### Vendor & Food Truck
| Table | Description |
|---|---|
| `Booths` | Vendor booth assignments |
| `Food_Truck` | Food truck registrations per event |
| `Food_Menu` | Menu items with price and availability |
| `Food_Truck_Orders` | Customer food orders |
| `Food_Truck_Orders_Details` | Order line items |

### Performances & Competitions
| Table | Description |
|---|---|
| `Performances` | Individual performances within programs |
| `Performances_Superstar` | Performers linked to performances |
| `Competition` | Competition details within programs |
| `Competition_Participants` | Participants and their roles |
| `Prizes` | Prize records with winner and category |

### Financial Tables
| Table | Description |
|---|---|
| `Payments` | Central ledger — populated exclusively by triggers |
| `Vendor_Payments` | Payments made to vendors |
| `Salary` | Staff salary records |
| `Performer_Remuneration` | Performer payment records |
| `Sponsorships` | Sponsorship transactions |

### Utility
| Table | Description |
|---|---|
| `Lost_And_Found` | Lost items with claim workflow |

---

## ⚙️ Triggers

| Trigger | Fires On | Effect |
|---|---|---|
| `sponsor_update` | INSERT → Sponsorships | Updates contribution amount + tier, logs CREDIT/SPONSOR in Payments |
| `Payments_after_order` | INSERT → Food_Truck_Orders | Logs CREDIT/FOOD_TRUCK in Payments |
| `after_performer_remuneration_insert` | INSERT → Performer_Remuneration | Logs DEBIT/REMUNERATION in Payments |
| `after_vendor_payment_insert` | INSERT → Vendor_Payments | Logs DEBIT/VENDOR in Payments |
| `after_salary_insert` | INSERT → Salary | Logs CREDIT/SALARY in Payments |
| `trg_prevent_double_bookings` | BEFORE INSERT → EventRecord | Blocks overlapping events at same location |

> The `Payments` table is populated **exclusively by triggers** — never by direct INSERT. An empty Payments table after data inserts is expected and correct.

---

## 🔧 Stored Procedures

| Procedure | Purpose |
|---|---|
| `RegisterAttendeeForEvent` | Register a new or existing person as an event attendee |
| `UpdateMenuPrices` | Update food menu item price with 20% increase guard |
| `GenerateEventFinancialReport` | Full financial summary — tickets, sponsorships, vendors, total |
| `GenerateEventPerformanceReport` | Performance and competition summary with participant counts |
| `claim_lost_item` | Mark a lost item as claimed and return the updated record |

---

## 📐 Functions

| Function | Returns | Purpose |
|---|---|---|
| `AreTicketsAvailableorNot` | BOOLEAN | Check ticket availability against actual venue capacity |
| `IsVenueAvailable` | BOOLEAN | Check if a venue is free during a time window |
| `CalculateFoodTruckRevenue` | DECIMAL | Total food truck revenue for an event |
| `CalculateEventTotalProgramDuration` | INT | Total program duration in minutes for an event |
| `check_menu_item_availability` | VARCHAR | Check if a menu item is available at a specific truck |

---

## 🧪 Trigger Verification

Run `Trigger_Verification.sql` after the full schema to test all 6 triggers sequentially:

```sql
source Trigger_Verification.sql;
```

Each trigger test includes an INSERT statement and verification SELECTs showing the expected result. Trigger 6 (double-booking prevention) intentionally produces an error — that error is the successful test.

Final verification query:

```sql
SELECT payment_type, COUNT(*) AS total_rows, SUM(amount) AS total_amount
FROM Payments
GROUP BY payment_type
ORDER BY payment_type;
-- Expected: 5 rows — FOOD_TRUCK, REMUNERATION, SALARY, SPONSOR, VENDOR
```

---

## 🎓 Context

Capstone project for **BUAN 6320 — Database Foundations for Business Analytics**
The University of Texas at Dallas | Fall 2024

---

## 👤 Author

**Firasuddin Syed**
MS Business Analytics & AI | UT Dallas | May 2026
[LinkedIn](https://linkedin.com/in/firasuddin-syed) · [GitHub](https://github.com/firasuddinsyed)
