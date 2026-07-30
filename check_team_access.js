import { createClient } from '@supabase/supabase-js';
import * as dotenv from 'dotenv';

dotenv.config();

const supabase = createClient(
  process.env.SUPABASE_URL,
  process.env.SUPABASE_SERVICE_ROLE_KEY
);

async function checkTeamAccess() {
  console.log('=== 检查团队访问权限问题 ===\n');

  console.log('分析teams表的RLS策略...\n');

  // 2. 使用service role key查询所有teams
  const { data: allTeams, error: teamsError } = await supabase
    .from('teams')
    .select('*');

  console.log('\n=== 使用Service Role查询所有团队 ===');
  if (teamsError) {
    console.error('错误:', teamsError);
  } else {
    console.log(`找到 ${allTeams.length} 个团队:`);
    allTeams.forEach(team => {
      console.log(`  - ${team.name} (${team.id})`);
    });
  }

  // 3. 检查remote用户
  const { data: remoteUser } = await supabase
    .from('users')
    .select('*')
    .eq('email', 'remote@123.com')
    .single();

  if (remoteUser) {
    console.log('\n=== Remote用户信息 ===');
    console.log(`邮箱: ${remoteUser.email}`);
    console.log(`角色: ${remoteUser.role}`);
    console.log(`团队ID: ${remoteUser.team_id || '(未分配)'}`);
    console.log(`用户ID: ${remoteUser.id}`);

    if (!remoteUser.team_id) {
      console.log('\n问题诊断: Remote用户没有team_id!');
      console.log('根本原因: teams表的RLS策略只允许查看"自己已加入的团队"');
      console.log('  当前策略: id IN (SELECT team_id FROM users WHERE id = auth.uid())');
      console.log('  问题: 如果用户team_id为NULL，则无法查询任何团队');
      console.log('  解决方案: 需要添加策略允许所有认证用户查看所有团队（用于加入团队）');
    }
  }
}

checkTeamAccess().catch(console.error);
