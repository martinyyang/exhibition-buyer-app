# Bug 修复：注册后创建事件失败

## 问题描述

用户注册后第一次尝试创建事件时出现错误：
```
Create failed: Exception: User is not part of a team
```

## 根本原因

注册流程中存在时序问题：

1. **注册流程** (register_screen.dart 第 96-120 行)：
   - 步骤 1: 创建用户（`team_id` = null）
   - 步骤 2: 创建团队
   - 步骤 3: 更新用户的 `team_id`
   - 步骤 4: 跳转到事件选择页面

2. **问题**：
   - 跳转后，用户的 `team_id` 可能还没完全生效（数据库写入延迟或缓存）
   - RLS 策略要求创建事件时必须有 `team_id`（initial_schema.sql 第 157-163 行）

## 修复方案

### 1. 注册流程改进 (register_screen.dart)

**修改前**：
```dart
final userId = authService.currentUserId;
if (userId != null) {
  await teamService.updateUserTeam(userId, team.id);
}
// 直接跳转，不验证
context.go('/event-selection');
```

**修改后**：
```dart
final userId = authService.currentUserId;
if (userId == null) {
  throw Exception('User ID not found after registration');
}

await teamService.updateUserTeam(userId, team.id);

// 验证 team_id 已成功更新
final updatedUser = await authService.getCurrentUser();
if (updatedUser?.teamId == null) {
  throw Exception('Failed to associate user with team');
}

// 确认更新成功后才跳转
context.go('/event-selection');
```

**改进点**：
- 强制验证 `userId` 存在
- 等待 `team_id` 更新完成
- 验证更新成功才允许跳转

### 2. 创建事件重试逻辑 (event_selection_screen.dart)

**修改前**：
```dart
final user = await authService.getCurrentUser();
if (user?.teamId == null) {
  throw Exception(l10n.userNotInTeam);
}
```

**修改后**：
```dart
// 重试逻辑：有时注册后 team_id 更新需要时间
String? teamId;
for (int i = 0; i < 3; i++) {
  final user = await authService.getCurrentUser();
  teamId = user?.teamId;

  if (teamId != null) break;

  // 如果是第一次重试，等待 1 秒
  if (i < 2) {
    await Future.delayed(const Duration(seconds: 1));
  }
}

if (teamId == null) {
  throw Exception(l10n.userNotInTeam);
}
```

**改进点**：
- 最多重试 3 次
- 每次重试间隔 1 秒
- 应对数据库缓存延迟

## RLS 策略说明

创建事件的 RLS 策略 (initial_schema.sql)：
```sql
CREATE POLICY "Team members can insert events"
  ON events FOR INSERT
  WITH CHECK (
    team_id IN (
      SELECT team_id FROM users WHERE id = auth.uid()
    )
  );
```

**策略要求**：
- 插入事件时，`team_id` 必须匹配当前用户的 `team_id`
- 如果用户的 `team_id` 为 null，策略检查失败

## 测试步骤

1. 清除浏览器缓存和应用数据
2. 注册新用户
3. 注册成功后应自动跳转到事件选择页面
4. 点击右上角 "+" 创建事件
5. 填写事件信息并提交
6. 应该成功创建事件，不再出现 "User is not part of a team" 错误

## 相关文件

- `lib/features/auth/screens/register_screen.dart` - 注册流程
- `lib/features/event/screens/event_selection_screen.dart` - 创建事件
- `supabase/migrations/20260722000000_initial_schema.sql` - RLS 策略
- `fix_team_association.sql` - 数据库验证查询

## 部署说明

修改仅涉及客户端代码，不需要数据库迁移。

1. 构建新版本：`flutter build web`
2. 部署到 GitHub Pages（已配置 CI/CD）
3. 通知用户清除缓存后刷新
