---
name: accept
description: "功能验收的人工审批关卡。用户测试并批准实现。"
allowed_tools: ["Read", "Bash", "Grep", "Glob", "Agent", "AskUserQuestion"]
---

# /accept — 功能验收

实现完成后，用户需要测试和接受功能时，使用此技能。

## 流程

### 第一步：自动验证

1. 使用 OpenSpec 检查任务完成情况：
```bash
pnpm exec openspec instructions apply --change <变更名> --json
```

2. 委托 **qa-engineer** 智能体进行自动检查

3. 运行完整测试套件：
```bash
cd frontend && npm test 2>&1 || true
cd backend && npm test 2>&1 || true
```

### 第二步：启动应用

```bash
cd backend && npm run dev &
cd frontend && npm run dev
```

### 第三步：展示验收

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  功能验收
  变更：<变更名>
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

## 实现内容
[实现摘要]

## QA 验证
- 测试：[X/Y 通过]
- 任务：[X/Y 完成]
- 发现的问题：[数量 或 "无"]

## 测试清单
请验证以下内容：
- [ ] [核心场景 1]
- [ ] [核心场景 2]
- [ ] [边界情况 1]

## 访问地址
- 前端：http://localhost:[端口]
- 后端：http://localhost:[端口]
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

### 第四步：收集决定

"请测试功能后告诉我：
- **接受** — 功能符合预期，交付吧
- **Bug：[描述]** — 发现了一个 Bug
- **修改：[描述]** — 功能正常但想调整
- **拒绝** — 不满足需求

你的判定是？"

### 第五步：处理决定

- **接受**：在 proposal.md 中插入 `<!-- FORGE_GATE:ACCEPTANCE:APPROVED:YYYY-MM-DD -->`（用实际日期），进入归档和交付。
- **Bug**：记录 → 修复 → 重新测试 → 重新展示
- **修改**：评估是否在范围内（如果不是建议用 /iterate） → 实现 → 重新展示
- **拒绝**：理解原因 → 判断是设计问题还是实现问题 → 对应修复
