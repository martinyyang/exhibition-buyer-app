// Complete browser simulation test
const SUPABASE_URL = 'https://ppwjblvnixqeympfcqgs.supabase.co';
const SUPABASE_ANON_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InBwd2pibHZuaXhxZXltcGZjcWdzIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODQ2NDQ2MjQsImV4cCI6MjEwMDIyMDYyNH0.LhLw3KUTKrLXry6Qst5nLWKsGCxEewW5XW1Pc6QrzEE';

async function simulateCompleteFlow() {
  console.log('='.repeat(60));
  console.log('完整流程测试：注册 -> 登录 -> 创建团队 -> 进入应用');
  console.log('='.repeat(60));

  // Step 1: Login with existing test account
  console.log('\n【步骤 1】用测试账号登录 1@123.com');
  const loginResponse = await fetch(`${SUPABASE_URL}/auth/v1/token?grant_type=password`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'apikey': SUPABASE_ANON_KEY
    },
    body: JSON.stringify({
      email: '1@123.com',
      password: '123456'
    })
  });

  const loginData = await loginResponse.json();

  if (loginResponse.status !== 200) {
    console.log('❌ 登录失败:', loginData);
    return;
  }

  console.log('✅ 登录成功!');
  console.log('   User ID:', loginData.user.id);
  const accessToken = loginData.access_token;

  // Step 2: Check if user has profile in users table
  console.log('\n【步骤 2】检查 users 表中的用户记录');

  await new Promise(resolve => setTimeout(resolve, 500)); // 等待 500ms

  let userProfile = await fetch(`${SUPABASE_URL}/rest/v1/users?id=eq.${loginData.user.id}`, {
    headers: {
      'apikey': SUPABASE_ANON_KEY,
      'Authorization': `Bearer ${accessToken}`
    }
  });

  let userData = await userProfile.json();

  if (userData.length === 0) {
    console.log('⚠️  users 表中没有记录，尝试创建...');

    // Create user record (simulate what auth_service does)
    const createUserResponse = await fetch(`${SUPABASE_URL}/rest/v1/users`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'apikey': SUPABASE_ANON_KEY,
        'Authorization': `Bearer ${accessToken}`,
        'Prefer': 'return=representation'
      },
      body: JSON.stringify({
        id: loginData.user.id,
        email: loginData.user.email,
        role: 'buyer'
      })
    });

    if (createUserResponse.status === 201) {
      console.log('✅ 用户记录创建成功');
      const newUserData = await createUserResponse.json();
      userData = newUserData;
    } else {
      const error = await createUserResponse.json();
      console.log('❌ 创建用户记录失败:', error);
      return;
    }
  } else {
    console.log('✅ 用户记录存在');
    console.log('   Email:', userData[0].email);
    console.log('   Role:', userData[0].role);
    console.log('   Team ID:', userData[0].team_id || '(null - 需要加入团队)');
  }

  // Step 3: Check if user has team
  const user = Array.isArray(userData) ? userData[0] : userData;

  if (user.team_id) {
    console.log('\n【步骤 3】用户已有团队');
    console.log('✅ 可以直接进入应用!');
    console.log('   Team ID:', user.team_id);
    return;
  }

  // Step 4: Create a team
  console.log('\n【步骤 3】用户没有团队，创建新团队...');
  const teamName = `Test Team ${Date.now()}`;
  const teamPassword = 'TestPass123';

  const createTeamResponse = await fetch(`${SUPABASE_URL}/rest/v1/teams`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'apikey': SUPABASE_ANON_KEY,
      'Authorization': `Bearer ${accessToken}`,
      'Prefer': 'return=representation'
    },
    body: JSON.stringify({
      name: teamName,
      password: teamPassword
    })
  });

  if (createTeamResponse.status !== 201) {
    const error = await createTeamResponse.json();
    console.log('❌ 创建团队失败:', error);
    return;
  }

  const teamData = await createTeamResponse.json();
  console.log('✅ 团队创建成功!');
  console.log('   Team ID:', teamData[0].id);
  console.log('   Team Name:', teamData[0].name);
  console.log('   Invite Code:', teamData[0].id.substring(0, 6).toUpperCase());

  // Step 5: Join the team
  console.log('\n【步骤 4】加入团队 (更新 user.team_id)...');

  const updateUserResponse = await fetch(`${SUPABASE_URL}/rest/v1/users?id=eq.${loginData.user.id}`, {
    method: 'PATCH',
    headers: {
      'Content-Type': 'application/json',
      'apikey': SUPABASE_ANON_KEY,
      'Authorization': `Bearer ${accessToken}`
    },
    body: JSON.stringify({
      team_id: teamData[0].id
    })
  });

  if (updateUserResponse.status === 204) {
    console.log('✅ 成功加入团队!');
  } else {
    const error = await updateUserResponse.json();
    console.log('❌ 加入团队失败:', error);
    return;
  }

  // Step 6: Verify final state
  console.log('\n【步骤 5】验证最终状态...');

  const finalUserResponse = await fetch(`${SUPABASE_URL}/rest/v1/users?id=eq.${loginData.user.id}`, {
    headers: {
      'apikey': SUPABASE_ANON_KEY,
      'Authorization': `Bearer ${accessToken}`
    }
  });

  const finalUserData = await finalUserResponse.json();

  if (finalUserData[0] && finalUserData[0].team_id) {
    console.log('\n' + '='.repeat(60));
    console.log('🎉🎉🎉 完整流程测试成功！🎉🎉🎉');
    console.log('='.repeat(60));
    console.log('✅ 用户已登录');
    console.log('✅ 用户记录已创建');
    console.log('✅ 团队已创建并加入');
    console.log('✅ 现在可以进入应用主界面 (/events)');
    console.log('='.repeat(60));
  } else {
    console.log('\n❌ 最终状态验证失败');
    console.log('用户数据:', finalUserData);
  }
}

simulateCompleteFlow().catch(err => {
  console.error('\n💥 测试过程出错:', err.message);
});
