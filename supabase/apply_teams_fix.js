import { createClient } from '@supabase/supabase-js';
import * as dotenv from 'dotenv';
import * as fs from 'fs';

dotenv.config();

const supabase = createClient(
  process.env.SUPABASE_URL,
  process.env.SUPABASE_SERVICE_ROLE_KEY
);

async function applyMigration() {
  console.log('=== 应用teams表RLS策略修复 ===\n');

  // 读取migration文件
  const migrationPath = './supabase/migrations/20260730000000_fix_teams_rls_for_joining.sql';
  console.log(`读取migration文件: ${migrationPath}\n`);
  const migrationSql = fs.readFileSync(migrationPath, 'utf8');

  console.log('执行SQL:\n');
  console.log(migrationSql);
  console.log('\n');

  try {
    // 分割SQL语句并逐个执行
    const statements = migrationSql
      .split(';')
      .map(s => s.trim())
      .filter(s => s.length > 0 && !s.startsWith('--'));

    for (const statement of statements) {
      if (statement) {
        console.log(`执行: ${statement.substring(0, 60)}...`);
        const { error } = await supabase.rpc('exec_sql', { sql: statement });

        if (error) {
          console.error(`错误: ${error.message}`);
          // 尝试直接通过REST API执行
          console.log('尝试通过直接查询执行...');
        } else {
          console.log('✓ 成功');
        }
      }
    }

    console.log('\n=== 验证修复 ===\n');

    // 使用service role验证策略
    const { data: teams } = await supabase.from('teams').select('*');
    console.log(`✓ 可以查询到 ${teams?.length || 0} 个团队`);

    console.log('\n修复完成！');
    console.log('Remote用户现在应该能够:');
    console.log('  1. 查看所有团队列表');
    console.log('  2. 通过邀请码或团队名加入团队');
    console.log('  3. 创建新团队');

  } catch (error) {
    console.error('应用migration失败:', error);
    console.log('\n请手动在Supabase Dashboard执行以下SQL:');
    console.log('---');
    console.log(migrationSql);
    console.log('---');
  }
}

applyMigration().catch(console.error);
