import { createClient } from '@supabase/supabase-js';
import * as dotenv from 'dotenv';

dotenv.config();

const supabase = createClient(
  process.env.SUPABASE_URL,
  process.env.SUPABASE_SERVICE_ROLE_KEY
);

async function listUsers() {
  console.log('正在查询用户列表...\n');

  // 查询 users 表
  const { data: users, error: usersError } = await supabase
    .from('users')
    .select('*')
    .order('created_at', { ascending: false });

  if (usersError) {
    console.error('查询 users 表失败:', usersError);
  } else {
    console.log('=== Users 表 ===');
    console.log(`共 ${users.length} 个用户\n`);

    users.forEach((user, index) => {
      console.log(`${index + 1}. 用户ID: ${user.id}`);
      console.log(`   邮箱: ${user.email}`);
      console.log(`   角色: ${user.role}`);
      console.log(`   团队ID: ${user.team_id || '(未分配)'}`);
      console.log(`   今日颜色: ${user.daily_color || '(未设置)'}`);
      console.log(`   颜色分配日期: ${user.color_assigned_date || '(未设置)'}`);
      console.log(`   创建时间: ${user.created_at}`);
      console.log('');
    });
  }

  // 查询 teams 表
  const { data: teams, error: teamsError } = await supabase
    .from('teams')
    .select('*')
    .order('created_at', { ascending: false });

  if (teamsError) {
    console.error('查询 teams 表失败:', teamsError);
  } else {
    console.log('=== Teams 表 ===');
    console.log(`共 ${teams.length} 个团队\n`);

    teams.forEach((team, index) => {
      console.log(`${index + 1}. 团队ID: ${team.id}`);
      console.log(`   名称: ${team.name}`);
      console.log(`   创建时间: ${team.created_at}`);
      console.log('');
    });
  }

  // 查询用户和团队的关联
  if (users && users.length > 0) {
    console.log('=== 用户-团队关系 ===');
    for (const user of users) {
      if (user.team_id) {
        const { data: team } = await supabase
          .from('teams')
          .select('name')
          .eq('id', user.team_id)
          .single();

        console.log(`${user.email} (${user.role}) -> ${team?.name || user.team_id}`);
      } else {
        console.log(`${user.email} (${user.role}) -> (无团队)`);
      }
    }
    console.log('');
  }

  // 测试用户密码提示
  console.log('=== 测试用户密码提示 ===');
  console.log('常用测试密码:');
  console.log('  - test123456');
  console.log('  - Test123456!');
  console.log('  - 123456');
  console.log('');
}

listUsers().catch(console.error);
