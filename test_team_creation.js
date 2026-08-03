const { createClient } = require('@supabase/supabase-js');

const supabaseUrl = 'https://ppwjblvnixqeympfcqgs.supabase.co';
const anonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InBwd2pibHZuaXhxZXltcGZjcWdzIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODQ2NDQ2MjQsImV4cCI6MjEwMDIyMDYyNH0.LhLw3KUTKrLXry6Qst5nLWKsGCxEewW5XW1Pc6QrzEE';

const supabase = createClient(supabaseUrl, anonKey);

async function testTeamCreation() {
  console.log('Testing team creation with authenticated user...\n');

  try {
    // 1. 注册一个测试用户
    console.log('1. Registering test user...');
    const { data: authData, error: authError } = await supabase.auth.signUp({
      email: `test_${Date.now()}@example.com`,
      password: 'Test123456',
    });

    if (authError) {
      console.error('❌ Auth error:', authError.message);
      return;
    }

    console.log('✓ User registered:', authData.user.id);

    // 2. 创建用户记录
    console.log('\n2. Creating user record...');
    const { error: userError } = await supabase.from('users').insert({
      id: authData.user.id,
      email: authData.user.email,
      role: 'remote',
      team_id: null,
    });

    if (userError) {
      console.error('❌ User record error:', userError.message);
      return;
    }

    console.log('✓ User record created');

    // 3. 尝试创建团队
    console.log('\n3. Creating team...');
    const teamName = `TestTeam_${Date.now()}`;
    const { data: teamData, error: teamError } = await supabase
      .from('teams')
      .insert({ name: teamName })
      .select()
      .single();

    if (teamError) {
      console.error('❌ Team creation error:', teamError);
      console.error('Error details:', JSON.stringify(teamError, null, 2));
      return;
    }

    console.log('✓ Team created:', teamData);

    // 4. 更新用户的 team_id
    console.log('\n4. Updating user team_id...');
    const { data: updateData, error: updateError, count } = await supabase
      .from('users')
      .update({ team_id: teamData.id })
      .eq('id', authData.user.id);

    if (updateError) {
      console.error('❌ Update error:', updateError);
      console.error('Error details:', JSON.stringify(updateError, null, 2));
      return;
    }

    console.log('✓ User team_id updated');
    console.log('Update affected rows:', count);

    // 4.5 直接查询验证
    console.log('\n4.5. Direct query to verify...');
    const { data: directQuery, error: directError } = await supabase
      .from('users')
      .select('id, email, team_id')
      .eq('id', authData.user.id)
      .single();

    if (directError) {
      console.error('❌ Direct query error:', directError);
    } else {
      console.log('Direct query result:', directQuery);
    }

    // 5. 验证最终状态
    console.log('\n5. Verifying final state...');
    const { data: finalUser, error: finalError } = await supabase
      .from('users')
      .select('*, teams(*)')
      .eq('id', authData.user.id)
      .single();

    if (finalError) {
      console.error('❌ Verification error:', finalError.message);
      return;
    }

    console.log('✅ Final state:', JSON.stringify(finalUser, null, 2));

  } catch (error) {
    console.error('❌ Unexpected error:', error);
  }
}

testTeamCreation();
