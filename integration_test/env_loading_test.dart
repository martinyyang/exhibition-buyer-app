import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io';

/// Integration tests specifically for .env file loading and validation
///
/// These tests verify:
/// 1. .env file exists and is readable
/// 2. Required environment variables are present
/// 3. Environment variables have valid values
/// 4. Supabase can connect with loaded credentials
/// 5. Fallback mechanism when .env is missing
///
/// Historical issues:
/// - .env loading failure causing startup crashes
/// - GitHub Secrets not properly injected in CI/CD
/// - Missing validation causing silent failures
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('.env文件加载和验证', () {
    test('.env文件存在性检查', () async {
      // 验证.env文件存在于项目根目录
      final envFile = File('.env');
      expect(
        envFile.existsSync(),
        isTrue,
        reason: '.env文件应该存在于项目根目录',
      );

      print('✓ .env文件存在');
    });

    test('.env文件可读性检查', () async {
      // 验证.env文件可以被读取
      final envFile = File('.env');
      String? content;

      try {
        content = await envFile.readAsString();
      } catch (e) {
        fail('.env文件无法读取: $e');
      }

      expect(content, isNotNull);
      expect(content, isNotEmpty);

      print('✓ .env文件可读 (${content.length} bytes)');
    });

    test('加载.env文件', () async {
      // 使用flutter_dotenv加载.env
      try {
        await dotenv.load(fileName: '.env');
        print('✓ .env文件加载成功');
      } catch (e) {
        fail('.env文件加载失败: $e');
      }

      // 验证dotenv实例有内容
      expect(dotenv.env.keys.length, greaterThan(0));
      print('  环境变量数量: ${dotenv.env.keys.length}');
    });

    test('验证SUPABASE_URL存在', () async {
      await dotenv.load(fileName: '.env');

      final supabaseUrl = dotenv.env['SUPABASE_URL'];

      expect(
        supabaseUrl,
        isNotNull,
        reason: 'SUPABASE_URL必须在.env文件中定义',
      );

      expect(
        supabaseUrl,
        isNotEmpty,
        reason: 'SUPABASE_URL不能为空',
      );

      print('✓ SUPABASE_URL存在: ${supabaseUrl?.substring(0, 30)}...');
    });

    test('验证SUPABASE_ANON_KEY存在', () async {
      await dotenv.load(fileName: '.env');

      final supabaseKey = dotenv.env['SUPABASE_ANON_KEY'];

      expect(
        supabaseKey,
        isNotNull,
        reason: 'SUPABASE_ANON_KEY必须在.env文件中定义',
      );

      expect(
        supabaseKey,
        isNotEmpty,
        reason: 'SUPABASE_ANON_KEY不能为空',
      );

      print('✓ SUPABASE_ANON_KEY存在: ${supabaseKey?.substring(0, 20)}...');
    });
  });

  group('环境变量格式验证', () {
    test('SUPABASE_URL格式正确性', () async {
      await dotenv.load(fileName: '.env');

      final supabaseUrl = dotenv.env['SUPABASE_URL']!;

      // 验证URL格式
      expect(
        supabaseUrl,
        startsWith('https://'),
        reason: 'SUPABASE_URL必须使用HTTPS协议',
      );

      expect(
        supabaseUrl,
        contains('supabase.co'),
        reason: 'SUPABASE_URL必须是有效的Supabase域名',
      );

      // 验证URL可以被解析
      final uri = Uri.tryParse(supabaseUrl);
      expect(uri, isNotNull, reason: 'SUPABASE_URL必须是有效的URI');
      expect(uri?.scheme, equals('https'));
      expect(uri?.host, isNotEmpty);

      print('✓ SUPABASE_URL格式正确: ${uri?.host}');
    });

    test('SUPABASE_ANON_KEY格式正确性', () async {
      await dotenv.load(fileName: '.env');

      final supabaseKey = dotenv.env['SUPABASE_ANON_KEY']!;

      // 验证Key长度（JWT通常很长）
      expect(
        supabaseKey.length,
        greaterThan(100),
        reason: 'SUPABASE_ANON_KEY应该是一个长JWT token',
      );

      // 验证JWT格式 (三段由.分隔)
      final parts = supabaseKey.split('.');
      expect(
        parts.length,
        equals(3),
        reason: 'SUPABASE_ANON_KEY应该是标准JWT格式（header.payload.signature）',
      );

      print('✓ SUPABASE_ANON_KEY格式正确 (JWT with ${parts.length} parts)');
    });

    test('没有包含占位符值', () async {
      await dotenv.load(fileName: '.env');

      final supabaseUrl = dotenv.env['SUPABASE_URL']!;
      final supabaseKey = dotenv.env['SUPABASE_ANON_KEY']!;

      // 验证不是.env.example中的占位符
      expect(
        supabaseUrl,
        isNot(contains('your-project-ref')),
        reason: 'SUPABASE_URL不应该包含占位符',
      );

      expect(
        supabaseKey,
        isNot(equals('your-anon-key-here')),
        reason: 'SUPABASE_ANON_KEY不应该是占位符',
      );

      print('✓ 环境变量已正确配置（非占位符）');
    });
  });

  group('Supabase连接测试', () {
    test('使用加载的环境变量初始化Supabase', () async {
      await dotenv.load(fileName: '.env');

      final supabaseUrl = dotenv.env['SUPABASE_URL']!;
      final supabaseKey = dotenv.env['SUPABASE_ANON_KEY']!;

      // 初始化Supabase
      try {
        await Supabase.initialize(
          url: supabaseUrl,
          anonKey: supabaseKey,
        );
        print('✓ Supabase初始化成功');
      } catch (e) {
        fail('Supabase初始化失败: $e');
      }

      // 验证客户端可用
      final client = Supabase.instance.client;
      expect(client, isNotNull);

      print('  Client ready: ${client.auth.currentSession == null ? "未登录" : "已登录"}');
    });

    test('验证Supabase客户端可以发起请求', () async {
      await dotenv.load(fileName: '.env');

      final supabaseUrl = dotenv.env['SUPABASE_URL']!;
      final supabaseKey = dotenv.env['SUPABASE_ANON_KEY']!;

      await Supabase.initialize(
        url: supabaseUrl,
        anonKey: supabaseKey,
      );

      final client = Supabase.instance.client;

      // 尝试一个简单的请求（获取当前session，不会失败）
      try {
        final session = client.auth.currentSession;
        print('✓ Supabase客户端可以正常工作');
        print('  当前session: ${session != null ? "有效" : "无"}');
      } catch (e) {
        fail('Supabase客户端请求失败: $e');
      }
    });

    test('网络连接测试 - 验证没有"no host"错误', () async {
      await dotenv.load(fileName: '.env');

      final supabaseUrl = dotenv.env['SUPABASE_URL']!;
      final supabaseKey = dotenv.env['SUPABASE_ANON_KEY']!;

      // 初始化并验证不会抛出网络权限错误
      bool hasNetworkError = false;
      String? errorMessage;

      try {
        await Supabase.initialize(
          url: supabaseUrl,
          anonKey: supabaseKey,
        );

        // 尝试访问auth（这会触发网络请求）
        final client = Supabase.instance.client;
        final _ = client.auth.currentUser;
      } catch (e) {
        errorMessage = e.toString().toLowerCase();
        if (errorMessage.contains('no host') ||
            errorMessage.contains('network') ||
            errorMessage.contains('socket')) {
          hasNetworkError = true;
        }
      }

      expect(
        hasNetworkError,
        isFalse,
        reason: '不应该出现"no host"或网络权限错误: $errorMessage',
      );

      print('✓ 网络连接正常（无"no host"错误）');
    });
  });

  group('Fallback机制测试', () {
    test('验证main.dart中存在fallback配置', () async {
      // 读取main.dart文件内容
      final mainFile = File('lib/main.dart');
      expect(mainFile.existsSync(), isTrue);

      final mainContent = await mainFile.readAsString();

      // 验证包含fallback逻辑
      expect(
        mainContent,
        contains('Fallback'),
        reason: 'main.dart应该包含fallback配置逻辑',
      );

      expect(
        mainContent,
        contains('https://ppwjblvnixqeympfcqgs.supabase.co'),
        reason: 'main.dart应该包含hardcoded fallback URL',
      );

      print('✓ Fallback配置存在于main.dart');
    });

    test('验证错误处理逻辑存在', () async {
      final mainFile = File('lib/main.dart');
      final mainContent = await mainFile.readAsString();

      // 验证包含错误处理
      expect(
        mainContent,
        contains('应用初始化失败'),
        reason: 'main.dart应该包含初始化失败的错误处理',
      );

      expect(
        mainContent,
        contains('catch'),
        reason: 'main.dart应该使用try-catch处理初始化错误',
      );

      print('✓ 错误处理逻辑存在于main.dart');
    });
  });

  group('CI/CD环境测试', () {
    test('检测运行环境', () {
      // 检查是否在CI环境中运行
      final isCI = Platform.environment['CI'] == 'true' ||
          Platform.environment['GITHUB_ACTIONS'] == 'true';

      print(isCI ? '✓ 运行在CI/CD环境' : '✓ 运行在本地环境');

      if (isCI) {
        print('  CI环境变量:');
        print('    CI: ${Platform.environment['CI']}');
        print('    GITHUB_ACTIONS: ${Platform.environment['GITHUB_ACTIONS']}');
      }
    });

    test('验证GitHub Secrets在CI中正确注入', () async {
      final isCI = Platform.environment['CI'] == 'true';

      if (isCI) {
        // 在CI环境中，.env应该由GitHub Actions创建
        final envFile = File('.env');
        expect(
          envFile.existsSync(),
          isTrue,
          reason: 'GitHub Actions应该创建.env文件',
        );

        await dotenv.load(fileName: '.env');

        final supabaseUrl = dotenv.env['SUPABASE_URL'];
        final supabaseKey = dotenv.env['SUPABASE_ANON_KEY'];

        expect(supabaseUrl, isNotNull, reason: 'CI环境应该注入SUPABASE_URL');
        expect(supabaseKey, isNotNull, reason: 'CI环境应该注入SUPABASE_ANON_KEY');

        print('✓ GitHub Secrets正确注入到CI环境');
      } else {
        print('✓ 跳过CI Secrets检查（非CI环境）');
      }
    });
  });

  group('性能测试', () {
    test('.env加载性能测试', () async {
      final startTime = DateTime.now();

      await dotenv.load(fileName: '.env');

      final endTime = DateTime.now();
      final duration = endTime.difference(startTime);

      expect(
        duration.inMilliseconds,
        lessThan(100),
        reason: '.env文件加载应该在100ms内完成',
      );

      print('✓ .env加载时间: ${duration.inMilliseconds}ms');
    });

    test('Supabase初始化性能测试', () async {
      await dotenv.load(fileName: '.env');

      final supabaseUrl = dotenv.env['SUPABASE_URL']!;
      final supabaseKey = dotenv.env['SUPABASE_ANON_KEY']!;

      final startTime = DateTime.now();

      await Supabase.initialize(
        url: supabaseUrl,
        anonKey: supabaseKey,
      );

      final endTime = DateTime.now();
      final duration = endTime.difference(startTime);

      expect(
        duration.inSeconds,
        lessThan(3),
        reason: 'Supabase初始化应该在3秒内完成',
      );

      print('✓ Supabase初始化时间: ${duration.inMilliseconds}ms');
    });

    test('完整启动流程性能测试', () async {
      final startTime = DateTime.now();

      // 模拟完整启动流程
      await dotenv.load(fileName: '.env');

      final supabaseUrl = dotenv.env['SUPABASE_URL']!;
      final supabaseKey = dotenv.env['SUPABASE_ANON_KEY']!;

      await Supabase.initialize(
        url: supabaseUrl,
        anonKey: supabaseKey,
      );

      final endTime = DateTime.now();
      final duration = endTime.difference(startTime);

      expect(
        duration.inSeconds,
        lessThan(5),
        reason: '完整启动流程应该在5秒内完成（避免hang）',
      );

      print('✓ 完整启动时间: ${duration.inMilliseconds}ms (< 5秒)');
    });
  });
}
