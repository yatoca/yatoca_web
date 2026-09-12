# Legacy PostgreSQL data archive

The production website no longer depends on PostgreSQL. Historical database data is retained separately for reporting and recovery.

## Primary database backup

Backup file used during migration:

```text
dump-yatocadb2-202609111829.sql
```

Despite the `.sql` suffix, `file` identifies it as a **PostgreSQL custom-format database dump**, not a plain SQL script.

Observed archive size at migration time: approximately 226 MB.

SHA-256 recorded during migration:

```text
6061d0f4ae5a15d8c80d6fd8b5d4f941b06af59e1a8242e0d46e6d745218ce36
```

Store the checksum next to every long-term copy. A matching checksum verifies that the archive bytes have not changed.

## Human-readable exports retained

The final business exports include:

```text
participantes_todos_cabildos.csv
participantes_comentarios_todos_cabildos.csv
unique-participant_contact.csv
opiniones_web.csv
opiniones_web_hero.csv
```

Historical `opiniones_web` and hero rows are **not** imported into DynamoDB. DynamoDB begins with post-cutover production submissions.

## Recovery posture

The custom PostgreSQL dump is the canonical relational backup. CSVs are reporting/inspection exports and should not be treated as a complete replacement for relational restoration.

Before permanently deleting the old managed PostgreSQL instance, perform one disposable restore test into a compatible PostgreSQL environment and compare table/row counts.

A custom-format archive is normally restored with `pg_restore`, not by piping it to `psql`.

Example outline:

```bash
createdb yatocadb2
pg_restore --no-owner --no-privileges --dbname yatocadb2 dump-yatocadb2-202609111829.sql
```

The original database used extension-backed types/features. A real restore test should confirm required extensions are available in the target PostgreSQL service before the old instance is permanently destroyed.

## Privacy

Participant/raw database exports contain personal information. Keep database and CSV backups encrypted, access-controlled and outside the public application repository.

### PostgreSQL restore prerequisites

Source PostgreSQL version: 15.19

Required extensions:

- vector
- citext
- unaccent
- pg_trgm

The backup is a PostgreSQL custom-format archive (`PGDMP`), despite its
`.sql` filename. Restore it using `pg_restore`, not `psql`.

A complete recovery test was performed on 2026-09-12 using PostgreSQL 15
with pgvector. The restore completed with zero errors and zero warnings.

Validated recovered structure:

- 63 public tables
- 65 foreign keys
- 111 public indexes
- 4 user-defined triggers

Because the required extensions are installed into the `public` schema
before restoration, exclude the dump's `SCHEMA - public` TOC entry during
restore.