---
name: design-review
description: "产品设计评审的人工审批关卡。向用户展示产品规格以获取批准。"
allowed_tools: ["Read", "Bash", "Grep", "Glob", "AskUserQuestion"]
---

# /design-review — 产品设计评审

向用户展示产品设计以获取人工批准。这是强制关卡 — 未经批准不得进入实现阶段。

## 流程

### 第一步：定位设计

使用 OpenSpec 查找活跃变更和产品规格：
```bash
pnpm exec openspec list --changes --json
pnpm exec openspec status --change <变更名> --json
```

读取提案和产品规格：
- `openspec/changes/<变更名>/proposal.md`
- `openspec/changes/<变更名>/specs/product-spec.md`

### 第二步：展示评审

用结构化格式向用户展示：

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  产品设计评审
  变更：<变更名>
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

## 愿景
[1-2 句产品愿景]

## 目标用户
[面向谁]

## 核心功能
1. [功能 1] — [简述]
2. [功能 2] — [简述]

## 用户流程
[主要使用路径描述]

## 范围边界
- 范围内：[包含什么]
- 范围外：[排除什么及原因]

完整规格：openspec/changes/<变更名>/specs/product-spec.md
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

### 第三步：收集决定

询问用户（使用 AskUserQuestion）：

"请审阅以上产品设计：
- **批准** — 设计满意，进入技术架构阶段
- **修改：[反馈]** — 我会根据反馈更新后重新展示
- **讨论** — 先讨论具体方面再决定
- **拒绝** — 换一个方向重新设计

你的决定是？"

### 第四步：处理决定

- **批准**：在 proposal.md 中插入 `<!-- FORGE_GATE:DESIGN_REVIEW:APPROVED:YYYY-MM-DD -->`（用实际日期）
- **修改**：理解反馈 → 更新规格 → 重新展示（最多 5 轮）
- **讨论**：对话 → 记录结论 → 更新规格 → 重新展示
- **拒绝**：记录原因，通知调用方重新进入设计阶段
