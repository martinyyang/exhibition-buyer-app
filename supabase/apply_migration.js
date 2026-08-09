const { createClient } = require('@supabase/supabase-js');
const fs = require('fs');
const path = require('path');

const SUPABASE_URL = process.env.SUPABASE_URL;
const SUPABASE_SERVICE_KEY = process.env.SUPABASE_SERVICE_ROLE_KEY;

if (!SUPABASE_URL || !SUPABASE_SERVICE_KEY) {
  console.error('Missing SUPABASE_URL or SUPABASE_SERVICE_ROLE_KEY');
  console.error('Usage: SUPABASE_URL=xxx SUPABASE_SERVICE_ROLE_KEY=xxx node apply_migration.js <migration_file>');
  process.exit(1);
}

const migrationFile = process.argv[2];
if (!migrationFile) {
  console.error('Please provide migration file name');
  console.error('Usage: node apply_migration.js 20260808000001_add_booth_cover_image.sql');
  process.exit(1);
}

const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_KEY);

async function applyMigration() {
  try {
    const migrationPath = path.join(__dirname, 'migrations', migrationFile);

    if (!fs.existsSync(migrationPath)) {
      console.error(`Migration file not found: ${migrationPath}`);
      process.exit(1);
    }

    const sql = fs.readFileSync(migrationPath, 'utf8');

    console.log('=== Applying Migration ===');
    console.log(`File: ${migrationFile}`);
    console.log('SQL:');
    console.log(sql);
    console.log('\n=== Executing... ===');

    const { data, error } = await supabase.rpc('exec_sql', { sql_query: sql });

    if (error) {
      console.error('❌ Migration failed:', error.message);
      console.error('Details:', error);
      process.exit(1);
    }

    console.log('✅ Migration applied successfully!');
    console.log('Result:', data);

    // Verify the column was added
    console.log('\n=== Verifying... ===');
    const { data: booths, error: verifyError } = await supabase
      .from('booths')
      .select('id, booth_number, cover_image_url')
      .limit(1);

    if (verifyError) {
      console.error('⚠️  Verification failed:', verifyError.message);
    } else {
      console.log('✅ Column exists! Sample query successful.');
      console.log('Sample booth:', booths);
    }

  } catch (err) {
    console.error('❌ Exception:', err.message);
    process.exit(1);
  }
}

applyMigration();
