---
name: mandoline
description: "MANDATORY BEFORE loading raw data into BigQuery — transforms opaque survey exports and CSV dumps into self-documenting tables that LLMs and analysts can work with without external codebooks. Invoke FIRST when you see raw column names (S1, Q1r3), numeric codes, or empty BQ descriptions. 6-phase workflow ensures teaching-style column descriptions, decoded labels, table metadata, and automated verification. Triggers on 'make this data analysis-ready', 'build a clean BQ table', 'this data needs proper descriptions', 'transform raw data', 'enrich this table'. Prevents hallucination by making schema self-explanatory. (user)"
---

# Mandoline

The precision slicer. Takes irregular raw data and produces uniform, self-documenting BigQuery tables.

**Iron Law: Descriptions teach, they don't just define.** Every column description answers three questions: What is it? What are the values? What do I DO with it?

## When to Use

- Raw survey data with opaque column names (`S1`, `Q1r1`, coded integers)
- CSV/spreadsheet dumps loaded into BQ without metadata
- Any BQ table where `INFORMATION_SCHEMA.COLUMNS` returns empty descriptions
- When someone says "make this data a pleasure to analyse"
- Before pointing an LLM at a BQ table for the first time

## When NOT to Use

- Data already has rich column descriptions and metadata
- Quick exploratory queries on known-good tables (use consomme instead)
- One-off ad hoc analysis that doesn't need a persistent clean table
- Streaming/real-time data (mandoline is for snapshot tables)

## The Workflow

### Phase 1: Inspect Raw Source

Before designing anything, understand what you have.

```python
from google.cloud import bigquery
c = bigquery.Client(project=PROJECT)
t = c.get_table(f'{PROJECT}.{DATASET}.{TABLE}')

# Schema: names, types, existing descriptions
for f in t.schema:
    print(f'{f.name} ({f.field_type}) — {f.description or "(none)"}')
```

**Check:**
- Opaque column names needing rename
- Numeric codes needing decode to labels
- Junk rows to filter (terminated, non-consenting)
- Placeholder values (999999, -1) to NULL
- Whether it's Sheets-linked (fragile — snapshot to native)
- Fieldwork dates from timestamps
- Null counts, value ranges, distinct counts

**Exit criterion:** Every column's purpose, valid range, and transformation known.

### Phase 2: Design Clean Schema

| Decision | Guideline |
|----------|-----------|
| **Name** | Descriptive snake_case. Prefix groups: `action_`, `attitude_`, `awareness_` |
| **Type** | STRING for decoded categories, BOOL for binary, INT64 for Likert, FLOAT64 for measurements |
| **Drop** | Constants, internal IDs, platform metadata |
| **Decode** | Categories to labels. Keep Likert as INT for AVG(). Single-select to STRING |

**Exit criterion:** Complete raw -> clean mapping table.

### Phase 3: Write Transformation SQL

`CREATE OR REPLACE TABLE ... AS SELECT` for BQ-to-BQ.

```sql
CREATE OR REPLACE TABLE `project.dataset.clean_table` AS
SELECT
  RID AS respondent_id,
  CASE S2 WHEN 1 THEN 'Male' WHEN 2 THEN 'Female' ... END AS gender,
  Q1r1 = 1 AS action_physical_activity,  -- binary -> BOOL
  Q2r1 AS attitude_score,                -- keep Likert as INT
  IF(qtime = 999999, NULL, qtime) AS duration_seconds,
FROM `project.dataset.raw_table`
WHERE status = 3  -- qualified only
```

### Phase 4: Write Teaching Descriptions

This is where the value lives. See `references/enrichment-checklist.md`.

**Three questions every description answers:**
1. **What is it?** — Field definition
2. **What are the values?** — Enumeration, range, encoding
3. **What do I DO with it?** — Usage guidance, gotchas, relationships

**First-column rule:** First description in each question group is richest. Subsequent can be shorter.

**Bad:** `gender: "Respondent gender"`
**Good:** `gender: "Respondent gender: Male, Female, Other gender identity, Prefer not to say. 4 values. 'Other' and 'Prefer not to say' have small bases — flag n<30 as unreliable"`

### Phase 5: Enrich Table Metadata

```python
table.description = TABLE_DESCRIPTION      # Methodology paragraph
table.friendly_name = "Short Display Name"  # BQ console
table.labels = {"survey_org": "ohid", "data_shape": "user-level"}  # Data Catalog
client.update_table(table, ["schema", "description", "friendly_name", "labels"])
```

### Phase 6: Verify

```python
CHECKS = [
    ("Row count", sql, lambda r: r["n"] == expected),
    ("No NULL demographics", sql, lambda r: r["n"] == 0),
    ("Distinct values", sql, lambda r: r["n"] == expected),
    ("No duplicates", sql, lambda r: r["n"] == 0),
]
```

All checks must pass. Failing = transformation bug.

## Script Pattern

Standalone PEP 723 script. Run with `uv run --script scripts/build_X_table.py`. Idempotent.

```
Constants → COLUMN_DESCRIPTIONS dict → TRANSFORM_SQL → CHECKS → main()
```

## Anti-Patterns

| Pattern | Problem | Fix |
|---------|---------|-----|
| "Column: description of column" | Circular | Answer three questions |
| Empty BQ descriptions | LLMs fly blind | Every column described |
| Numeric codes in clean table | Codebook lookup every query | Decode to labels |
| No verification | Silent bugs | Automated checks |
| External datamap as prompt | Token-hungry, fragile | Bake into schema |
| Sheets-linked external table | Breaks on edit | Snapshot to native |

## Integration

- **Consomme** analyses what mandoline produces
- **Plongeur** auto-discovers mandoline tables via INFORMATION_SCHEMA
- Build scripts live alongside consuming app (e.g. `plongeur/scripts/`)
