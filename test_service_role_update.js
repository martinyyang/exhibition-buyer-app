const { createClient } = require('@supabase/supabase-js');

const supabaseUrl = 'https://ppwjblvnixqeympfcqgs.supabase.co';
const anonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InBwd2pibHZuaXhxZXltcGZjcWdzIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODQ2NDQ2MjQsImV4cCI6MjEwMDIyMDYyNH0.LhLw3KUTKrLXry6Qst5nLWKsGCxEewW5XW1Pc6QrzEE';
const serviceRoleKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InBwd2pibHZuaXhxZXltcGZjcWdzIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc4NDY0NDYyNCwiZXhwIjoyMTAwMjIwNjI0fQ.SmNmMeqMlb23r9v0hw8Em1FwtApm7vhcujsDUryuhyI';

const supabaseAnon = createClient(supabaseUrl, anonKey);
const supabaseService = createClient(supabaseUrl, serviceRoleKey);

async function testServiceRoleUpdate() {
  console.log('Testing update with service role vs anon...\n');

  try {
    // 1. 注册用户
    console.log('1. Registering test user with anon client...');
    const { data: authData, error: authError } = await supabaseAnon.auth.signUp({
      email: `test_${Date.now()}@example.com`,
      password: 'Test123456',
    });

    if (authError) {
      console.error('❌ Auth error:', authError.message);
      return;
    }

    const userId = authData.user.id;
    console.log('✓ User registered:', userId);

    // 2. 用 service role 创建用户记录
    console.log('\n2. Creating user record with service role...');
    const { error: userError } = await supabaseService.from('users').insert({
      id: userId,
      email: authData.user.email,
      role: 'remote',
      team_id: null,
    });

    if (userError) {
      console.error('❌ User record error:', userError.message);
      return;
    }

    console.log('✓ User record created');

    // 3. 创建团队
    console.log('\n3. Creating team with anon client (authenticated)...');
    const teamName = `TestTeam_${Date.now()}`;
    const { data: teamData, error: teamError } = await supabaseAnon
      .from('teams')
      .insert({ name: teamName })
      .select()
      .single();

    if (teamError) {
      console.error('❌ Team creation error:', teamError);
      return;
    }

    console.log('✓ Team created:', teamData.id);

    // 3.5 验证当前会话
    console.log('\n3.5. Verifying current session...');
    const { data: sessionData, error: sessionError } = await supabaseAnon.auth.getSession();

    if (sessionError) {
      console.error('❌ Session error:', sessionError);
    } else {
      console.log('Current session user:', sessionData.session?.user?.id);
      console.log('Expected user ID:', userId);
      console.log('IDs match:', sessionData.session?.user?.id === userId);
    }

    // 4. 用 anon client (authenticated) 更新 team_id
    console.log('\n4. Updating team_id with anon client (authenticated)...');
    const { data: anonUpdateData, error: anonUpdateError, status, statusText } = await supabaseAnon
      .from('users')
      .update({ team_id: teamData.id })
      .eq('id', userId)
      .select();

    console.log('Response status:', status, statusText);

    if (anonUpdateError) {
      console.error('❌ Anon update error:', anonUpdateError);
    } else {
      console.log('✓ Anon update result:', anonUpdateData);
    }

    // 5. 验证（用 service role）
    console.log('\n5. Verifying with service role...');
    const { data: verifyData, error: verifyError } = await supabaseService
      .from('users')
      .select('id, email, team_id')
      .eq('id', userId)
      .single();

    if (verifyError) {
      console.error('❌ Verify error:', verifyError);
    } else {
      console.log('Service role sees:', verifyData);
    }

    // 6. 如果 anon 失败，用 service role 更新
    if (verifyData.team_id === null) {
      console.log('\n6. Anon update failed. Trying with service role...');
      const { data: serviceUpdateData, error: serviceUpdateError } = await supabaseService
        .from('users')
        .update({ team_id: teamData.id })
        .eq('id', userId);

      if (serviceUpdateError) {
        console.error('❌ Service update error:', serviceUpdateError);
      } else {
        console.log('✓ Service role update succeeded');

        // 再次验证
        const { data: finalData } = await supabaseService
          .from('users')
          .select('id, email, team_id')
          .eq('id', userId)
          .single();

        console.log('Final state:', finalData);
      }
    }

  } catch (error) {
    console.error('❌ Unexpected error:', error);
  }
}

testServiceRoleUpdate();
