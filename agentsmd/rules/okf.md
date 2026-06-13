---
name: okf
description: Open Knowledge Format — reference for creating, maintaining, and reading OKF bundles
paths: ["**/*.md"]
---

# Open Knowledge Format (OKF)

OKF is a minimalist spec for encoding knowledge as markdown files with YAML frontmatter. Documents are
human-readable, agent-parseable, and version-control compatible. There is no central schema registry and
no required tooling — plain text readers can consume any OKF bundle.

Canonical spec: [GoogleCloudPlatform/knowledge-catalog — okf/SPEC.md](https://github.com/GoogleCloudPlatform/knowledge-catalog/blob/main/okf/SPEC.md)

## Bundle Structure

A bundle is a directory tree of `.md` files. Two filenames are reserved:

| File | Role |
| --- | --- |
| `index.md` | Directory listing — no frontmatter; grouped `*` lists of `[title](url) - description` entries |
| `log.md` | Change history — newest-first; `## YYYY-MM-DD` headers; **bold** lead word per entry |

All other `.md` files are concept documents. Subdirectory nesting is unlimited and producer-defined.
Declare the target spec version in root `index.md` frontmatter with `okf_version: "0.1"`.

## Concept Document Schema

### Frontmatter

Every concept document opens with a `---`-delimited YAML block.

| Field | Status | Type | Notes |
| --- | --- | --- | --- |
| `type` | **Required** | string | Free-form label; not registered centrally. Consumers must tolerate unknown types. |
| `title` | Recommended | string | Human-readable display name; consumers may derive from filename if absent. |
| `description` | Recommended | string | Single sentence — powers index pages and search previews. |
| `resource` | Recommended | URI string | Uniquely identifies the underlying asset; omit for abstract concepts. |
| `tags` | Recommended | list of strings | Cross-cutting categorization (domain, status, technology, etc.). |
| `timestamp` | Recommended | ISO 8601 datetime | Last meaningful modification, e.g. `2026-06-13T22:45:00Z`. |
| *(custom)* | Allowed | any | Consumers must preserve unknown keys when round-tripping and must not reject them. |

### Body

Prefer structural markdown over freeform prose. Conventional section names (none mandatory):

| Section | Purpose |
| --- | --- |
| `# Schema` | Column or field descriptions, typically as a table |
| `# Examples` | Concrete usage in fenced code blocks |
| `# Citations` | Numbered references: `[1] [Title](url)` — absolute or bundle-relative |

## Creating OKF Documents

1. Open with `---` YAML frontmatter. Always include `type`.
2. Add `title` and `description` — these are the primary signals for indexes and search.
3. Add `resource` when the document maps to a real asset (table, API endpoint, file, service).
4. Add `tags` for cross-cutting grouping.
5. Set `timestamp` to the current ISO 8601 datetime.
6. Write the body with headings, lists, tables, and fenced code blocks. Minimize freeform prose.
7. Link to related concepts using **bundle-relative paths**: `[customers table](/tables/customers.md)`.

Example concept document:

```markdown
---
type: BigQuery Table
title: orders
description: Fact table tracking all customer purchase events.
resource: bigquery://myproject/mydataset/orders
tags: [finance, fact-table, bigquery]
timestamp: 2026-06-13T22:45:00Z
---

# Schema

| Column | Type | Notes |
| --- | --- | --- |
| order_id | STRING | Primary key |
| customer_id | STRING | FK → [customers](/tables/customers.md) |
| amount_usd | FLOAT64 | Transaction total |
```

## Maintaining OKF Documents

- **Update `timestamp`** on every meaningful change.
- **Append to `log.md`** — add a `## YYYY-MM-DD` header if the date is new, then bullet entries with a bold
  lead word (`**Update**`, `**Creation**`, `**Deprecation**`). Newest entries go at the top.
- **Preserve all frontmatter keys** — including unknown or custom ones — when editing. Never strip fields.
- **Update `index.md`** in the affected directory whenever concept files are added or removed.
- Do not reject or refuse to process documents with missing optional fields, broken links, or unknown `type`.

Log entry example:

```markdown
## 2026-06-13

* **Update**: Revised orders schema; added `refund_amount_usd` column.
* **Creation**: Added orders.md concept document.
```

## Reading OKF Documents

1. Parse the `---` frontmatter block first. `type` identifies what kind of concept this is.
2. Use `description` as the one-sentence summary for any index or preview context.
3. Follow bundle-relative links (`/path/to/concept.md`) to traverse the knowledge graph.
4. **Tolerate broken links** — a link whose target does not exist in the bundle is not malformed.
5. Use `index.md` for directory overviews; synthesize one on-the-fly if absent.
6. If `okf_version` is unrecognized, attempt best-effort parsing rather than refusing the bundle.
7. Treat unrecognized frontmatter keys as custom metadata — do not discard them.

## Migrating from Obsidian

| Obsidian | OKF equivalent | Action |
| --- | --- | --- |
| `[[concept]]` wikilink | `[concept](/path/concept.md)` | Rewrite to standard markdown with bundle-relative path |
| YAML frontmatter keys | Custom OKF fields | Keep as-is; OKF preserves unknown keys |
| `tags:` list | `tags:` list | No change |
| `date:` field | `timestamp:` (ISO 8601) | Rename key; convert `YYYY-MM-DD` → `YYYY-MM-DDT00:00:00Z` if needed |
| Folder structure | Bundle subdirectory structure | Preserve as-is; add `index.md` files progressively |
| *(no equivalent)* | `type:` | **Add `type` — the only hard requirement OKF adds over plain markdown** |

## Conformance Checklist

- [ ] Every non-reserved `.md` file has parseable YAML frontmatter
- [ ] Every frontmatter block has a non-empty `type` field
- [ ] `index.md` files (if present) use grouped `* [title](url) - description` lists with no frontmatter
- [ ] `log.md` (if present) is newest-first with `## YYYY-MM-DD` section headers
- [ ] `okf_version: "0.1"` declared in root `index.md` frontmatter
