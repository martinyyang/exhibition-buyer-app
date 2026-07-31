# 多现场、多远程功能分析

## 问题1: 多现场、多远程是否已实现？

### ✅ 数据库层面完全支持

#### 多现场（一个团队多个活动）
```sql
CREATE TABLE events (
  id UUID PRIMARY KEY,
  name TEXT NOT NULL,
  team_id UUID REFERENCES teams(id),  -- 一个团队可以有多个events
  is_active BOOLEAN DEFAULT FALSE,
  ...
);
```
- **结论**: ✅ 支持一个团队创建多个场次

#### 多远程（一个团队多个remote用户）
```sql
CREATE TABLE users (
  id UUID PRIMARY KEY,
  role TEXT CHECK (role IN ('buyer', 'remote')),  -- 可以是buyer或remote
  team_id UUID REFERENCES teams(id),  -- 多个用户可以属于同一个团队
  ...
);
```
- **结论**: ✅ 支持一个团队有多个buyer和多个remote成员

### ✅ 应用层面完全支持

#### 事件服务 (event_service.dart)
- `getEventsForTeam(teamId)` - 获取团队所有场次
- `createEvent(...)` - 创建新场次（需要teamId）
- `setActiveEvent(eventId, teamId)` - 切换活跃场次

#### 团队服务 (team_service.dart)
- `getTeamMembers(teamId)` - 获取团队所有成员（包括所有buyer和remote）
- 没有对成员数量的限制

---

## 问题2: 远程端是否可以发起新团队？

### ✅ 代码层面：完全支持

#### TeamService (team_service.dart)
```dart
// 第11-18行：创建团队函数
Future<Team> createTeam({required String name}) async {
  final teamData = {'name': name};
  final result = await _supabase.from('teams').insert(teamData).select().single();
  return Team.fromJson(result);
}
```
- **没有角色检查**，buyer和remote都可以调用

#### 智能加入/创建逻辑 (第26-52行)
```dart
Future<Team> joinTeamByInviteCodeOrName(String input) async {
  // 1. 先尝试匹配邀请码
  // 2. 再尝试匹配团队名称
  // 3. 都不匹配时自动创建新团队
  return await createTeam(name: cleanInput);
}
```
- **结论**: ✅ 任何用户（包括remote）输入一个不存在的团队名称时会自动创建

### ✅ UI层面：完全支持

#### SettingsScreen (settings_screen.dart)
```dart
// 第124-130行：无团队用户
if (user.teamId == null || user.teamId!.isEmpty) {
  return ListTile(
    title: Text(l10n.teamInfo),
    subtitle: Text(l10n.notInTeamTip),
    onTap: () => _showEditTeamDialog(context, ref, l10n, user, ''),
  );
}
```

```dart
// 第189-249行：加入/创建团队对话框
showDialog(
  ...
  content: TextFormField(
    labelText: l10n.inviteCodeOrNameLabel,
    hintText: l10n.inviteCodeOrNameHint,
  ),
  ...
  onPressed: () async {
    final team = await teamService.joinTeamByInviteCodeOrName(input);
    // 自动加入或创建
  }
)
```

- **UI没有区分buyer和remote**
- **所有用户都看到相同的"加入团队"界面**
- **输入不存在的名称会自动创建新团队**

---

## 🎯 总结

| 功能 | 状态 | 说明 |
|------|------|------|
| 一个团队多个场次 | ✅ 已实现 | events表通过team_id关联，无数量限制 |
| 一个团队多个买手 | ✅ 已实现 | users表支持多个role='buyer'的用户 |
| 一个团队多个远程 | ✅ 已实现 | users表支持多个role='remote'的用户 |
| Remote创建团队 | ✅ 已实现 | 代码和UI都支持，无角色限制 |
| Buyer创建团队 | ✅ 已实现 | 代码和UI都支持，无角色限制 |

### 使用方式

#### 创建新团队（任何角色）
1. 进入设置页面
2. 点击"团队信息"或"加入团队"
3. 输入一个**不存在的团队名称**
4. 系统自动创建新团队并加入

#### 加入现有团队
1. 进入设置页面
2. 点击"团队信息"或"加入团队"
3. 输入**6位邀请码**或**现有团队名称**
4. 加入该团队

#### 创建多个场次
1. 团队成员进入"场次选择"页面
2. 点击"创建新场次"
3. 输入场次信息
4. 团队所有成员都能看到这个场次

---

## 📝 结论

**所有功能都已完整实现！**

- ✅ 支持多现场（一个团队多个events）
- ✅ 支持多远程（一个团队多个remote用户）
- ✅ Remote和Buyer权限完全平等
- ✅ 任何角色都可以创建新团队
- ✅ 任何角色都可以创建新场次

**没有任何UI或代码限制Remote用户的权限。**
