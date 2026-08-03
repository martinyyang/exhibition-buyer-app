const { createClient } = require('@supabase/supabase-js');
const fs = require('fs');
const path = require('path');

const supabaseUrl = 'https://ppwjblvnixqeympfcqgs.supabase.co';
const serviceRoleKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InBwd2pibHZuaXhxZXltcGZjcWdzIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc4NDY0NDYyNCwiZXhwIjoyMTAwMjIwNjI0fQ.SmNmMeqMlb23r9v0hw8Em1FwtApm7vhcujsDUryuhyI';

const supabase = createClient(supabaseUrl, serviceRoleKey, {
  auth: {
    autoRefreshToken: false,
    persistSession: false
  }
});

async function applyMigration() {
  console.log('Applying migration: fix_users_team_id_update.sql\n');

  try {
    const migrationPath = path.join(__dirname, 'supabase/migrations/20260803000000_fix_users_team_id_update.sql');
    const sql = fs.readFileSync(migrationPath, 'utf8');

    console.log('Executing SQL:');
    console.log(sql);
    console.log('\n---\n');

    // Split by semicolons and execute each statement
    const statements = sql
      .split(';')
      .map(s => s.trim())
      .filter(s => s.length > 0 && !s.startsWith('--'));

    for (const statement of statements) {
      console.log(`Executing: ${statement.substring(0, 50)}...`);
      const { data, error } = await supabase.rpc('query', {
        query_text: statement
      });

      if (error) {
        console.error('❌ Error:', error);
        return;
      }
      console.log('✓ Success');
    }

    console.log('\n✅ Migration applied successfully!');

  } catch (error) {
    console.error('❌ Unexpected error:', error.message);
  }
}

applyMigration();
