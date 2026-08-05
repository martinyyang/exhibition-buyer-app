// Test authentication flow against production
const SUPABASE_URL = 'https://ppwjblvnixqeympfcqgs.supabase.co';
const SUPABASE_ANON_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InBwd2pibHZuaXhxZXltcGZjcWdzIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODQ2NDQ2MjQsImV4cCI6MjEwMDIyMDYyNH0.LhLw3KUTKrLXry6Qst5nLWKsGCxEewW5XW1Pc6QrzEE';

// Test 1: Try to login with existing user
async function testLogin() {
  console.log('\n=== Test 1: Login with 1@123.com ===');

  const response = await fetch(`${SUPABASE_URL}/auth/v1/token?grant_type=password`, {
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

  const data = await response.json();
  console.log('Status:', response.status);
  console.log('Response:', JSON.stringify(data, null, 2));

  return data;
}

// Test 2: Register a new user
async function testRegister() {
  console.log('\n=== Test 2: Register new user ===');

  const testEmail = `test_${Date.now()}@example.com`;
  const testPassword = 'TestPass123';

  console.log('Registering:', testEmail);

  const response = await fetch(`${SUPABASE_URL}/auth/v1/signup`, {
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

  const data = await response.json();
  console.log('Status:', response.status);
  console.log('Response:', JSON.stringify(data, null, 2));

  if (data.access_token) {
    // Try to login immediately
    console.log('\n=== Test 3: Login with newly registered user ===');
    const loginResponse = await fetch(`${SUPABASE_URL}/auth/v1/token?grant_type=password`, {
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

    const loginData = await loginResponse.json();
    console.log('Login Status:', loginResponse.status);
    console.log('Login Response:', JSON.stringify(loginData, null, 2));
  }

  return data;
}

// Test 3: Check if user exists in database
async function checkUser(email, accessToken) {
  console.log('\n=== Test 4: Check user in database ===');

  const response = await fetch(`${SUPABASE_URL}/rest/v1/users?email=eq.${email}`, {
    headers: {
      'apikey': SUPABASE_ANON_KEY,
      'Authorization': `Bearer ${accessToken}`
    }
  });

  const data = await response.json();
  console.log('Status:', response.status);
  console.log('User data:', JSON.stringify(data, null, 2));
}

// Run all tests
(async () => {
  try {
    await testLogin();
    await testRegister();
  } catch (error) {
    console.error('Error:', error.message);
  }
})();
