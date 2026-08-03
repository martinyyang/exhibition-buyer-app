import { createClient } from '@supabase/supabase-js';

const supabaseUrl = 'https://ppwjblvnixqeympfcqgs.supabase.co';
const supabaseServiceKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InBwd2pibHZuaXhxZXltcGZjcWdzIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc4NDY0NDYyNCwiZXhwIjoyMTAwMjIwNjI0fQ.SmNmMeqMlb23r9v0hw8Em1FwtApm7vhcujsDUryuhyI';

const supabase = createClient(supabaseUrl, supabaseServiceKey);

async function cleanupDatabase() {
  try {
    console.log('🧹 Starting database cleanup...\n');

    // 1. 删除所有照片
    console.log('1️⃣ Deleting all photos...');
    const { error: photosError } = await supabase
      .from('photos')
      .delete()
      .neq('id', '00000000-0000-0000-0000-000000000000');

    if (photosError) {
      console.error('❌ Photos deletion failed:', photosError);
    } else {
      console.log('✅ All photos deleted\n');
    }

    // 2. 删除所有展位
    console.log('2️⃣ Deleting all booths...');
    const { error: boothsError } = await supabase
      .from('booths')
      .delete()
      .neq('id', '00000000-0000-0000-0000-000000000000');

    if (boothsError) {
      console.error('❌ Booths deletion failed:', boothsError);
    } else {
      console.log('✅ All booths deleted\n');
    }

    // 3. 删除所有事件
    console.log('3️⃣ Deleting all events...');
    const { error: eventsError } = await supabase
      .from('events')
      .delete()
      .neq('id', '00000000-0000-0000-0000-000000000000');

    if (eventsError) {
      console.error('❌ Events deletion failed:', eventsError);
    } else {
      console.log('✅ All events deleted\n');
    }

    // 4. 删除所有用户记录（从 users 表）
    console.log('4️⃣ Deleting all users from users table...');
    const { error: usersError } = await supabase
      .from('users')
      .delete()
      .neq('id', '00000000-0000-0000-0000-000000000000');

    if (usersError) {
      console.error('❌ Users deletion failed:', usersError);
    } else {
      console.log('✅ All users deleted from users table\n');
    }

    // 5. 删除所有汇率设置
    console.log('5️⃣ Deleting all exchange settings...');
    const { error: exchangeError } = await supabase
      .from('exchange_settings')
      .delete()
      .neq('id', '00000000-0000-0000-0000-000000000000');

    if (exchangeError) {
      console.error('❌ Exchange settings deletion failed:', exchangeError);
    } else {
      console.log('✅ All exchange settings deleted\n');
    }

    // 6. 删除所有公式历史
    console.log('6️⃣ Deleting all formula history...');
    const { error: formulaError } = await supabase
      .from('formula_history')
      .delete()
      .neq('id', '00000000-0000-0000-0000-000000000000');

    if (formulaError) {
      console.error('❌ Formula history deletion failed:', formulaError);
    } else {
      console.log('✅ All formula history deleted\n');
    }

    // 7. 删除所有团队
    console.log('7️⃣ Deleting all teams...');
    const { error: teamsError } = await supabase
      .from('teams')
      .delete()
      .neq('id', '00000000-0000-0000-0000-000000000000');

    if (teamsError) {
      console.error('❌ Teams deletion failed:', teamsError);
    } else {
      console.log('✅ All teams deleted\n');
    }

    // 8. 删除 auth.users 中的用户（需要调用 admin API）
    console.log('8️⃣ Deleting auth users...');
    const { data: authUsers, error: listError } = await supabase.auth.admin.listUsers();

    if (listError) {
      console.error('❌ Failed to list auth users:', listError);
    } else {
      console.log(`Found ${authUsers.users.length} auth users to delete`);

      for (const user of authUsers.users) {
        const { error: deleteError } = await supabase.auth.admin.deleteUser(user.id);
        if (deleteError) {
          console.error(`❌ Failed to delete auth user ${user.email}:`, deleteError);
        } else {
          console.log(`✅ Deleted auth user: ${user.email}`);
        }
      }
      console.log('✅ All auth users deleted\n');
    }

    console.log('🎉 Database cleanup completed successfully!');

  } catch (error) {
    console.error('❌ Cleanup failed:', error);
  }
}

cleanupDatabase();
