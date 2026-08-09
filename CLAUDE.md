每个更改文件代码并上传到 GitHub 的实现任务都必须在最终响应之前以 GitHub Action 成功为结束。  

- 在编辑前检查 `git status`，并将预先存在的或并发更改视为用户拥有的。  
- **验证策略**：本地仅运行 `flutter analyze` 检查语法错误，不执行完整构建（项目是 Web 优先，生产构建由 Cloudflare Pages 自动完成）
- 只暂存属于当前任务的文件或块。除非用户明确要求，否则绝不捆绑不相关的更改。  
- 在 `main` 上使用简洁的描述性提交消息，报告提交哈希，除非被要求，否则不要推送、修改或重写历史。  
- **推送后必须跟进**：推送到 GitHub 后，使用 `gh run list --limit 3` 和 `gh run view <run-id>` 监控 GitHub Action 状态，直到构建成功或失败。如果失败，分析日志并修复问题。
- 只读任务和没有文件更改的任务不创建空提交。

## 项目架构关键点

- **Web 优先平台**：主要针对 Web 浏览器和移动端 Web，不开发原生 APK
- **部署平台**：Cloudflare Pages 自动部署（推送 main 分支触发），生产环境变量在 Cloudflare 控制台配置
  - **构建环境**：Flutter 3.24.5（与本地开发版本一致）
  - **构建命令**：安装 Flutter → 注入环境变量 → `flutter build web --release`
  - **重要**：pubspec.yaml 的 assets 不应包含 `.env`（生产环境不需要，会导致构建失败）
- **环境变量加载**：
  - 生产环境（Cloudflare Pages）：编译时变量 `String.fromEnvironment`
  - 本地开发：`.env` 文件（`flutter_dotenv`）
  - 自动检测运行环境，无需手动切换
- **中国网络优化**：支持 Cloudflare Workers 代理，通过 `SUPABASE_PROXY_URL` 环境变量启用
- **实时协作**：Supabase Realtime 用于多用户同步（事件、摊位、照片、旗子）
- **照片标注**：十字准星旗子，支持移动端缩放和点击
- **价格转换**：团队级自定义公式计算器
- **照片格式**：WebP 格式（体积减少 60-80%），优化上传/加载速度
- **团队管理**：
  - 团队密码：必填功能，用于安全验证（`teams.password` 字段，NOT NULL）
  - 邀请码：团队 ID 前 6 位大写字母（`Team.inviteCode` getter）
  - 加入团队：需要团队名/邀请码 + 密码双重验证
  - 找回邀请码：`/team-retrieve` 路由，输入团队 ID + 密码验证

## 更新历史

### 2026-08-09

#### 旗子功能修复和优化 (commit: 33f3662, 185edb5, df3f39a, 140972d)
- **修复旗子编号显示为 0 的问题**：
  - 根因：Realtime INSERT 事件会添加新旗子而非替换临时旗子，导致临时旗子（number=0）和真实旗子同时存在
  - 修复：`flag_provider.dart` 的 INSERT 事件处理器现在会检测临时旗子（ID 以 `temp_` 开头且位置接近），并替换而非追加
  - 结果：新创建的旗子立即显示正确的序号（1, 2, 3...）
- **修复数据库触发器错误**：
  - 创建迁移 `supabase/migrations/20260809000002_fix_flag_number_trigger.sql`
  - 问题：`SELECT MAX(number) ... FOR UPDATE` 导致 PostgreSQL 错误（聚合函数不允许 FOR UPDATE）
  - 解决方案：使用 `ORDER BY number DESC LIMIT 1 FOR UPDATE` 替代 MAX，保持原子性和行锁
  - 应用指南：`supabase/APPLY_FLAG_TRIGGER_FIX.md`
- **移除旗子标记上的删除按钮**：
  - 从 `photo_detail_screen.dart` 和 `photo_annotation_canvas.dart` 移除红色 X 删除按钮
  - 删除操作仅保留在旗子列表表格中（设计决策：照片视图用于标注，列表视图用于管理）
- **移除照片网格中的供应商信息功能**：
  - 从 `photo_grid_screen.dart` 移除"添加供应商信息"菜单项和相关对话框
  - 供应商信息是摊位级别属性，仅在摊位列表管理，不应在照片级别出现

#### UX 改进：移除隐藏手势，全面使用可见按钮 (commit: c77a9dd, 93da8c5, 72c3927)
- **改动**：将所有长按手势替换为可见的UI控件，降低用户认知难度
- **受影响组件**：
  - `booth_list_screen.dart`：移除调试用的红色 URL 显示（原为临时诊断代码）
  - `event_selection_screen.dart`：事件卡片右上角添加三点菜单按钮（Icons.more_vert）
  - `photo_grid_screen.dart`：照片卡片右上角添加半透明三点菜单按钮（黑色背景 50% 透明度）
  - ~~`photo_detail_screen.dart`：旗子标记右上角添加红色 X 删除按钮（20x20 圆形，白色边框）~~（已在后续迭代中移除）
  - ~~`photo_annotation_canvas.dart`：旗子标记同样添加红色 X 删除按钮~~（已在后续迭代中移除）
- **设计原则**：
  - 菜单操作（编辑/删除多选）使用三点图标 (⋮)
  - 所有交互必须有可见UI提示，不依赖用户"发现"隐藏手势
- **测试修复**：更新 `ux_team_experience_test.dart` 和 `team_security_invite_test.dart`，适配新的 UI 流程（BottomSheet → AlertDialog）

### 2026-08-05

#### 事件优先 UX 改进 (commit: c532313)
- **改动**：场次选择页面空状态从"加入团队"改为"创建场次"作为主要操作
- **原因**：用户主要工作流是创建场次 → 添加摊位 → 拍照标注，团队选择已在登录后自动完成
- **UI 变更**：
  - 空状态图标：`Icons.event_busy` → `Icons.event_note`
  - 主要按钮：从"一键匹配/加入现场团队"改为"创建新场次"
  - 按钮颜色：蓝色 → 绿色（与创建操作一致）
  - 提示文案：从团队相关提示改为"创建您的第一个展会场次，开始采购协作"
- **团队持久化确认**：用户登录后团队信息已持久化，路由自动判断 `userTeamId` 存在则直接进入 `/events`，无需每次重新选择团队

### 2026-08-04

#### Cloudflare Pages 部署修复 (commit: 95dc40e)
- 根因：pubspec.yaml 中声明 `.env` 为 asset，但 Cloudflare Pages 构建环境中该文件不存在，导致构建失败
- 修复：从 pubspec.yaml assets 列表移除 `.env`（生产环境使用编译时环境变量，不需要 .env 文件）
- 构建配置：安装 Flutter 3.24.5 到 `$HOME/flutter`，设置 PATH，执行 `flutter build web` 并通过 `--dart-define` 注入环境变量
- 部署成功：生产环境 URL https://exhibition-buyer-app.pages.dev
- `.env` 文件仅用于本地开发（已在 .gitignore）

#### 依赖版本锁定 (commit: 60bb83c)
- 锁定 Cloudflare Pages 构建环境使用 Flutter 3.24.5（与本地开发一致）
- intl 依赖版本回退到 `^0.19.0`（匹配 Flutter 3.24.5 要求）
- 避免 Flutter 版本不一致导致的依赖冲突

### 2026-08-03

#### 登录后获取 Profile 失败终极修复 (commit: 82381f3, caed19f)
- 根因：长时间不登录后，浏览器存留已过期的 Supabase Access Token，登录新 Session 挂载存在微小延迟/旧 token 干扰，导致获取 `users` 表 RLS/请求抛出异常（`Failed to fetch user profile after login`）
- 修复：
  - `auth_service.dart`: 登录前主动显式清理残存的过期旧 Session（`signOut()` 清场）
  - `auth_service.dart`: 引入带指数退避的 3 次自愈重试机制 `_fetchUserProfileWithRetry()`，若 `users` 表记录暂缺则自动建立默认账号记录
- 编译修复：补全 `TeamService` 兼容方法 `findAndVerifyTeam` 与 `joinTeamByInviteCodeOrName`
- 隔离测试：新增 `test/services/auth_service_expired_session_test.dart` 并通过

#### 团队密码安全验证（commit: ceb3cb0, 659cc5f）
- `teams.password` 改为必填（NOT NULL），防止仅凭团队名加入
- 加入团队需要：团队名/邀请码 + 密码双重验证
- 支持两种加入方式：
  - 团队名 + 密码（智能匹配，处理同名团队）
  - 邀请码（6位大写）+ 密码
- 登录页新增"加入团队"表单，无需注册即可加入
- 现有团队自动分配默认密码（`LEGACY_TEAM_<8-char-id>`）
- 数据库迁移：`20260803000001` 添加字段，`20260803000002` 设置必填

#### 团队密码和邀请码找回（commit: ea39bae）
- 新增 `teams.password` 字段（可选，明文存储）
- 新增 `/team-retrieve` 路由和 `TeamRetrieveScreen` 页面
- 团队创建时可设置密码，或使用系统生成的建议密码
- 通过团队 ID + 密码验证即可查看邀请码
- 国际化：团队创建和找回页面支持英语
- 登录页面邮箱字段添加 `AutofillHints.username` 支持浏览器密码管理器

### Cloudflare Pages 部署支持（commit: f2fce8b, 9bed4e6）
- `lib/main.dart` 支持编译时环境变量（`String.fromEnvironment`）
- 自动检测运行环境：Cloudflare Pages vs 本地开发
- 新增 `docs/CLOUDFLARE_PAGES_DEPLOYMENT.md` 完整部署指南
- README 添加部署章节，说明生产环境 URL 和环境变量配置方式

### 照片上传优化（commit: c11e215）
- WebP 格式替代 JPEG：`photo_service.dart` 使用 `CompressFormat.webp`
- 上传进度追踪：5 个阶段回调（压缩 10% → 上传 30% → URL 70% → 保存 90% → 完成 100%）
- 统一错误处理：`lib/core/utils/error_handler.dart` 提供友好错误提示和重试功能
- 性能提升：上传时间 5-10 秒 → 1-3 秒（3G 网络），流量节省 60-80%

## 旗子定位实现规则（关键！）

**旗子形状：十字准星（40x40 px），中心点在 (20, 20)**

修改 `lib/features/photo/screens/photo_detail_screen.dart` 中的旗子定位时，必须遵守：

1. **定位偏移：`left: -20, top: -20`**（让十字准星中心对齐到点击位置）
   - ❌ 绝对不能用 `top: -60`（那是旧的旗子底部对齐逻辑，已废弃）

2. **网格吸附：基于图片显示区域的百分比**
   - ✅ 正确：`final gridSize = displayWidth * 0.015;`（图片显示宽度的 1.5%）
   - ❌ 错误：`static const double _gridCellSize = 15.0;`（固定像素在不同图片产生不同误差）
   - ❌ 错误：`containerSize.width * 0.015`（容器包含留白，必须用图片实际显示尺寸）

3. **坐标计算：必须基于图片实际显示区域（BoxFit.contain）**
   - 先计算图片在容器中的 `displayWidth`、`displayHeight`、`offsetX`、`offsetY`
   - 点击坐标必须减去偏移：`(localPosition.dx - offsetX) / displayWidth`
   - 检查是否在图片内（0-1 范围），留白区域忽略点击

参考 commits: 82d785d, 2ec6a50, 31a7f86, 0812da3  
详细实现见：`C:\Users\Administrator\.claude\projects\E--gemini-projects-exhibition-buyer-app\memory\flag_positioning_implementation.md`