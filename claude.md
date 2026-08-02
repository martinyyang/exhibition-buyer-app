每个更改文件代码并上传到github的实现任务都必须在最终响应之前以 git action成功为结束。  

- 在编辑前检查 `git status`，并将预先存在的或并发更改视为用户拥有的。  
- 在提交前审查最终差异并运行相应的验证。  
- 只暂存属于当前任务的文件或块。除非用户明确要求，否则绝不捆绑不相关的更改。  
- 在 `main` 上使用简洁的描述性提交消息，报告提交哈希，除非被要求，否则不要推送、修改或重写历史。  
- 只读任务和没有文件更改的任务不创建空提交。

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