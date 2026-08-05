// Complete user flow test: Register -> Login -> Team Selection
const SUPABASE_URL = 'https://ppwjblvnixqeympfcqgs.supabase.co';
const SUPABASE_ANON_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InBwd2pibHZuaXhxZXltcGZjcWdzIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODQ2NDQ2MjQsImV4cCI6MjEwMDIyMDYyNH0.LhLw3KUTKrLXry6Qst5nLWKsGCxEewW5XW1Pc6QrzEE';

async function testCompleteFlow() {
  // Step 1: Register
  const testEmail = `flow_test_${Date.now()}@example.com`;
  const testPassword = 'TestPass123';

  console.log('=== Step 1: Register ===');
  console.log('Email:', testEmail);

  const signupResponse = await fetch(`${SUPABASE_URL}/auth/v1/signup`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'apikey': SUPABASE_ANON_KEY
    },
    body: JSON.stringify({
      email: testEmail,
      password: testPassword
    })
  });

  const signupData = await signupResponse.json();
  if (signupResponse.status !== 200) {
    console.log('❌ Registration failed:', signupData);
    return;
  }
  console.log('✅ Registration successful');
  console.log('User ID:', signupData.user.id);
  const accessToken = signupData.access_token;

  // Step 2: Check users table
  console.log('\n=== Step 2: Check users table ===');
  const usersResponse = await fetch(`${SUPABASE_URL}/rest/v1/users?id=eq.${signupData.user.id}`, {
    headers: {
      'apikey': SUPABASE_ANON_KEY,
      'Authorization': `Bearer ${accessToken}`
    }
  });

  const usersData = await usersResponse.json();
  console.log('Status:', usersResponse.status);
  console.log('Users data:', JSON.stringify(usersData, null, 2));

  if (usersResponse.status === 200 && usersData.length > 0) {
    console.log('✅ User profile exists in database');
    console.log('Team ID:', usersData[0].team_id || 'null (expected for new user)');
  } else {
    console.log('⚠️ User profile not found - may need to be created by app');
  }

  // Step 3: Create a team
  console.log('\n=== Step 3: Create a team ===');
  const teamName = `Test Team ${Date.now()}`;
  const teamPassword = 'TestPassword123';

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
      password: teamPassword,
      created_by: signupData.user.id
    })
  });

  const teamData = await createTeamResponse.json();
  console.log('Status:', createTeamResponse.status);

  if (createTeamResponse.status === 201) {
    console.log('✅ Team created successfully');
    console.log('Team ID:', teamData[0].id);
    console.log('Team Name:', teamData[0].name);
    console.log('Invite Code:', teamData[0].id.substring(0, 6).toUpperCase());

    // Step 4: Update user's team_id
    console.log('\n=== Step 4: Join team (update user team_id) ===');
    const updateUserResponse = await fetch(`${SUPABASE_URL}/rest/v1/users?id=eq.${signupData.user.id}`, {
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

    console.log('Update Status:', updateUserResponse.status);
    if (updateUserResponse.status === 204) {
      console.log('✅ User joined team successfully');
    } else {
      const errorData = await updateUserResponse.json();
      console.log('❌ Failed to join team:', errorData);
    }

    // Step 5: Verify final state
    console.log('\n=== Step 5: Verify final user state ===');
    const finalUserResponse = await fetch(`${SUPABASE_URL}/rest/v1/users?id=eq.${signupData.user.id}`, {
      headers: {
        'apikey': SUPABASE_ANON_KEY,
        'Authorization': `Bearer ${accessToken}`
      }
    });

    const finalUserData = await finalUserResponse.json();
    console.log('Final user state:', JSON.stringify(finalUserData, null, 2));

    if (finalUserData[0] && finalUserData[0].team_id) {
      console.log('\n✅✅✅ COMPLETE FLOW SUCCESS ✅✅✅');
      console.log('User is ready to access the app!');
    } else {
      console.log('\n⚠️ User has no team - would be stuck on team selection screen');
    }
  } else {
    console.log('❌ Team creation failed:', teamData);
  }
}

testCompleteFlow();
