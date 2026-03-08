# BQ Table Enrichment Checklist

The full inventory of BigQuery features that make a table self-documenting. Most people use 2-3 of these. Use all of them.

## Table-Level

| Feature | API | What it does | Example |
|---------|-----|-------------|---------|
| **Description** | `table.description` | Paragraph visible in BQ console, Data Catalog, INFORMATION_SCHEMA | Survey methodology: n, fieldwork dates, format, key usage notes, caveats |
| **Friendly name** | `table.friendly_name` | Short display name in BQ console UI | "OHID Mental Health Survey" |
| **Labels** | `table.labels` | Key-value metadata for filtering in Data Catalog and `__TABLES__` | `survey_org: ohid`, `data_shape: user-level`, `respondents: 1320` |
| **Expiration** | `table.expires` | Auto-delete date. Prevents orphan tables | 60-90 days for snapshots, None for production |

## Column-Level

| Feature | API | What it does |
|---------|-----|-------------|
| **Description** | `SchemaField.description` | Per-column text visible in BQ console, INFORMATION_SCHEMA, and LLM schema discovery |
| **Mode** | `SchemaField.mode` | NULLABLE, REQUIRED, REPEATED — communicates data contracts |

## Column Description Philosophy: Teach, Don't Define

The difference between a mediocre table and an excellent one is in the column descriptions.

### Bad (defines)
```
gender: "Respondent gender"
pct: "Percentage value"
base_n: "Sample size"
```

### Good (teaches)
```
gender: "Respondent gender: Male, Female, Other gender identity, Prefer not to say.
         4 values. 'Other gender identity' and 'Prefer not to say' have small bases —
         flag n<30 as unreliable when cross-tabulating"

pct: "Survey result as decimal (0.12 = 12%). Weighted percentage"

base_n: "Weighted base (sample size) for this segment. Differs per segment —
         use for statistical reliability. Bases under 100 warrant a small-base caveat"
```

### The Pattern

Every description should answer up to three questions:

1. **What is it?** — The field definition (everyone does this)
2. **What are the values?** — Enumeration or range (most people skip this)
3. **What do I DO with it?** — Usage guidance, gotchas, relationships to other columns (almost nobody does this)

### Examples by Column Type

**Identifiers:**
```
"Unique respondent identifier (UUID). Use COUNT(DISTINCT respondent_id) for sample sizes"
```

**Demographics (STRING):**
```
"Respondent age band. 5 groups: 18-24, 25-34, 35-44, 45-54, 55-64.
 Under-18s and over-65s screened out. Use GROUP BY age_group for age analysis"
```

**Multi-select binary (BOOL):**
```
"Q1 multi-select: 'Done physical activity (e.g. gone for a walk etc.)'.
 TRUE = selected. COUNTIF/COUNT(*) for percentage.
 Percentages across action_ columns sum >100%"
```

**Likert scale (INT64):**
```
"Q2 Likert: 'I can imagine myself taking action...'.
 1=Strongly disagree, 2=Somewhat disagree, 3=Neither, 4=Somewhat agree, 5=Strongly agree.
 6=Prefer not to say — EXCLUDE from mean calculations with WHERE col <= 5.
 Higher = more agreement"
```

**Pre-calculated metrics (FLOAT64):**
```
"Survey result as decimal (0.12 = 12%). Weighted percentage.
 NEVER use SUM() or COUNT() to recalculate — this is already computed"
```

**Ordering columns (INT64):**
```
"Display order within the question (1-based).
 Use ORDER BY label_order for chart axis ordering — never alphabetically"
```

**Boolean flags:**
```
"True for aggregate rows like 'Net: Agree'.
 These summarise other responses and should not be summed with them"
```

**Mutually exclusive indicators:**
```
"'None of the above'. TRUE = took no listed action.
 Mutually exclusive with other action_ columns in practice"
```

### First-Column Rule

The first description for each question group should be the richest — it teaches the pattern. Subsequent columns in the same group can be shorter since the reader has context.

```python
# First action column — full teaching description
"action_physical_activity": (
    "Q1 multi-select: 'Done physical activity (e.g. gone for a walk etc.)'. "
    "TRUE = selected. COUNTIF/COUNT(*) for percentage. "
    "Percentages across action_ columns sum >100%"
),
# Subsequent action columns — shorter, pattern established
"action_talked_to_someone": "Q1 multi-select: 'Talked to someone I trust'. TRUE = selected",
```

## Label Conventions

Labels are key-value strings (lowercase, hyphens allowed). Use for:

| Key | Purpose | Example values |
|-----|---------|---------------|
| `survey_org` | Data provider | `ohid`, `itv`, `yougov` |
| `data_shape` | Processing level | `user-level`, `pre-aggregated`, `raw` |
| `respondents` | Sample size | `1320`, `2249` |
| `fieldwork_year` | When collected | `2023`, `2025` |
| `wave` | Survey wave | `1`, `2026-q1` |
| `pipeline` | How it was built | `mandoline`, `manual` |

## Table Description Template

```
{Survey name} ({data level}). {Panel type} (n={sample size}).
Fieldwork: {dates}. Covers {topic summary}.
{Format description — one row per what}.
{Key usage notes — the things that trip people up}.
{Caveats — small bases, weighting, multi-select behavior}.
Column descriptions contain full question wording and usage guidance.
```

## Verification Checks

Every built table needs automated verification. Patterns:

| Check | SQL pattern | Why |
|-------|------------|-----|
| Row count | `COUNT(*) = expected` | Transformation didn't drop/duplicate |
| No NULL demographics | `COUNTIF(col IS NULL) = 0` | Decoding covered all codes |
| Distinct value counts | `COUNT(DISTINCT col) = expected` | All categories decoded |
| Value ranges | `MIN(col) >= low AND MAX(col) <= high` | No out-of-range values |
| Unique IDs | `COUNT(*) = COUNT(DISTINCT id)` | No duplicates |
| Decoded values work | `COUNTIF(col IS NULL) = 0` for decoded columns | CASE covered all inputs |
| Placeholder handling | `COUNTIF(col IS NULL) = expected_nulls` | Sentinels converted to NULL |
