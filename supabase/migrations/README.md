# Database Migrations

## How to Apply Migrations

### Option 1: Using Supabase Dashboard (Recommended)

1. Go to your Supabase project dashboard
2. Navigate to **SQL Editor**
3. Copy the content of the migration file
4. Paste and execute the SQL

### Option 2: Using Supabase CLI

```bash
# Login to Supabase
supabase login

# Link to your project
supabase link --project-ref YOUR_PROJECT_REF

# Push migrations
supabase db push
```

## Latest Migration

**20260801000000_add_is_purchased_to_flags.sql**
- Adds `is_purchased` column to `flags` table
- Sets default value to `false`
- Creates index for performance

## Quick Apply (Copy-Paste to SQL Editor)

```sql
-- Add is_purchased column to flags table
ALTER TABLE flags
ADD COLUMN IF NOT EXISTS is_purchased BOOLEAN DEFAULT false NOT NULL;

-- Add comment to the column
COMMENT ON COLUMN flags.is_purchased IS 'Indicates whether the product has been purchased';

-- Create index for faster queries on purchased flags
CREATE INDEX IF NOT EXISTS idx_flags_is_purchased ON flags(is_purchased);
```

After running this migration, the app will be able to track which products have been purchased.
