const { createClient } = require('@supabase/supabase-js');

const supabaseUrl = 'https://ppwjblvnixqeympfcqgs.supabase.co';
const serviceRoleKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InBwd2pibHZuaXhxZXltcGZjcWdzIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc4NDY0NDYyNCwiZXhwIjoyMTAwMjIwNjI0fQ.SmNmMeqMlb23r9v0hw8Em1FwtApm7vhcujsDUryuhyI';

const supabase = createClient(supabaseUrl, serviceRoleKey, {
  auth: {
    autoRefreshToken: false,
    persistSession: false
  }
});

async function fixRLSPolicies() {
  console.log('Starting RLS policy fix...');

  try {
    // 1. Drop existing problematic policies
    console.log('\n1. Dropping existing policies...');

    await supabase.rpc('exec_sql', {
      query: `
        -- Drop ALL existing policies for teams table
        DROP POLICY IF EXISTS "Authenticated users can create teams" ON public.teams;
        DROP POLICY IF EXISTS "Users can view their team" ON public.teams;
        DROP POLICY IF EXISTS "Users can update their team" ON public.teams;
        DROP POLICY IF EXISTS "Authenticated users can view all teams" ON public.teams;
        DROP POLICY IF EXISTS "Team members can update own team" ON public.teams;

        -- Drop ALL existing policies for users table
        DROP POLICY IF EXISTS "Users can view their own data" ON public.users;
        DROP POLICY IF EXISTS "Users can update their own data" ON public.users;
        DROP POLICY IF EXISTS "Users can view team members" ON public.users;
        DROP POLICY IF EXISTS "Service role full access" ON public.users;
      `
    });

    console.log('✓ Dropped existing policies');

    // 2. Create new correct policies for teams table
    console.log('\n2. Creating new policies for teams table...');

    await supabase.rpc('exec_sql', {
      query: `
        -- Enable RLS on teams
        ALTER TABLE public.teams ENABLE ROW LEVEL SECURITY;

        -- Authenticated users can insert teams
        CREATE POLICY "Authenticated users can create teams"
        ON public.teams
        FOR INSERT
        TO authenticated
        WITH CHECK (true);

        -- Users can view teams they belong to
        CREATE POLICY "Users can view their team"
        ON public.teams
        FOR SELECT
        TO authenticated
        USING (
          id IN (
            SELECT team_id FROM public.users WHERE id = auth.uid()
          )
        );

        -- Users can update teams they belong to
        CREATE POLICY "Users can update their team"
        ON public.teams
        FOR UPDATE
        TO authenticated
        USING (
          id IN (
            SELECT team_id FROM public.users WHERE id = auth.uid()
          )
        );
      `
    });

    console.log('✓ Created policies for teams table');

    // 3. Create new correct policies for users table (avoiding recursion)
    console.log('\n3. Creating new policies for users table...');

    await supabase.rpc('exec_sql', {
      query: `
        -- Enable RLS on users
        ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;

        -- Users can view their own data (no recursion - direct auth.uid() check)
        CREATE POLICY "Users can view their own data"
        ON public.users
        FOR SELECT
        TO authenticated
        USING (id = auth.uid());

        -- Users can update their own data (including team_id)
        CREATE POLICY "Users can update their own data"
        ON public.users
        FOR UPDATE
        TO authenticated
        USING (id = auth.uid())
        WITH CHECK (id = auth.uid());

        -- Users can view team members (direct team_id comparison)
        CREATE POLICY "Users can view team members"
        ON public.users
        FOR SELECT
        TO authenticated
        USING (
          team_id = (
            SELECT team_id FROM public.users WHERE id = auth.uid() LIMIT 1
          )
        );

        -- Service role can do everything (for registration)
        CREATE POLICY "Service role full access"
        ON public.users
        FOR ALL
        TO service_role
        USING (true)
        WITH CHECK (true);
      `
    });

    console.log('✓ Created policies for users table');

    console.log('\n✅ RLS policies fixed successfully!');
    console.log('\nNext steps:');
    console.log('1. Test registration at http://localhost:8000/');
    console.log('2. Check if infinite recursion is resolved');

  } catch (error) {
    console.error('❌ Error fixing RLS policies:', error.message);
    console.error('Details:', error);
  }
}

fixRLSPolicies();
