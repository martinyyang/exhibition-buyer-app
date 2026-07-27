const { Client } = require('pg');

// Supabase 数据库直连字符串 (使用 service_role key 作为密码)
const serviceRoleKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InBwd2pibHZuaXhxZXltcGZjcWdzIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc4NDY0NDYyNCwiZXhwIjoyMTAwMjIwNjI0fQ.SmNmMeqMlb23r9v0hw8Em1FwtApm7vhcujsDUryuhyI';
const connectionString = `postgresql://postgres:${serviceRoleKey}@db.ppwjblvnixqeympfcqgs.supabase.co:6543/postgres`;

const sql = `
DROP POLICY IF EXISTS "Team members can view team members" ON users;

CREATE POLICY "Users can view own data"
  ON users FOR SELECT
  TO authenticated
  USING (id = auth.uid());
`;

async function fixRLS() {
  const client = new Client({
    connectionString,
    ssl: { rejectUnauthorized: false }
  });

  try {
    console.log('🔧 Connecting to Supabase database...\n');
    await client.connect();

    console.log('✅ Connected! Executing RLS fix...\n');
    await client.query(sql);

    console.log('✅ RLS policy fixed successfully!\n');
    console.log('🌐 Refresh the app: https://martinyyang.github.io/exhibition-buyer-app/');
  } catch (error) {
    console.error('❌ Error:', error.message);
    console.error('\nDetails:', error);
    process.exit(1);
  } finally {
    await client.end();
  }
}

fixRLS();
