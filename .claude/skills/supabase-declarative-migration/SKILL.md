---
name: supabase-declarative-migration
description: Apply declarative DDL pattern for Supabase database migrations without ALTER statements
dependencies: supabase-cli
---

# Supabase Declarative DDL Migration

This skill enables Claude to manage Supabase database migrations using a declarative DDL approach, following Supabase's [diffing-changes pattern](https://supabase.com/docs/guides/deployment/database-migrations#diffing-changes).

## When to Use This Skill

Use this skill when:
- Adding columns to existing tables
- Adding indexes or constraints
- Updating RLS (Row Level Security) policies
- Modifying table definitions in Supabase projects

## Core Principles

### 1. Declarative DDL Over Imperative DDL

**DO NOT use ALTER statements**. Instead, directly edit the `CREATE TABLE` definitions in existing migration files.

**Why?**
- Supabase's diffing-changes approach treats migration files as the source of truth
- Keeps schema definitions clean and readable
- Avoids accumulation of incremental ALTER statements

### 2. Edit Existing Migration Files

**DO NOT create new migration files** for schema changes. Edit the original table definition files.

**Example:**
```sql
-- Before: supabase/migrations/003_create_tenant_members_table.sql
CREATE TABLE IF NOT EXISTS public.tenant_members
(
    id         UUID DEFAULT gen_random_uuid(),
    tenant_id  UUID NOT NULL,
    name       TEXT NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    PRIMARY KEY (id, tenant_id)
);

-- After: Add new columns directly to the CREATE TABLE statement
CREATE TABLE IF NOT EXISTS public.tenant_members
(
    id              UUID DEFAULT gen_random_uuid(),
    tenant_id       UUID NOT NULL,
    user_id         UUID NOT NULL,        -- ✅ New column
    name            TEXT NOT NULL,
    email           TEXT NOT NULL DEFAULT '',  -- ✅ New column
    role            TEXT NOT NULL DEFAULT 'viewer',  -- ✅ New column
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    PRIMARY KEY (id, tenant_id),
    CONSTRAINT fk_tenant_members_tenant   -- ✅ New constraint
        FOREIGN KEY (tenant_id)
        REFERENCES public.tenants (id)
        ON DELETE CASCADE
);
```

### 3. Maintain Idempotency

Always use `IF NOT EXISTS` or `IF EXISTS` clauses to ensure migrations can be safely re-run.

```sql
-- ✅ Idempotent
CREATE TABLE IF NOT EXISTS public.my_table (...);
CREATE INDEX IF NOT EXISTS idx_name ON public.my_table (column);
DROP POLICY IF EXISTS policy_name ON public.my_table;

-- ❌ Not idempotent
CREATE TABLE public.my_table (...);
CREATE INDEX idx_name ON public.my_table (column);
```

## Migration Workflow

### Step 1: Edit Schema Definition

Directly edit the existing migration file (e.g., `003_create_tenant_members_table.sql`).

**Adding Columns:**
```sql
CREATE TABLE IF NOT EXISTS public.tenant_members
(
    -- ... existing columns ...
    new_column TEXT NOT NULL DEFAULT 'default_value',  -- Add here
    -- ... existing columns ...
);
```

**Adding Indexes:**
```sql
-- Add after the CREATE TABLE statement
CREATE INDEX IF NOT EXISTS idx_tenant_members_new_column
    ON public.tenant_members (new_column);
```

**Adding Constraints:**
```sql
CREATE TABLE IF NOT EXISTS public.tenant_members
(
    -- ... columns ...
    CONSTRAINT fk_constraint_name
        FOREIGN KEY (column_name)
        REFERENCES public.other_table (id)
        ON DELETE CASCADE
);
```

### Step 2: Update RLS Policies (if needed)

RLS policies should also be managed declaratively:

```sql
-- Drop existing policy
DROP POLICY IF EXISTS old_policy_name ON public.tenant_members;

-- Create new policy
CREATE POLICY new_policy_name
    ON public.tenant_members
    FOR ALL
    TO authenticated
    USING (
        tenant_id IN (
            SELECT tenant_id
            FROM public.tenant_members
            WHERE user_id = auth.uid()
              AND role = 'admin'
              AND deleted_at IS NULL
        )
    );
```

### Step 3: Inform User to Apply Migration

**Claude's Role:** Edit migration files only. **DO NOT** execute database commands.

**User's Role:** Apply migrations to the database.

After editing migration files, inform the user with:

```
Migration files have been updated. Please run the following command to apply changes:

**Local Testing:**
supabase db reset

**Production Deployment (after testing):**
supabase db push
```

## What Claude Does

✅ **Claude WILL:**
- Edit existing migration files in `supabase/migrations/`
- Add columns, indexes, and constraints declaratively
- Update RLS policies
- Ensure idempotency with `IF NOT EXISTS` / `IF EXISTS`
- Provide clear instructions for users to apply migrations

❌ **Claude WILL NOT:**
- Execute `supabase db reset`
- Execute `supabase db push`
- Run any Supabase CLI commands
- Apply changes to databases (local or production)

## Common Patterns

### Pattern: Adding Multiple Columns

```sql
CREATE TABLE IF NOT EXISTS public.documents
(
    id              UUID DEFAULT gen_random_uuid(),
    tenant_id       UUID NOT NULL,
    title           TEXT NOT NULL,
    content         TEXT,
    author_id       UUID NOT NULL,           -- ✅ New
    status          TEXT DEFAULT 'draft',    -- ✅ New
    published_at    TIMESTAMPTZ,             -- ✅ New
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    PRIMARY KEY (id, tenant_id)
);

-- Add indexes for new columns
CREATE INDEX IF NOT EXISTS idx_documents_author_id
    ON public.documents (author_id);
CREATE INDEX IF NOT EXISTS idx_documents_status
    ON public.documents (status);
```

### Pattern: Adding Foreign Key Constraints

```sql
CREATE TABLE IF NOT EXISTS public.tenant_members
(
    id         UUID DEFAULT gen_random_uuid(),
    tenant_id  UUID NOT NULL,
    user_id    UUID NOT NULL,
    PRIMARY KEY (id, tenant_id),
    -- ✅ Add foreign key in table definition
    CONSTRAINT fk_tenant_members_tenant
        FOREIGN KEY (tenant_id)
        REFERENCES public.tenants (id)
        ON DELETE CASCADE
);
```

### Pattern: Unique Constraints with Partial Indexes

```sql
-- Unique constraint for non-deleted records only
CREATE UNIQUE INDEX IF NOT EXISTS idx_tenant_members_user_tenant
    ON public.tenant_members (user_id, tenant_id)
    WHERE deleted_at IS NULL;
```

## Important Warnings

### ❌ DO NOT Do These

1. **Do not use ALTER statements:**
   ```sql
   -- ❌ Wrong
   ALTER TABLE public.tenant_members ADD COLUMN email TEXT;
   ALTER TABLE public.tenant_members ADD CONSTRAINT fk_...;
   ```

2. **Do not create new migration files for schema changes:**
   ```bash
   # ❌ Wrong
   # Creating 007_add_email_to_tenant_members.sql
   ```

3. **Do not delete existing migration files:**
   - Migration history must be preserved

4. **Do not use DO $$ blocks for conditional DDL (avoid if possible):**
   ```sql
   -- ❌ Avoid (not declarative)
   DO $$
   BEGIN
       IF NOT EXISTS (...) THEN
           ALTER TABLE ...
       END IF;
   END $$;
   ```

### ✅ DO These Instead

1. **Edit the original CREATE TABLE statement:**
   ```sql
   -- ✅ Correct: Edit 003_create_tenant_members_table.sql
   CREATE TABLE IF NOT EXISTS public.tenant_members
   (
       -- ... existing columns ...
       email TEXT NOT NULL DEFAULT '',  -- Add new column here
       -- ... existing columns ...
   );
   ```

2. **Use idempotent DDL:**
   ```sql
   -- ✅ Correct
   CREATE INDEX IF NOT EXISTS idx_name ON table (column);
   DROP POLICY IF EXISTS policy_name ON table;
   ```

## Example: Complete Migration Update

**Before (003_create_tenant_members_table.sql):**
```sql
CREATE TABLE IF NOT EXISTS public.tenant_members
(
    id         UUID DEFAULT gen_random_uuid(),
    tenant_id  UUID NOT NULL,
    name       TEXT NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    PRIMARY KEY (id, tenant_id)
);

ALTER TABLE public.tenant_members ENABLE ROW LEVEL SECURITY;

CREATE POLICY "service_role_all"
    ON public.tenant_members
    FOR ALL
    TO service_role
    USING (true);
```

**After (003_create_tenant_members_table.sql):**
```sql
CREATE TABLE IF NOT EXISTS public.tenant_members
(
    id              UUID DEFAULT gen_random_uuid(),
    tenant_id       UUID NOT NULL,
    user_id         UUID NOT NULL,              -- ✅ Added
    name            TEXT NOT NULL,
    email           TEXT NOT NULL DEFAULT '',   -- ✅ Added
    role            TEXT NOT NULL DEFAULT 'viewer',  -- ✅ Added
    saasus_user_id  TEXT,                       -- ✅ Added
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    PRIMARY KEY (id, tenant_id),
    CONSTRAINT fk_tenant_members_tenant         -- ✅ Added
        FOREIGN KEY (tenant_id)
        REFERENCES public.tenants (id)
        ON DELETE CASCADE
);

-- ✅ Added indexes
CREATE INDEX IF NOT EXISTS idx_tenant_members_user_id
    ON public.tenant_members (user_id);
CREATE INDEX IF NOT EXISTS idx_tenant_members_email
    ON public.tenant_members (email);
CREATE UNIQUE INDEX IF NOT EXISTS idx_tenant_members_user_tenant
    ON public.tenant_members (user_id, tenant_id)
    WHERE deleted_at IS NULL;

ALTER TABLE public.tenant_members ENABLE ROW LEVEL SECURITY;

-- ✅ Updated RLS policies declaratively
DROP POLICY IF EXISTS "service_role_all" ON public.tenant_members;

CREATE POLICY service_role_all_tenant_members
    ON public.tenant_members
    FOR ALL
    TO service_role
    USING (true)
    WITH CHECK (true);

CREATE POLICY admin_manage_tenant_members
    ON public.tenant_members
    FOR ALL
    TO authenticated
    USING (
        tenant_id IN (
            SELECT tenant_id
            FROM public.tenant_members
            WHERE user_id = auth.uid()
              AND role = 'admin'
              AND deleted_at IS NULL
        )
    )
    WITH CHECK (
        tenant_id IN (
            SELECT tenant_id
            FROM public.tenant_members
            WHERE user_id = auth.uid()
              AND role = 'admin'
              AND deleted_at IS NULL
        )
    );
```

## User Commands Reference

After Claude edits migration files, the user should run:

### Local Testing
```bash
supabase db reset
```
This command resets the local database and re-applies all migrations from scratch.

### Production Deployment
```bash
supabase db push
```
⚠️ **Warning:** Only run this after thoroughly testing locally. This applies migrations to your production Supabase project.

## Reference Documentation

- [Supabase Database Migrations - Diffing Changes](https://supabase.com/docs/guides/deployment/database-migrations#diffing-changes)
- [Supabase CLI - db diff](https://supabase.com/docs/reference/cli/supabase-db-diff)
- [Supabase CLI - db reset](https://supabase.com/docs/reference/cli/supabase-db-reset)
- [Supabase CLI - db push](https://supabase.com/docs/reference/cli/supabase-db-push)

## Summary

- **Declarative DDL**: Edit `CREATE TABLE` definitions directly, not `ALTER` statements
- **Edit existing files**: Don't create new migration files for schema changes
- **Idempotency**: Always use `IF NOT EXISTS` / `IF EXISTS`
- **Claude edits only**: Database application is the user's responsibility
- **Test locally**: Run `supabase db reset` before production deployment
