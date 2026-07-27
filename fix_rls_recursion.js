const https = require('https');

const supabaseUrl = 'ppwjblvnixqeympfcqgs.supabase.co';
const serviceRoleKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InBwd2pibHZuaXhxZXltcGZjcWdzIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc4NDY0NDYyNCwiZXhwIjoyMTAwMjIwNjI0fQ.SmNmMeqMlb23r9v0hw8Em1FwtApm7vhcujsDUryuhyI';

const sql = `
DROP POLICY IF EXISTS "Team members can view team members" ON users;

CREATE POLICY "Users can view own data"
  ON users FOR SELECT
  TO authenticated
  USING (id = auth.uid());
`;

const data = JSON.stringify({ query: sql });

const options = {
  hostname: supabaseUrl,
  port: 443,
  path: '/rest/v1/rpc/exec_sql',
  method: 'POST',
  headers: {
    'Content-Type': 'application/json',
    'Content-Length': data.length,
    'apikey': serviceRoleKey,
    'Authorization': `Bearer ${serviceRoleKey}`
  }
};

console.log('🔧 Fixing RLS policy recursion...\n');

const req = https.request(options, (res) => {
  let body = '';

  res.on('data', (chunk) => {
    body += chunk;
  });

  res.on('end', () => {
    if (res.statusCode === 200 || res.statusCode === 204) {
      console.log('✅ RLS policy fixed successfully!');
      console.log('\nNext steps:');
      console.log('1. Refresh the web app: https://martinyyang.github.io/exhibition-buyer-app/');
      console.log('2. The infinite recursion error should be gone');
    } else {
      console.log('❌ Error:', res.statusCode);
      console.log('Response:', body);
      console.log('\n⚠️  exec_sql function might not exist. Manual fix required:');
      console.log('1. Go to: https://supabase.com/dashboard/project/ppwjblvnixqeympfcqgs/sql/new');
      console.log('2. Run the SQL from fix_rls_now.sql file');
    }
  });
});

req.on('error', (error) => {
  console.error('❌ Request failed:', error.message);
});

req.write(data);
req.end();
