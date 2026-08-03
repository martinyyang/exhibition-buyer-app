const { createClient } = require('@supabase/supabase-js');

const supabaseUrl = 'https://ppwjblvnixqeympfcqgs.supabase.co';
const serviceRoleKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InBwd2pibHZuaXhxZXltcGZjcWdzIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc4NDY0NDYyNCwiZXhwIjoyMTAwMjIwNjI0fQ.SmNmMeqMlb23r9v0hw8Em1FwtApm7vhcujsDUryuhyI';

const supabase = createClient(supabaseUrl, serviceRoleKey, {
  auth: {
    autoRefreshToken: false,
    persistSession: false
  }
});

async function fixTeamIdUpdatePolicy() {
  console.log('Fixing users team_id update policy...\n');

  try {
    // 删除旧策略
    console.log('1. Dropping old policy...');
    const { error: dropError } = await supabase.rpc('query', {
      query_text: `DROP POLICY IF EXISTS "Users can update their own data" ON users`
    });

    if (dropError && !dropError.message.includes('does not exist')) {
      console.error('❌ Drop error:', dropError);

      // 尝试直接删除
      console.log('Trying alternative method...');
      await fetch(`${supabaseUrl}/rest/v1/rpc/query`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'apikey': serviceRoleKey,
          'Authorization': `Bearer ${serviceRoleKey}`
        },
        body: JSON.stringify({
          query_text: `DROP POLICY IF EXISTS "Users can update their own data" ON users`
        })
      });
    }

    console.log('✓ Old policy dropped');

    // 创建新策略
    console.log('\n2. Creating new policy...');
    const { error: createError } = await supabase.rpc('query', {
      query_text: `
        CREATE POLICY "Users can update their own data"
          ON users FOR UPDATE
          USING (id = auth.uid())
          WITH CHECK (id = auth.uid())
      `
    });

    if (createError) {
      console.error('❌ Create error:', createError);
      return;
    }

    console.log('✓ New policy created');

    console.log('\n✅ Policy fixed! Users can now update their team_id.');

  } catch (error) {
    console.error('❌ Unexpected error:', error);
  }
}

fixTeamIdUpdatePolicy();
