const { createClient } = require('@supabase/supabase-js');

const supabaseUrl = 'https://ppwjblvnixqeympfcqgs.supabase.co';
const serviceRoleKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InBwd2pibHZuaXhxZXltcGZjcWdzIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc4NDY0NDYyNCwiZXhwIjoyMTAwMjIwNjI0fQ.SmNmMeqMlb23r9v0hw8Em1FwtApm7vhcujsDUryuhyI';

const supabase = createClient(supabaseUrl, serviceRoleKey, {
  auth: {
    autoRefreshToken: false,
    persistSession: false
  }
});

async function checkPolicies() {
  console.log('Checking current RLS policies on users table...\n');

  try {
    const { data, error } = await supabase.rpc('exec_sql', {
      query: `
        SELECT
          polname AS policy_name,
          polcmd AS command,
          polpermissive AS permissive,
          polroles::regrole[] AS roles,
          pg_get_expr(polqual, polrelid) AS using_expression,
          pg_get_expr(polwithcheck, polrelid) AS with_check_expression
        FROM pg_policy
        WHERE polrelid = 'public.users'::regclass
        ORDER BY polname;
      `
    });

    if (error) {
      console.error('❌ Error:', error);
      return;
    }

    console.log('Current policies on users table:');
    console.log(JSON.stringify(data, null, 2));

  } catch (error) {
    console.error('❌ Unexpected error:', error);
  }
}

checkPolicies();
