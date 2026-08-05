// Create a test account for user
const SUPABASE_URL = 'https://ppwjblvnixqeympfcqgs.supabase.co';
const SUPABASE_ANON_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InBwd2pibHZuaXhxZXltcGZjcWdzIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODQ2NDQ2MjQsImV4cCI6MjEwMDIyMDYyNH0.LhLw3KUTKrLXry6Qst5nLWKsGCxEewW5XW1Pc6QrzEE';

async function createTestAccount() {
  const testEmail = '1@123.com';
  const testPassword = '123456';

  console.log('\n=== Creating test account: 1@123.com ===');

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

  if (response.status === 200) {
    console.log('✅ Account created successfully!');
    console.log('Email:', testEmail);
    console.log('Password:', testPassword);
    console.log('User ID:', data.user.id);
  } else {
    console.log('❌ Failed to create account');
    console.log('Error:', JSON.stringify(data, null, 2));

    if (data.msg && data.msg.includes('already registered')) {
      console.log('\n=== Account already exists, trying to login ===');
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

      if (loginResponse.status === 200) {
        console.log('✅ Login successful with existing account!');
      } else {
        console.log('❌ Login failed - password may be incorrect');
        console.log('Suggestion: Use password reset feature at https://exhibition-buyer-app.pages.dev');
      }
    }
  }
}

createTestAccount();
