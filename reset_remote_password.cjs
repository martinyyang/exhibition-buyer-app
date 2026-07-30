const { createClient } = require('@supabase/supabase-js');
require('dotenv').config();

const supabase = createClient(
  process.env.SUPABASE_URL,
  process.env.SUPABASE_SERVICE_ROLE_KEY
);

async function resetRemotePassword() {
  console.log('=== 重置 remote@123.com 密码 ===\n');

  try {
    // 获取remote用户ID
    const { data: remoteUser, error: userError } = await supabase
      .from('users')
      .select('*')
      .eq('email', 'remote@123.com')
      .single();

    if (userError || !remoteUser) {
      console.error('找不到remote用户:', userError);
      return;
    }

    console.log('找到用户:');
    console.log(`  ID: ${remoteUser.id}`);
    console.log(`  邮箱: ${remoteUser.email}`);
    console.log(`  角色: ${remoteUser.role}`);
    console.log(`  团队ID: ${remoteUser.team_id || '(未分配)'}\n`);

    // 使用Supabase Admin API重置密码
    const newPassword = 'remote123456';

    const { data: updateData, error: updateError } = await supabase.auth.admin.updateUserById(
      remoteUser.id,
      { password: newPassword }
    );

    if (updateError) {
      console.error('重置密码失败:', updateError);
      console.log('\n备选方案：手动在Supabase Dashboard重置密码');
      console.log('1. 访问 Authentication > Users');
      console.log('2. 找到 remote@123.com');
      console.log('3. 点击 "Reset Password"');
    } else {
      console.log('✓ 密码重置成功！');
      console.log(`  新密码: ${newPassword}`);
      console.log('  请使用此密码登录测试\n');
    }

    // 同时检查用户能否更新自己的team_id
    console.log('=== 检查用户更新权限 ===\n');

    // 尝试直接更新team_id（使用service role）
    const { data: teams } = await supabase.from('teams').select('*');

    if (teams && teams.length > 0) {
      const targetTeam = teams[0];
      console.log(`尝试将用户加入团队: ${targetTeam.name} (${targetTeam.id})\n`);

      const { data: updateResult, error: updateTeamError } = await supabase
        .from('users')
        .update({ team_id: targetTeam.id })
        .eq('id', remoteUser.id)
        .select();

      if (updateTeamError) {
        console.error('❌ 更新team_id失败:', updateTeamError);
        console.log('\n可能的原因:');
        console.log('1. RLS策略"Users can update own data"可能不允许更新team_id字段');
        console.log('2. 需要检查users表的UPDATE策略');
      } else {
        console.log('✓ 成功更新team_id!');
        console.log('更新后的用户信息:', updateResult);
      }
    }

  } catch (error) {
    console.error('操作失败:', error);
  }
}

resetRemotePassword().catch(console.error);
