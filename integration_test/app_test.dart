import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:integration_test/integration_test.dart';
import 'package:exhibition_buyer_app/main.dart';
import 'package:exhibition_buyer_app/features/auth/screens/login_screen.dart';
import 'package:exhibition_buyer_app/features/event/screens/event_selection_screen.dart';
import 'package:exhibition_buyer_app/features/booth/screens/booth_list_screen.dart';
import 'package:exhibition_buyer_app/features/photo/screens/photo_grid_screen.dart';
import 'package:exhibition_buyer_app/features/photo/screens/photo_detail_screen.dart';
import 'package:exhibition_buyer_app/features/flag/widgets/flag_table.dart';
import 'package:exhibition_buyer_app/shared/widgets/color_badge.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('完整采购工作流E2E测试', () {
    testWidgets('买手登录-创建场次-创建摊位-拍照-远程标注-报价-谈判流程', (tester) async {
      // 启动应用
      await tester.pumpWidget(
        const ProviderScope(
          child: MyApp(),
        ),
      );
      await tester.pumpAndSettle();

      // 步骤1 - 买手登录
      // 预期：成功登录并分配每日颜色标识
      expect(find.byType(LoginScreen), findsOneWidget);

      // 输入测试账号
      await tester.enterText(
        find.byKey(const Key('email_field')),
        'buyer@test.com',
      );
      await tester.enterText(
        find.byKey(const Key('password_field')),
        'test123456',
      );

      // 点击登录按钮
      await tester.tap(find.byKey(const Key('login_button')));
      await tester.pumpAndSettle();

      // 验证登录成功并显示颜色标识
      expect(find.byType(ColorBadge), findsWidgets);
      expect(find.byType(EventSelectionScreen), findsOneWidget);

      // 步骤2 - 创建新场次
      // 预期：场次创建成功并设为活跃状态
      await tester.tap(find.byKey(const Key('create_event_button')));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('event_name_field')),
        '2026春季广交会',
      );

      // 选择开始日期
      await tester.tap(find.byKey(const Key('start_date_picker')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('save_event_button')));
      await tester.pumpAndSettle();

      // 验证场次创建成功
      expect(find.text('2026春季广交会'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle), findsOneWidget); // 活跃标记

      // 步骤3 - 创建摊位
      // 预期：摊位创建成功并显示在列表中
      await tester.tap(find.text('2026春季广交会'));
      await tester.pumpAndSettle();

      expect(find.byType(BoothListScreen), findsOneWidget);

      await tester.tap(find.byKey(const Key('create_booth_button')));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('booth_number_field')),
        'B01',
      );

      await tester.tap(find.byKey(const Key('save_booth_button')));
      await tester.pumpAndSettle();

      // 验证摊位创建成功
      expect(find.text('B01'), findsOneWidget);

      // 步骤4 - 买手拍照上传
      // 预期：照片上传成功并显示缩略图
      await tester.tap(find.text('B01'));
      await tester.pumpAndSettle();

      expect(find.byType(PhotoGridScreen), findsOneWidget);

      // 模拟拍照（实际集成测试中需要mock image_picker）
      await tester.tap(find.byKey(const Key('camera_fab')));
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // 验证照片显示
      expect(find.byType(Image), findsWidgets);

      // 步骤5 - 远程端在照片上插旗标注
      // 预期：旗子显示在照片上，编号自动递增
      // 切换到远程端视图（通过角色切换或另一个用户登录）
      // 点击照片进入详情页
      await tester.tap(find.byType(Image).first);
      await tester.pumpAndSettle();

      expect(find.byType(PhotoDetailScreen), findsOneWidget);

      // 在照片上点击3个位置插旗
      final photoCenter = tester.getCenter(find.byKey(const Key('photo_canvas')));
      await tester.tapAt(photoCenter + const Offset(-100, -50)); // 旗子#1
      await tester.pumpAndSettle();

      await tester.tapAt(photoCenter + const Offset(50, 30)); // 旗子#2
      await tester.pumpAndSettle();

      await tester.tapAt(photoCenter + const Offset(0, -80)); // 旗子#3
      await tester.pumpAndSettle();

      // 验证旗子显示
      expect(find.text('1'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);
      expect(find.text('3'), findsOneWidget);
      expect(find.byType(FlagTable), findsOneWidget);

      // 步骤6 - 买手填写报价
      // 预期：报价保存成功，换算价格自动计算
      // 切换回买手视图
      await tester.enterText(
        find.byKey(const Key('price_rmb_field_1')),
        '1000',
      );
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      // 验证换算价格显示（假设公式为 RMB * 0.14）
      expect(find.text('140.00'), findsOneWidget);

      // 步骤7 - 远程端设置目标价
      // 预期：目标价保存成功，红色警告标记显示
      // 远程端输入目标价
      await tester.enterText(
        find.byKey(const Key('target_price_field_1')),
        '120',
      );
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      // 验证警告标记显示
      expect(find.byIcon(Icons.warning), findsOneWidget);
      expect(find.text('🚨'), findsOneWidget);

      // 步骤8 - 买手更新报价
      // 预期：报价更新成功，警告标记消失
      await tester.enterText(
        find.byKey(const Key('price_rmb_field_1')),
        '850',
      );
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle(const Duration(milliseconds: 500));

      // 验证警告标记消失
      expect(find.byIcon(Icons.warning), findsNothing);

      // 步骤9 - 验证实时同步
      // 预期：双端数据延迟 < 1秒
      final startTime = DateTime.now();

      // 远程端修改目标价
      await tester.enterText(
        find.byKey(const Key('target_price_field_2')),
        '200',
      );
      await tester.testTextInput.receiveAction(TextInputAction.done);

      // 等待实时同步
      await tester.pumpAndSettle();

      final endTime = DateTime.now();
      final syncDelay = endTime.difference(startTime).inMilliseconds;

      // 验证同步延迟 < 1秒
      expect(syncDelay, lessThan(1000));
      expect(find.text('200'), findsOneWidget);
    });

    testWidgets('场次切换和数据隔离测试', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MyApp(),
        ),
      );
      await tester.pumpAndSettle();

      // 登录
      await tester.enterText(find.byKey(const Key('email_field')), 'buyer@test.com');
      await tester.enterText(find.byKey(const Key('password_field')), 'test123456');
      await tester.tap(find.byKey(const Key('login_button')));
      await tester.pumpAndSettle();

      // 步骤1 - 创建第一个场次并添加摊位
      // 预期：场次和摊位创建成功
      await tester.tap(find.byKey(const Key('create_event_button')));
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('event_name_field')), '2026春季展');
      await tester.tap(find.byKey(const Key('start_date_picker')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('save_event_button')));
      await tester.pumpAndSettle();

      expect(find.text('2026春季展'), findsOneWidget);

      // 进入场次并创建摊位B01
      await tester.tap(find.text('2026春季展'));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('create_booth_button')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('booth_number_field')), 'B01');
      await tester.tap(find.byKey(const Key('save_booth_button')));
      await tester.pumpAndSettle();

      expect(find.text('B01'), findsOneWidget);

      // 返回场次列表
      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();

      // 步骤2 - 创建第二个场次并切换
      // 预期：只显示当前场次的摊位
      await tester.tap(find.byKey(const Key('create_event_button')));
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('event_name_field')), '2026秋季展');
      await tester.tap(find.byKey(const Key('start_date_picker')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('save_event_button')));
      await tester.pumpAndSettle();

      expect(find.text('2026秋季展'), findsOneWidget);

      // 进入第二个场次
      await tester.tap(find.text('2026秋季展'));
      await tester.pumpAndSettle();

      // 验证第二个场次的摊位列表为空
      expect(find.text('B01'), findsNothing);
      expect(find.text('暂无摊位'), findsOneWidget);

      // 步骤3 - 在两个场次中创建相同摊位号
      // 预期：允许创建，数据隔离正确
      await tester.tap(find.byKey(const Key('create_booth_button')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('booth_number_field')), 'B01');
      await tester.tap(find.byKey(const Key('save_booth_button')));
      await tester.pumpAndSettle();

      // 验证第二个场次也有B01（跨场次允许重复）
      expect(find.text('B01'), findsOneWidget);

      // 再创建一个B02
      await tester.tap(find.byKey(const Key('create_booth_button')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('booth_number_field')), 'B02');
      await tester.tap(find.byKey(const Key('save_booth_button')));
      await tester.pumpAndSettle();

      expect(find.text('B02'), findsOneWidget);

      // 步骤4 - 切换回第一个场次
      // 预期：显示第一个场次的数据，不显示第二个场次的数据
      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();

      // 切换到第一个场次
      await tester.tap(find.text('2026春季展'));
      await tester.pumpAndSettle();

      // 验证只显示第一个场次的摊位（B01），不显示B02
      expect(find.text('B01'), findsOneWidget);
      expect(find.text('B02'), findsNothing);
    });

    testWidgets('公式换算和历史记录测试', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MyApp(),
        ),
      );
      await tester.pumpAndSettle();

      // 登录并准备测试数据
      await tester.enterText(find.byKey(const Key('email_field')), 'remote@test.com');
      await tester.enterText(find.byKey(const Key('password_field')), 'test123456');
      await tester.tap(find.byKey(const Key('login_button')));
      await tester.pumpAndSettle();

      // 进入设置或公式配置页面
      await tester.tap(find.byIcon(Icons.settings));
      await tester.pumpAndSettle();

      // 步骤1 - 设置简单公式 (RMB * 0.14)
      // 预期：公式保存成功
      await tester.tap(find.byKey(const Key('formula_settings_button')));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('formula_input_field')),
        'RMB * 0.14',
      );

      // 验证公式预览
      expect(find.text('示例：1000元 → 140.00'), findsOneWidget);

      await tester.tap(find.byKey(const Key('save_formula_button')));
      await tester.pumpAndSettle();

      expect(find.text('公式保存成功'), findsOneWidget);

      // 步骤2 - 填写报价并验证换算结果
      // 预期：换算价格计算正确
      // 返回并进入旗子详情
      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();

      // 填写报价
      await tester.enterText(
        find.byKey(const Key('price_rmb_field_1')),
        '2000',
      );
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      // 验证换算结果：2000 * 0.14 = 280
      expect(find.text('280.00'), findsOneWidget);

      // 步骤3 - 设置复杂公式 ((RMB - 50) * 0.14 + 10)
      // 预期：公式保存成功，历史记录增加
      await tester.tap(find.byIcon(Icons.settings));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('formula_settings_button')));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('formula_input_field')),
        '(RMB - 50) * 0.14 + 10',
      );

      // 验证复杂公式预览
      expect(find.text('示例：1000元 → 143.00'), findsOneWidget);

      await tester.tap(find.byKey(const Key('save_formula_button')));
      await tester.pumpAndSettle();

      // 验证历史记录显示
      expect(find.byKey(const Key('formula_history_list')), findsOneWidget);
      expect(find.text('RMB * 0.14'), findsOneWidget);
      expect(find.text('(RMB - 50) * 0.14 + 10'), findsOneWidget);

      // 步骤4 - 从历史记录快速选择公式
      // 预期：公式应用成功，使用次数增加
      await tester.tap(find.text('RMB * 0.14'));
      await tester.pumpAndSettle();

      expect(find.text('公式已应用'), findsOneWidget);

      // 验证使用次数增加
      expect(find.text('使用 2 次'), findsOneWidget);

      // 步骤5 - 批量重新计算换算价格
      // 预期：所有旗子的换算价格更新
      await tester.tap(find.byKey(const Key('recalculate_all_button')));
      await tester.pumpAndSettle();

      // 验证所有旗子的换算价格已更新（2000 * 0.14 = 280）
      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();

      expect(find.text('280.00'), findsOneWidget);
    });

    testWidgets('买手小组协作测试', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MyApp(),
        ),
      );
      await tester.pumpAndSettle();

      // 步骤1 - 买手A登录并获得颜色标识
      // 预期：分配颜色（如绿色🟢）
      await tester.enterText(find.byKey(const Key('email_field')), 'buyerA@test.com');
      await tester.enterText(find.byKey(const Key('password_field')), 'test123456');
      await tester.tap(find.byKey(const Key('login_button')));
      await tester.pumpAndSettle();

      // 验证颜色标识分配
      final colorBadgeA = find.byType(ColorBadge);
      expect(colorBadgeA, findsOneWidget);

      // 获取买手A的颜色（应该是绿色🟢、蓝色🔵等之一）
      final colorWidgetA = tester.widget<ColorBadge>(colorBadgeA);
      expect(
        ['green', 'blue', 'yellow', 'red', 'purple', 'orange'],
        contains(colorWidgetA.colorName),
      );
      final buyerAColor = colorWidgetA.colorName;

      // 步骤2 - 买手A创建摊位并拍照
      // 预期：照片带有买手A的颜色标识
      // 创建场次和摊位
      await tester.tap(find.byKey(const Key('create_event_button')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('event_name_field')), '测试场次');
      await tester.tap(find.byKey(const Key('start_date_picker')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('OK'));
      await tester.tap(find.byKey(const Key('save_event_button')));
      await tester.pumpAndSettle();

      await tester.tap(find.text('测试场次'));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('create_booth_button')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('booth_number_field')), 'A01');
      await tester.tap(find.byKey(const Key('save_booth_button')));
      await tester.pumpAndSettle();

      // 进入摊位拍照
      await tester.tap(find.text('A01'));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('camera_fab')));
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // 验证照片显示买手A的颜色标识
      expect(find.byType(ColorBadge), findsWidgets);

      // 登出买手A
      await tester.tap(find.byIcon(Icons.logout));
      await tester.pumpAndSettle();

      // 步骤3 - 买手B登录并获得不同颜色
      // 预期：分配不同颜色（如蓝色🔵）
      await tester.enterText(find.byKey(const Key('email_field')), 'buyerB@test.com');
      await tester.enterText(find.byKey(const Key('password_field')), 'test123456');
      await tester.tap(find.byKey(const Key('login_button')));
      await tester.pumpAndSettle();

      // 验证买手B获得不同颜色
      final colorBadgeB = find.byType(ColorBadge);
      expect(colorBadgeB, findsOneWidget);

      final colorWidgetB = tester.widget<ColorBadge>(colorBadgeB);
      final buyerBColor = colorWidgetB.colorName;
      expect(buyerBColor, isNot(buyerAColor)); // 不同买手应该有不同颜色

      // 步骤4 - 买手B查看买手A的照片
      // 预期：能够看到同组买手的照片
      await tester.tap(find.text('测试场次'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('A01'));
      await tester.pumpAndSettle();

      // 买手B应该能看到买手A拍的照片（同组共享）
      expect(find.byType(Image), findsWidgets);

      // 步骤5 - 验证颜色标识显示正确
      // 预期：远程端能区分不同买手的照片
      // 切换到远程视图（或登录远程账号）
      await tester.tap(find.byIcon(Icons.logout));
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('email_field')), 'remote@test.com');
      await tester.enterText(find.byKey(const Key('password_field')), 'test123456');
      await tester.tap(find.byKey(const Key('login_button')));
      await tester.pumpAndSettle();

      // 进入买手列表，验证颜色标识
      await tester.tap(find.byKey(const Key('buyer_list_button')));
      await tester.pumpAndSettle();

      // 应该显示两个买手，分别带有不同的颜色标识
      expect(find.byType(ColorBadge), findsNWidgets(2));
      expect(find.text('buyerA'), findsOneWidget);
      expect(find.text('buyerB'), findsOneWidget);
    });

    testWidgets('红色警告标记逻辑测试', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MyApp(),
        ),
      );
      await tester.pumpAndSettle();

      // 准备测试环境：登录、创建场次、摊位、照片、旗子
      await tester.enterText(find.byKey(const Key('email_field')), 'buyer@test.com');
      await tester.enterText(find.byKey(const Key('password_field')), 'test123456');
      await tester.tap(find.byKey(const Key('login_button')));
      await tester.pumpAndSettle();

      // 创建测试数据...（简化）
      // 假设已经有照片和旗子

      // 步骤1 - 创建旗子并填写初始报价
      // 预期：旗子创建成功，无警告标记
      await tester.enterText(
        find.byKey(const Key('price_rmb_field_1')),
        '1000',
      );
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      // 验证无警告标记
      expect(find.byIcon(Icons.warning), findsNothing);
      expect(find.text('🚨'), findsNothing);

      // 步骤2 - 远程端设置目标价
      // 预期：警告标记显示（🚨）
      // 切换到远程视图
      await tester.tap(find.byKey(const Key('switch_to_remote_button')));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('target_price_field_1')),
        '120',
      );
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle(const Duration(milliseconds: 500));

      // 验证警告标记显示
      expect(find.byIcon(Icons.warning), findsOneWidget);

      // 步骤3 - 买手查看旗子列表
      // 预期：看到红色警告标记
      await tester.tap(find.byKey(const Key('switch_to_buyer_button')));
      await tester.pumpAndSettle();

      // 买手端也应该看到警告
      expect(find.byIcon(Icons.warning), findsOneWidget);

      // 步骤4 - 买手更新报价
      // 预期：警告标记立即消失
      await tester.enterText(
        find.byKey(const Key('price_rmb_field_1')),
        '850',
      );
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle(const Duration(milliseconds: 500));

      // 验证警告标记消失
      expect(find.byIcon(Icons.warning), findsNothing);

      // 步骤5 - 验证双端同步
      // 预期：远程端也看到警告消失
      await tester.tap(find.byKey(const Key('switch_to_remote_button')));
      await tester.pumpAndSettle();

      // 远程端警告也应该消失
      expect(find.byIcon(Icons.warning), findsNothing);
      expect(find.text('850'), findsOneWidget);
    });

    testWidgets('响应式布局测试：移动端-平板-桌面端切换', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MyApp(),
        ),
      );
      await tester.pumpAndSettle();

      // 登录并准备测试数据
      await tester.enterText(find.byKey(const Key('email_field')), 'remote@test.com');
      await tester.enterText(find.byKey(const Key('password_field')), 'test123456');
      await tester.tap(find.byKey(const Key('login_button')));
      await tester.pumpAndSettle();

      // 进入照片网格页面
      // 假设已有测试数据

      // 1. 移动端 (400x800)
      await tester.binding.setSurfaceSize(const Size(400, 800));
      await tester.pumpAndSettle();

      // 验证单列布局，网格显示2列
      expect(find.byKey(const Key('photo_grid')), findsOneWidget);
      // 验证响应式网格列数为2
      final mobileGrid = tester.widget<GridView>(find.byKey(const Key('photo_grid')));
      final mobileDelegate = mobileGrid.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount;
      expect(mobileDelegate.crossAxisCount, 2);

      // 验证侧边栏隐藏
      expect(find.byKey(const Key('sidebar')), findsNothing);

      // 2. 平板 (900x1200)
      await tester.binding.setSurfaceSize(const Size(900, 1200));
      await tester.pumpAndSettle();

      // 验证网格显示3列
      final tabletGrid = tester.widget<GridView>(find.byKey(const Key('photo_grid')));
      final tabletDelegate = tabletGrid.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount;
      expect(tabletDelegate.crossAxisCount, 3);

      // 3. 桌面端 (1600x1200)
      await tester.binding.setSurfaceSize(const Size(1600, 1200));
      await tester.pumpAndSettle();

      // 验证网格显示4列
      final desktopGrid = tester.widget<GridView>(find.byKey(const Key('photo_grid')));
      final desktopDelegate = desktopGrid.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount;
      expect(desktopDelegate.crossAxisCount, 4);

      // 验证Web端三栏布局显示
      expect(find.byKey(const Key('buyer_sidebar')), findsOneWidget); // 左侧买手列表
      expect(find.byKey(const Key('photo_canvas')), findsOneWidget); // 中间照片
      expect(find.byKey(const Key('flag_sidebar')), findsOneWidget); // 右侧Flag表格

      // 验证侧边栏宽度
      final buyerSidebar = tester.widget<Container>(find.byKey(const Key('buyer_sidebar')));
      expect(buyerSidebar.constraints?.maxWidth, 280);

      final flagSidebar = tester.widget<Container>(find.byKey(const Key('flag_sidebar')));
      expect(flagSidebar.constraints?.maxWidth, 400);

      // 重置屏幕尺寸
      await tester.binding.setSurfaceSize(null);
    });

    testWidgets('供应商信息测试：添加供应商名称和Logo', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MyApp(),
        ),
      );
      await tester.pumpAndSettle();

      // 登录并准备照片
      await tester.enterText(find.byKey(const Key('email_field')), 'buyer@test.com');
      await tester.enterText(find.byKey(const Key('password_field')), 'test123456');
      await tester.tap(find.byKey(const Key('login_button')));
      await tester.pumpAndSettle();

      // 进入照片网格
      // 假设已有照片

      // 步骤1 - 长按照片打开菜单
      // 预期：显示操作菜单
      await tester.longPress(find.byType(Image).first);
      await tester.pumpAndSettle();

      // 验证菜单显示
      expect(find.text('添加供应商信息'), findsOneWidget);
      expect(find.text('删除照片'), findsOneWidget);

      // 步骤2 - 点击"添加供应商信息"
      // 预期：打开供应商信息对话框
      await tester.tap(find.text('添加供应商信息'));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('supplier_dialog')), findsOneWidget);
      expect(find.text('供应商信息'), findsOneWidget);

      // 步骤3 - 输入供应商名称
      // 预期：名称保存成功
      await tester.enterText(
        find.byKey(const Key('supplier_name_field')),
        'LV专柜',
      );

      // 可选：上传Logo（模拟）
      await tester.tap(find.byKey(const Key('upload_logo_button')));
      await tester.pumpAndSettle(const Duration(seconds: 1));

      // 保存
      await tester.tap(find.byKey(const Key('save_supplier_button')));
      await tester.pumpAndSettle();

      // 步骤4 - 验证供应商名称显示在照片卡片上
      // 预期：照片缩略图显示供应商名称
      expect(find.text('LV专柜'), findsOneWidget);

      // 验证Logo显示（如果上传了）
      expect(find.byKey(const Key('supplier_logo')), findsWidgets);
    });

    testWidgets('旗子编号顺序测试：远程插旗顺序=买手看到的顺序', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MyApp(),
        ),
      );
      await tester.pumpAndSettle();

      // 远程端登录
      await tester.enterText(find.byKey(const Key('email_field')), 'remote@test.com');
      await tester.enterText(find.byKey(const Key('password_field')), 'test123456');
      await tester.tap(find.byKey(const Key('login_button')));
      await tester.pumpAndSettle();

      // 进入照片详情页
      // 假设已有照片

      // 步骤1 - 远程在照片上依次点击3个位置
      // 预期：生成旗子#1, #2, #3
      final photoCenter = tester.getCenter(find.byKey(const Key('photo_canvas')));

      // 第一个位置（左上）
      await tester.tapAt(photoCenter + const Offset(-150, -100));
      await tester.pumpAndSettle();
      expect(find.text('1'), findsOneWidget);

      // 第二个位置（右下）
      await tester.tapAt(photoCenter + const Offset(100, 50));
      await tester.pumpAndSettle();
      expect(find.text('2'), findsOneWidget);

      // 第三个位置（中上）
      await tester.tapAt(photoCenter + const Offset(0, -120));
      await tester.pumpAndSettle();
      expect(find.text('3'), findsOneWidget);

      // 步骤2 - 验证Flag表格中编号顺序
      // 预期：编号按插旗顺序递增
      expect(find.byType(FlagTable), findsOneWidget);

      // 获取表格中的行
      final flagRows = find.byKey(const Key('flag_row'));
      expect(flagRows, findsNWidgets(3));

      // 验证第一行是旗子#1，第二行是旗子#2，第三行是旗子#3
      final firstRow = tester.widget<DataRow>(flagRows.at(0));
      expect(firstRow.cells[0].child, isA<Text>().having((t) => t.data, 'text', '1'));

      final secondRow = tester.widget<DataRow>(flagRows.at(1));
      expect(secondRow.cells[0].child, isA<Text>().having((t) => t.data, 'text', '2'));

      final thirdRow = tester.widget<DataRow>(flagRows.at(2));
      expect(thirdRow.cells[0].child, isA<Text>().having((t) => t.data, 'text', '3'));

      // 步骤3 - 买手端验证顺序一致
      // 预期：买手看到的编号顺序与远程插旗顺序相同
      await tester.tap(find.byIcon(Icons.logout));
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('email_field')), 'buyer@test.com');
      await tester.enterText(find.byKey(const Key('password_field')), 'test123456');
      await tester.tap(find.byKey(const Key('login_button')));
      await tester.pumpAndSettle();

      // 进入同一照片详情页
      // 验证旗子编号顺序一致
      expect(find.text('1'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);
      expect(find.text('3'), findsOneWidget);

      // 验证Flag表格顺序
      expect(find.byType(FlagTable), findsOneWidget);
      final buyerFlagRows = find.byKey(const Key('flag_row'));
      expect(buyerFlagRows, findsNWidgets(3));

      // 买手看到的顺序应该与远程插旗顺序完全一致
    });
  });
}
