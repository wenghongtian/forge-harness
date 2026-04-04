---
name: iterate
description: "产品功能迭代。在现有产品上添加功能、增强能力或重构，全程规格追踪。"
allowed_tools: ["Read", "Write", "Edit", "Bash", "Grep", "Glob", "Agent", "AskUserQuestion"]
---

# /iterate — 功能迭代

在现有产品上添加功能、增强已有能力或重构时，使用此技能。

## 前提条件
- Forge 框架已安装（`install.sh` 已运行，OpenSpec 已初始化）
- `openspec/specs/` 中有现有规格

---

## 第一阶段：理解变更

**目标**：明确用户想要改变什么以及为什么。

1. 查看现有规格：
```bash
npx openspec list --specs
```

2. 询问用户：
   - "你想添加或修改什么？"
   - "为什么需要这个？它为用户解决什么问题？"
   - "这个变更不应该影响哪些部分？"

3. 阅读当前代码库了解实现情况

---

## 第二阶段：设计变更（人工审批关卡）

**目标**：创建用户批准的变更提案。

1. 创建功能分支：
```bash
git checkout -b feature/<变更名>
```

2. 创建新的 OpenSpec 变更：
```bash
npx openspec new change <变更名> --schema forge-lifecycle
```

3. 按 OpenSpec 指引创建工件：
```bash
npx openspec instructions proposal --change <变更名>
```

4. 委托 **product-designer** 智能体：
   - 传入用户需求、现有规格、当前代码上下文
   - 产出 `proposal.md` 和 `specs/*.md`（增量规格使用 ADDED/MODIFIED/REMOVED 格式）

5. **人工审批关卡 — 设计评审**：

   展示变更设计并询问用户是否批准。
   - 批准后在 proposal.md 中插入 `<!-- FORGE_GATE:DESIGN_REVIEW:APPROVED:YYYY-MM-DD -->`
   - **未经明确批准不得继续**

---

## 第三阶段：技术设计（人工审批关卡）

1. 获取设计指引：
```bash
npx openspec instructions design --change <变更名>
```

2. 委托 **tech-architect** 智能体产出 `design.md`

3. **人工审批关卡 — 技术评审**：
   - 批准后在 design.md 中插入 `<!-- FORGE_GATE:TECH_REVIEW:APPROVED:YYYY-MM-DD -->`
   - **未经明确批准不得继续**

---

## 第四阶段：实现

1. 生成任务清单：
```bash
npx openspec instructions tasks --change <变更名>
```

2. 使用 apply 指引追踪进度：
```bash
npx openspec instructions apply --change <变更名> --json
```

3. 按顺序实现，每完成一个任务标记 `[x]`

4. 实现完成后委托 **code-reviewer** 审查

---

## 第五阶段：验收（人工审批关卡）

1. 委托 **qa-engineer** 自动验证
2. 展示变更内容，请用户测试
3. **未经明确接受不得继续**

---

## 第六阶段：交付

1. 运行完整测试套件
2. 归档变更：
```bash
npx openspec archive <变更名>
```

3. 提交并准备合并：
```bash
git add -A
git commit -m "feat: <变更描述>"
```

4. 如果有文档冲突，先归档目标分支的变更再合并
