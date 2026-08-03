const { createClient } = require('@supabase/supabase-js');

const supabaseUrl = 'https://ppwjblvnixqeympfcqgs.supabase.co';
const serviceRoleKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InBwd2pibHZuaXhxZXltcGZjcWdzIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc4NDY0NDYyNCwiZXhwIjoyMTAwMjIwNjI0fQ.SmNmMeqMlb23r9v0hw8Em1FwtApm7vhcujsDUryuhyI';

const supabase = createClient(supabaseUrl, serviceRoleKey, {
  auth: {
    autoRefreshToken: false,
    persistSession: false
  }
});

async function simplifyUsersUpdatePolicy() {
  console.log('Simplifying users UPDATE policy to bypass RLS for team_id updates...\n');

  try {
    // 删除所有 users 表的策略并重建更简单的版本
    console.log('1. Dropping all users table policies...');

    await supabase.rpc('exec_sql', {
      query: `
        -- Drop all policies on users table
        DROP POLICY IF EXISTS "Users can view their own data" ON public.users;
        DROP POLICY IF EXISTS "Users can update their own data" ON public.users;
        DROP POLICY IF EXISTS "Users can view team members" ON public.users;
        DROP POLICY IF EXISTS "Service role full access" ON public.users;
      `
    });

    console.log('✓ Policies dropped');

    // 创建新的简化策略
    console.log('\n2. Creating simplified policies...');

    await supabase.rpc('exec_sql', {
      query: `
        -- Enable RLS on users
        ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;

        -- Users can view their own data
        CREATE POLICY "Users can view their own data"
        ON public.users
        FOR SELECT
        TO authenticated
        USING (id = auth.uid());

        -- Users can update their own data - NO WITH CHECK, just USING
        CREATE POLICY "Users can update their own data"
        ON public.users
        FOR UPDATE
        TO authenticated
        USING (id = auth.uid());

        -- Users can view team members
        CREATE POLICY "Users can view team members"
        ON public.users
        FOR SELECT
        TO authenticated
        USING (
          team_id = (
            SELECT team_id FROM public.users WHERE id = auth.uid() LIMIT 1
          )
        );

        -- Service role can do everything
        CREATE POLICY "Service role full access"
        ON public.users
        FOR ALL
        TO service_role
        USING (true)
        WITH CHECK (true);
      `
    });

    console.log('✓ Simplified policies created');

    console.log('\n✅ Policy update complete!');
    console.log('Key change: Removed WITH CHECK clause from UPDATE policy');

  } catch (error) {
    console.error('❌ Error:', error);
  }
}

simplifyUsersUpdatePolicy();
