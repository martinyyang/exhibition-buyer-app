const https = require('https');

const projectRef = 'ppwjblvnixqeympfcqgs';
const serviceRoleKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InBwd2pibHZuaXhxZXltcGZjcWdzIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc4NDY0NDYyNCwiZXhwIjoyMTAwMjIwNjI0fQ.SmNmMeqMlb23r9v0hw8Em1FwtApm7vhcujsDUryuhyI';

// 使用 pg_temp 模式临时创建执行函数
const setupAndExecute = `
-- 临时创建执行函数
CREATE OR REPLACE FUNCTION pg_temp.execute_ddl(sql_text text)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  EXECUTE sql_text;
END;
$$;

-- 执行修复
SELECT pg_temp.execute_ddl($ddl$
  DROP POLICY IF EXISTS "Team members can view team members" ON users;

  CREATE POLICY "Users can view own data"
    ON users FOR SELECT
    TO authenticated
    USING (id = auth.uid());
$ddl$);
`;

function executeSQL(sql) {
  return new Promise((resolve, reject) => {
    const data = JSON.stringify({ query: sql });

    const options = {
      hostname: `${projectRef}.supabase.co`,
      port: 443,
      path: '/rest/v1/rpc/query',
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Content-Length': Buffer.byteLength(data),
        'apikey': serviceRoleKey,
        'Authorization': `Bearer ${serviceRoleKey}`,
        'Prefer': 'params=single-object'
      }
    };

    const req = https.request(options, (res) => {
      let body = '';
      res.on('data', (chunk) => { body += chunk; });
      res.on('end', () => {
        if (res.statusCode >= 200 && res.statusCode < 300) {
          resolve({ statusCode: res.statusCode, body });
        } else {
          reject({ statusCode: res.statusCode, body });
        }
      });
    });

    req.on('error', reject);
    req.write(data);
    req.end();
  });
}

console.log('🔧 Attempting to fix RLS policy via pg_temp...\n');

executeSQL(setupAndExecute)
  .then(() => {
    console.log('✅ RLS policy fixed successfully!');
    console.log('\nRefresh the app: https://martinyyang.github.io/exhibition-buyer-app/');
  })
  .catch((err) => {
    console.log('❌ pg_temp approach failed:', err.statusCode);
    console.log('Response:', err.body);
    console.log('\n🔄 Will need manual fix via Supabase Dashboard SQL Editor');
  });
