// Test RLS policies directly
const SUPABASE_URL = 'https://ppwjblvnixqeympfcqgs.supabase.co';
const SUPABASE_ANON_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InBwd2pibHZuaXhxZXltcGZjcWdzIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODQ2NDQ2MjQsImV4cCI6MjEwMDIyMDYyNH0.LhLw3KUTKrLXry6Qst5nLWKsGCxEewW5XW1Pc6QrzEE';

async function testRLSPolicies() {
  console.log('=== Testing RLS Policies ===\n');

  // Login first
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
  const accessToken = loginData.access_token;
  const userId = loginData.user.id;

  console.log('Logged in as:', userId);

  // Test 1: Try to update team_id with different methods
  console.log('\n--- Test 1: PATCH with eq filter ---');
  const patch1 = await fetch(`${SUPABASE_URL}/rest/v1/users?id=eq.${userId}`, {
    method: 'PATCH',
    headers: {
      'Content-Type': 'application/json',
      'apikey': SUPABASE_ANON_KEY,
      'Authorization': `Bearer ${accessToken}`,
      'Prefer': 'return=representation'
    },
    body: JSON.stringify({
      team_id: 'ce4d7da3-9ae5-4dfd-9803-a1f41be9ab34'
    })
  });

  console.log('Status:', patch1.status);
  const patch1Data = await patch1.text();
  console.log('Response:', patch1Data);

  // Check if actually updated
  const check1 = await fetch(`${SUPABASE_URL}/rest/v1/users?id=eq.${userId}`, {
    headers: {
      'apikey': SUPABASE_ANON_KEY,
      'Authorization': `Bearer ${accessToken}`
    }
  });
  const check1Data = await check1.json();
  console.log('After update, team_id is:', check1Data[0]?.team_id);

  // Test 2: Check RLS policies via pg_policies
  console.log('\n--- Test 2: Query RLS policies (service role needed) ---');
  console.log('(Skipping - needs service_role key)');

  // Test 3: Try updating other fields
  console.log('\n--- Test 3: Update daily_color (test if UPDATE works at all) ---');
  const patch2 = await fetch(`${SUPABASE_URL}/rest/v1/users?id=eq.${userId}`, {
    method: 'PATCH',
    headers: {
      'Content-Type': 'application/json',
      'apikey': SUPABASE_ANON_KEY,
      'Authorization': `Bearer ${accessToken}`,
      'Prefer': 'return=representation'
    },
    body: JSON.stringify({
      daily_color: 'green'
    })
  });

  console.log('Status:', patch2.status);
  const patch2Data = await patch2.text();
  console.log('Response:', patch2Data);

  const check2 = await fetch(`${SUPABASE_URL}/rest/v1/users?id=eq.${userId}`, {
    headers: {
      'apikey': SUPABASE_ANON_KEY,
      'Authorization': `Bearer ${accessToken}`
    }
  });
  const check2Data = await check2.json();
  console.log('After update, daily_color is:', check2Data[0]?.daily_color);

  // Test 4: Check if policy name conflicts exist
  console.log('\n--- Test 4: Try UPDATE with explicit columns ---');
  const patch3 = await fetch(`${SUPABASE_URL}/rest/v1/users?id=eq.${userId}`, {
    method: 'PATCH',
    headers: {
      'Content-Type': 'application/json',
      'apikey': SUPABASE_ANON_KEY,
      'Authorization': `Bearer ${accessToken}`,
      'Prefer': 'return=representation',
      'Prefer': 'resolution=merge-duplicates'
    },
    body: JSON.stringify({
      team_id: 'ce4d7da3-9ae5-4dfd-9803-a1f41be9ab34',
      daily_color: 'blue'
    })
  });

  console.log('Status:', patch3.status);
  const patch3Text = await patch3.text();
  console.log('Response:', patch3Text);

  const check3 = await fetch(`${SUPABASE_URL}/rest/v1/users?id=eq.${userId}`, {
    headers: {
      'apikey': SUPABASE_ANON_KEY,
      'Authorization': `Bearer ${accessToken}`
    }
  });
  const check3Data = await check3.json();
  console.log('Final state:', JSON.stringify(check3Data[0], null, 2));
}

testRLSPolicies().catch(err => {
  console.error('Error:', err.message);
});
