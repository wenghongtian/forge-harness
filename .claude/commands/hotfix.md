---
name: hotfix
description: "线上 Bug 修复。最小化修改，全程可追踪。"
allowed_tools: ["Read", "Write", "Edit", "Bash", "Grep", "Glob", "Agent", "AskUserQuestion"]
---

# /hotfix — 线上 Bug 修复

有 Bug 需要快速修复时，使用此技能。这是一个精简流程，审批关卡更轻量。

## 前提条件
- Forge 框架已安装（`install.sh` 已运行，OpenSpec 已初始化）
- 有 Bug 报告（描述、复现步骤、预期 vs 实际行为）

---

## 第一阶段：复现和记录

1. 如用户未提供，询问 Bug 详情：
   - "预期行为是什么？"
   - "实际行为是什么？"
   - "如何复现？"

2. 创建热修复分支和 OpenSpec 变更：
```bash
git checkout -b hotfix/<bug名>
pnpm exec openspec new change hotfix-<bug名> --schema forge-lifecycle
```

3. 按 OpenSpec 指引写提案：
```bash
pnpm exec openspec instructions proposal --change hotfix-<bug名>
```

在 `proposal.md` 中记录 Bug 报告、根因（待分析）和修复策略。

---

## 第二阶段：根因分析

1. 阅读相关规格了解预期行为：
```bash
pnpm exec openspec list --specs
```

2. 追踪代码路径，定位问题根因

3. 在 `proposal.md` 中补充根因分析和修复策略

---

## 第三阶段：修复实现

### 热修复原则
- **只做最小修改** — 修复 Bug，不做其他事
- **不重构** — 留给 /iterate
- **不加新功能** — 即使看到机会
- **添加回归测试** — 确保此 Bug 不会再次出现

1. 编写一个失败的测试来复现 Bug
2. 应用修复
3. 验证测试通过
4. 运行完整测试套件检查回归

5. 如果修复改变了已定义的行为，写增量规格：
```bash
pnpm exec openspec instructions product-spec --change hotfix-<bug名>
```

---

## 第四阶段：快速验收（人工审批关卡）

```
Bug 修复已准备好审阅：

Bug：[描述]
根因：[简要说明]
修复：[改了什么]
测试：[全部通过，已添加回归测试]

修改的文件：
- [文件1]：[改动内容]
- [文件2]：[改动内容]

请验证修复。这个问题解决了吗？（接受 / 需要继续修改）
```

- **未经明确接受不得继续**

---

## 第五阶段：交付

```bash
pnpm exec openspec archive hotfix-<bug名>
git add -A
git commit -m "fix: <Bug 描述>

根因：<简要根因>
已添加回归测试。"
```
