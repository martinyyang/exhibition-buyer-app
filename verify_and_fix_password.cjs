const { createClient } = require('@supabase/supabase-js');
require('dotenv').config();

const supabase = createClient(
  process.env.SUPABASE_URL,
  process.env.SUPABASE_SERVICE_ROLE_KEY
);

async function verifyAndFixPassword() {
  console.log('=== 验证并修复 remote@123.com 密码 ===\n');

  try {
    // 1. 尝试多个可能的密码登录
    const testPasswords = [
      'remote123456',
      'test123456',
      'Test123456!',
      '123456',
      'remote@123.com',
      'remote',
    ];

    console.log('步骤1: 尝试所有可能的密码...\n');

    for (const password of testPasswords) {
      const supabaseAnon = createClient(
        process.env.SUPABASE_URL,
        process.env.SUPABASE_ANON_KEY
      );

      const { data, error } = await supabaseAnon.auth.signInWithPassword({
        email: 'remote@123.com',
        password: password,
      });

      if (!error) {
        console.log(`✓ 找到正确密码: ${password}`);
        await supabaseAnon.auth.signOut();
        return;
      } else {
        console.log(`✗ ${password} - ${error.message}`);
      }
    }

    console.log('\n所有密码都不正确，现在强制重置...\n');

    // 2. 获取用户ID
    const { data: user } = await supabase
      .from('users')
      .select('id')
      .eq('email', 'remote@123.com')
      .single();

    if (!user) {
      console.error('找不到用户 remote@123.com');
      return;
    }

    console.log(`用户ID: ${user.id}`);

    // 3. 尝试多种方式重置密码
    const newPassword = 'Remote123456!';

    console.log(`\n步骤2: 尝试重置密码为: ${newPassword}\n`);

    // 方式1: updateUserById
    const { data: updateData, error: updateError } = await supabase.auth.admin.updateUserById(
      user.id,
      {
        password: newPassword,
        email_confirm: true // 确保邮箱已验证
      }
    );

    if (updateError) {
      console.error('方式1失败:', updateError.message);

      // 方式2: 生成密码重置链接
      console.log('\n尝试方式2: 生成密码重置邮件...');
      const { data: resetData, error: resetError } = await supabase.auth.admin.generateLink({
        type: 'magiclink',
        email: 'remote@123.com',
      });

      if (resetError) {
        console.error('方式2失败:', resetError.message);
      } else {
        console.log('✓ 重置链接已生成');
        console.log('注意：由于这是测试环境，请使用Admin API或Dashboard重置');
      }
    } else {
      console.log('✓ 密码重置成功！');
      console.log('用户信息:', updateData.user);
    }

    // 4. 验证新密码
    console.log('\n步骤3: 验证新密码...\n');

    const supabaseAnon = createClient(
      process.env.SUPABASE_URL,
      process.env.SUPABASE_ANON_KEY
    );

    const { data: loginData, error: loginError } = await supabaseAnon.auth.signInWithPassword({
      email: 'remote@123.com',
      password: newPassword,
    });

    if (loginError) {
      console.error('❌ 新密码登录失败:', loginError.message);
      console.log('\n可能的原因:');
      console.log('1. 邮箱未验证');
      console.log('2. 密码策略限制');
      console.log('3. Auth配置问题');
      console.log('\n请手动在Supabase Dashboard重置:');
      console.log('1. 访问 Authentication > Users');
      console.log('2. 找到 remote@123.com');
      console.log('3. 点击 ... > Reset Password');
      console.log('4. 勾选 "Auto Confirm User"');
      console.log('5. 设置新密码并保存');
    } else {
      console.log('✓ 新密码登录成功！');
      console.log(`\n最终密码: ${newPassword}`);
      await supabaseAnon.auth.signOut();
    }

  } catch (error) {
    console.error('错误:', error);
  }
}

verifyAndFixPassword().catch(console.error);
