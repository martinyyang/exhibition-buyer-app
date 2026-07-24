import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async {
  // 加载环境变量
  await dotenv.load(fileName: '.env');

  // 初始化 Supabase
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL'] ?? '',
    anonKey: dotenv.env['SUPABASE_ANON_KEY'] ?? '',
  );

  final supabase = Supabase.instance.client;

  print('正在修复 RLS 策略...\n');

  try {
    // 执行修复 SQL
    final sql = '''
      -- 允许任何认证用户创建团队（注册时需要）
      CREATE POLICY "Authenticated users can create teams"
        ON teams FOR INSERT
        TO authenticated
        WITH CHECK (true);

      -- 允许新注册用户插入自己的用户记录
      CREATE POLICY "Users can insert own data"
        ON users FOR INSERT
        TO authenticated
        WITH CHECK (auth.uid() = id);

      -- 允许团队成员查看同团队的其他成员信息（设置界面需要显示团队名称）
      CREATE POLICY "Team members can view team members"
        ON users FOR SELECT
        USING (
          team_id IN (
            SELECT team_id FROM users WHERE id = auth.uid()
          )
        );
    ''';

    // 注意：Supabase 客户端库不支持直接执行 DDL 语句
    // 需要使用 Supabase 管理 API 或在控制台手动执行
    print('错误：Supabase 客户端不支持执行 DDL 语句');
    print('请在 Supabase 控制台的 SQL Editor 中手动执行以下 SQL：\n');
    print(sql);
  } catch (e) {
    print('执行失败: $e');
  }
}
