const { createClient } = require('@supabase/supabase-js');
require('dotenv').config();

// 使用ANON key模拟用户操作
const supabaseAnon = createClient(
  process.env.SUPABASE_URL,
  process.env.SUPABASE_ANON_KEY
);

// 使用Service Role key模拟后端操作
const supabaseService = createClient(
  process.env.SUPABASE_URL,
  process.env.SUPABASE_SERVICE_ROLE_KEY
);

async function testTeamJoinFlow() {
  console.log('=== 测试团队加入流程（模拟实际用户操作）===\n');

  const email = 'remote@123.com';
  const password = 'remote123456';

  try {
    // 1. 模拟用户登录
    console.log('步骤1: 用户登录...');
    const { data: authData, error: authError } = await supabaseAnon.auth.signInWithPassword({
      email,
      password,
    });

    if (authError) {
      console.error('❌ 登录失败:', authError.message);
      return;
    }

    console.log('✓ 登录成功');
    console.log(`  用户ID: ${authData.user.id}\n`);

    // 2. 尝试查询所有团队（测试RLS策略）
    console.log('步骤2: 查询所有团队（测试是否应用了RLS修复）...');
    const { data: teams, error: teamsError } = await supabaseAnon
      .from('teams')
      .select('*');

    if (teamsError) {
      console.error('❌ 查询团队失败:', teamsError.message);
      console.log('\n⚠️ 问题诊断: RLS策略未修复！');
      console.log('   需要在Supabase Dashboard执行修复SQL:');
      console.log('   supabase/migrations/20260730000000_fix_teams_rls_for_joining.sql\n');
    } else {
      console.log(`✓ 查询到 ${teams.length} 个团队:`);
      teams.forEach(team => {
        console.log(`  - ${team.name} (${team.id})`);
      });
      console.log();
    }

    // 3. 尝试更新自己的team_id（模拟joinTeam操作）
    console.log('步骤3: 尝试更新自己的team_id...');

    if (teams && teams.length > 0) {
      const targetTeamId = teams[0].id;

      const { data: updateData, error: updateError } = await supabaseAnon
        .from('users')
        .update({ team_id: targetTeamId })
        .eq('id', authData.user.id)
        .select();

      if (updateError) {
        console.error('❌ 更新team_id失败:', updateError.message);
        console.log('\n⚠️ 问题诊断: users表的UPDATE策略可能有问题');
        console.log('   当前策略: "Users can update own data"');
        console.log('   可能的问题:');
        console.log('   1. 策略可能限制了可更新的字段');
        console.log('   2. team_id字段可能需要额外的验证');
        console.log('   3. 需要检查是否有触发器或约束阻止更新\n');

        // 检查当前用户信息
        const { data: currentUser } = await supabaseAnon
          .from('users')
          .select('*')
          .eq('id', authData.user.id)
          .single();

        console.log('当前用户信息:', currentUser);
      } else {
        console.log('✓ 成功更新team_id!');
        console.log('更新后:', updateData);
      }
    }

    // 登出
    await supabaseAnon.auth.signOut();

  } catch (error) {
    console.error('测试失败:', error);
  }
}

async function checkRLSPolicies() {
  console.log('\n=== 检查users表的RLS策略 ===\n');

  // 查询当前的RLS策略（需要service role）
  const { data, error } = await supabaseService.rpc('exec', {
    sql: `
      SELECT tablename, policyname, cmd, qual, with_check
      FROM pg_policies
      WHERE schemaname = 'public' AND tablename = 'users';
    `
  }).catch(() => ({ data: null, error: null }));

  if (data) {
    console.log('Users表的RLS策略:');
    console.log(JSON.stringify(data, null, 2));
  } else {
    console.log('无法直接查询RLS策略（需要特殊权限）');
    console.log('请手动检查 supabase/migrations/20260722000000_initial_schema.sql');
  }
}

async function main() {
  await testTeamJoinFlow();
  await checkRLSPolicies();
}

main().catch(console.error);
