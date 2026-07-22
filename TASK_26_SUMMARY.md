# 任务#26完成总结：公式历史存档和自动换算

## 创建/修改的文件

### 新增服务层文件
1. **lib/features/formula/services/exchange_settings_service.dart** - 汇率设置服务
   - `getCurrentFormula()`: 获取当前活跃的汇率公式
   - `setDailyFormula()`: 设置当天的汇率公式（自动保存到历史）
   - `calculateWithCurrentFormula()`: 使用当前公式计算价格

2. **lib/features/formula/providers/formula_provider.dart** - Riverpod状态管理
   - `formulaHistoryProvider`: 提供最近使用的公式列表（支持Realtime）
   - `currentFormulaProvider`: 提供当前活跃的公式（支持Realtime）
   - `FormulaHistoryNotifier`: 公式历史状态管理器
   - `CurrentFormulaNotifier`: 当前公式状态管理器

### 完善现有文件
3. **lib/features/formula/services/formula_history_service.dart** - 添加查询方法
   - 新增 `getFormulaByText()`: 根据公式文本查询是否已存在

4. **lib/core/services/realtime_service.dart** - 扩展Realtime支持
   - 新增 `subscribeToFormulaHistory()`: 监听公式历史变化
   - 新增 `subscribeToExchangeSettings()`: 监听汇率设置变化

5. **lib/features/flag/services/flag_service.dart** - 优化报价更新
   - 修改 `updateBuyerPrice()`: 添加teamId参数支持
   - 重命名 `updateTargetPrice()` -> `setTargetPrice()`: 保持命名一致性

### 测试文件
6. **test/services/formula_history_service_test.dart** - FormulaHistoryService单元测试
   - saveFormula测试（首次保存、重复保存、自动更新时间）
   - getRecentFormulas测试（获取最近5条、空列表、降序排列）
   - deleteFormula测试
   - getFormulaByText测试

7. **test/services/exchange_settings_service_test.dart** - ExchangeSettingsService单元测试
   - getCurrentFormula测试（获取活跃公式、无公式返回null）
   - setDailyFormula测试（禁用其他公式、自动保存历史、设置活跃状态）
   - calculateWithCurrentFormula测试（简单公式、复杂公式、无公式、计算错误）

8. **test/providers/formula_provider_test.dart** - Provider单元测试
   - FormulaHistoryNotifier测试（初始化加载、Realtime订阅、刷新、错误处理）
   - CurrentFormulaNotifier测试（初始化加载、Realtime订阅、刷新、错误处理）
   - Provider集成测试

## 测试覆盖情况

### 完整测试覆盖
- ✅ FormulaCalculator: 已有完整测试（validateFormula、calculate、preview、边界情况）
- ✅ FormulaHistoryService: 13个测试用例覆盖所有核心功能
- ✅ ExchangeSettingsService: 11个测试用例覆盖所有核心功能
- ✅ FormulaProvider: 12个测试用例覆盖Notifier和Provider集成

### 测试策略
- 使用Mockito生成Mock对象
- TDD方式：先写测试，再实现功能
- 覆盖正常流程和异常情况
- 验证数据库操作的正确性

## 核心功能要点

### 1. 公式历史存档逻辑
```dart
// 保存公式时自动去重和更新使用次数
saveFormula(formula, teamId):
  - 查询是否存在相同team_id和formula
  - 如果存在: 更新last_used_at和use_count+1
  - 如果不存在: 插入新记录（use_count=1）
```

### 2. 每日公式设置逻辑
```dart
setDailyFormula(teamId, formula):
  1. 将同team_id的今天其他公式is_active设为false
  2. 插入新的exchange_setting（is_active=true, valid_date=今天）
  3. 调用saveFormula保存到历史记录
```

### 3. Realtime实时同步
- 公式历史变化时自动刷新列表
- 汇率设置变化时自动刷新当前公式
- 使用RealtimeService统一管理订阅

### 4. 数据隔离
- 公式历史按team_id隔离
- 汇率设置按team_id和valid_date隔离
- 每个团队每天只能有一个活跃公式

## 如何集成到现有Flag价格计算流程

### 场景1：远程设置公式后自动计算所有旗子
```dart
// 在远程端调用
await exchangeSettingsService.setDailyFormula(teamId, formula);

// 然后批量更新所有旗子的converted_price
await flagService.recalculatePrices(
  photoId: photoId,
  formula: formula,
);
```

### 场景2：买手更新price_rmb后自动计算converted_price
```dart
// 获取当前活跃公式
final formula = await exchangeSettingsService.getCurrentFormula(teamId);

// 更新买手报价时自动计算换算价格
await flagService.updateBuyerPrice(
  flagId: flagId,
  priceRmb: priceRmb,
  formula: formula, // 传入当前公式
  teamId: teamId,
);
```

### 场景3：在UI中显示公式历史
```dart
// 在Widget中使用Provider
class FormulaInputWidget extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(formulaHistoryProvider(teamId));
    final currentFormulaAsync = ref.watch(currentFormulaProvider(teamId));
    
    return historyAsync.when(
      data: (formulas) => ListView(
        children: formulas.map((formula) => 
          ListTile(title: Text(formula))
        ).toList(),
      ),
      loading: () => CircularProgressIndicator(),
      error: (err, stack) => Text('Error: $err'),
    );
  }
}
```

## 注意事项

1. **Flutter/Dart环境缺失**: 测试文件已创建，但无法运行测试验证。需要安装Flutter SDK后运行：
   ```bash
   flutter test test/services/formula_history_service_test.dart
   flutter test test/services/exchange_settings_service_test.dart
   flutter test test/providers/formula_provider_test.dart
   ```

2. **Mock文件生成**: 需要运行build_runner生成mock文件：
   ```bash
   dart run build_runner build --delete-conflicting-outputs
   ```

3. **数据库Schema**: 确保exchange_settings和formula_history表已按照任务要求创建

4. **公式验证**: 所有公式必须包含"RMB"变量，使用FormulaCalculator.validateFormula()验证

5. **异常处理**: 公式计算错误时不会中断流程，会跳过该旗子或返回null

## 下一步建议

1. 安装Flutter SDK并运行测试验证功能
2. 在UI层集成formulaHistoryProvider和currentFormulaProvider
3. 添加公式输入界面，支持从历史记录快速选择
4. 实现批量更新所有旗子价格的功能
5. 添加公式变更日志记录（用于审计）
