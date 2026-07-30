const { createClient } = require('@supabase/supabase-js');
require('dotenv').config();
const fs = require('fs');

const supabase = createClient(
  process.env.SUPABASE_URL,
  process.env.SUPABASE_SERVICE_ROLE_KEY
);

async function applyMigration() {
  console.log('=== 应用teams表RLS策略修复 ===\n');
  console.log(`Supabase URL: ${process.env.SUPABASE_URL}\n`);

  // 读取migration文件
  const migrationSql = fs.readFileSync(
    './supabase/migrations/20260730000000_fix_teams_rls_for_joining.sql',
    'utf8'
  );

  console.log('需要执行的SQL:\n');
  console.log('---');
  console.log(migrationSql);
  console.log('---\n');

  console.log('由于Supabase客户端限制，请手动执行以下步骤:\n');
  console.log('1. 访问 Supabase Dashboard: https://app.supabase.com/');
  console.log('2. 选择你的项目: exhibition-buyer-app');
  console.log('3. 进入 SQL Editor');
  console.log('4. 复制上面的SQL语句并执行');
  console.log('\n或者使用以下命令（如果安装了psql）:');
  console.log(`psql "${process.env.SUPABASE_URL}" -c "$(cat ./supabase/migrations/20260730000000_fix_teams_rls_for_joining.sql)"`);

  // 验证当前状态
  console.log('\n=== 当前状态检查 ===\n');

  const { data: teams, error } = await supabase.from('teams').select('*');
  if (error) {
    console.error('查询teams表错误:', error.message);
  } else {
    console.log(`✓ 使用Service Role可以查询到 ${teams.length} 个团队`);
  }

  const { data: remoteUser } = await supabase
    .from('users')
    .select('*')
    .eq('email', 'remote@123.com')
    .single();

  if (remoteUser) {
    console.log(`✓ Remote用户: ${remoteUser.email}`);
    console.log(`  团队ID: ${remoteUser.team_id || '(未分配)'}`);
    console.log(`  问题: ${remoteUser.team_id ? '已修复' : '需要应用上述SQL修复'}`);
  }
}

applyMigration().catch(console.error);
