---
name: openspec-workflow
description: OpenSpec 工作流参考。常用 CLI 命令和工件管理的快速参考。
---

# OpenSpec 工作流参考

## 何时使用
当需要操作 OpenSpec（创建变更、查看状态、归档等）时引用此技能。

## 常用命令

### 查看状态
```bash
# 列出所有变更
pnpm exec openspec list --changes --json

# 列出所有规格
pnpm exec openspec list --specs --json

# 查看某个变更的工件状态
pnpm exec openspec status --change <变更名> --json
```

### 创建变更
```bash
# 创建新变更（使用项目默认 schema）
pnpm exec openspec new change <变更名>

# 指定 schema
pnpm exec openspec new change <变更名> --schema forge-lifecycle
```

### 获取工件指引
```bash
# 获取某个工件的创建指引（包含模板、依赖、说明）
pnpm exec openspec instructions <工件ID> --change <变更名>

# 获取实现阶段的指引（任务进度、下一步）
pnpm exec openspec instructions apply --change <变更名> --json
```

### 归档变更
```bash
# 归档并合并规格到主规格
pnpm exec openspec archive <变更名>

# 跳过确认
pnpm exec openspec archive <变更名> -y

# 跳过规格更新（仅基础设施变更）
pnpm exec openspec archive <变更名> --skip-specs
```

### 验证
```bash
# 验证某个变更
pnpm exec openspec validate <变更名>

# 验证所有
pnpm exec openspec validate --all
```

## forge-lifecycle 工件流程

```
proposal（提案）
    ↓
product-spec（产品规格）  ← 需要人工审批
    ↓
design（技术设计）        ← 需要人工审批
    ↓
tasks（任务清单）
    ↓
apply（实现）             ← 需要人工验收
```

每个工件依赖上一个工件完成后才能开始。使用 `openspec status` 查看哪些工件可以创建。

## 增量规格格式

在 `specs/*.md` 中描述变更内容：

```markdown
## ADDED Requirements

### Requirement: 用户导出功能
用户可以将数据导出为 CSV 格式。

#### Scenario: 正常导出
- GIVEN 用户有至少 1 条数据
- WHEN 点击"导出"按钮
- THEN 下载包含所有数据的 CSV 文件

## MODIFIED Requirements

### Requirement: 用户列表
修改后的需求描述...（必须包含完整的更新内容）

## REMOVED Requirements

### Requirement: 旧版报表
- Reason: 被新的导出功能替代
- Migration: 使用导出功能代替
```

## 审批标记格式

在对应文件中插入结构化审批标记（HTML 注释，防误匹配）：

```markdown
<!-- FORGE_GATE:DESIGN_REVIEW:APPROVED:2024-01-15 -->
<!-- FORGE_GATE:TECH_REVIEW:APPROVED:2024-01-16 -->
<!-- FORGE_GATE:ACCEPTANCE:APPROVED:2024-01-20 -->
```

- 设计评审标记写入 `proposal.md`
- 技术评审标记写入 `design.md`
- 验收标记写入 `proposal.md`

这些标记被 Forge 的 `human-gate.cjs` 钩子读取。**缺少标记时提交会被阻塞。**
