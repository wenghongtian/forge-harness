---
name: recover
description: "会话恢复。从 OpenSpec 文档中恢复任务状态，在会话丢失后重建进度。"
allowed_tools: ["Read", "Write", "Bash", "Grep", "Glob", "AskUserQuestion"]
---

# /recover — 会话恢复

当新会话开始，需要恢复正在进行的项目状态时，使用此技能。OpenSpec 文档是唯一能在会话丢失后存续的真实信息源。

## 恢复流程

### 第一步：获取项目状态

1. 检查 git 状态：
```bash
git branch --show-current
git status --short
git log --oneline -10
```

2. 使用 OpenSpec 查看所有变更及其状态：
```bash
npx openspec list --changes --json
```

3. 读取项目配置：
```bash
cat openspec/config.yaml
```

### 第二步：分析每个活跃变更

对于每个活跃变更，使用 OpenSpec 获取详细状态：

```bash
# 查看工件完成情况
npx openspec status --change <变更名> --json

# 如果有任务，查看实现进度
npx openspec instructions apply --change <变更名> --json
```

OpenSpec 会返回：
- `artifacts`: 每个工件的状态（done/ready/blocked）
- `progress`: 任务完成数/总数
- `state`: blocked/ready/all_done
- `tasks`: 每个任务的完成状态

### 第三步：检查审批状态

阅读关键文件中的审批标记（结构化格式）：
```bash
# 检查设计评审
grep -l "FORGE_GATE:DESIGN_REVIEW:APPROVED" openspec/changes/*/proposal.md 2>/dev/null

# 检查技术评审
grep -l "FORGE_GATE:TECH_REVIEW:APPROVED" openspec/changes/*/design.md 2>/dev/null

# 检查验收
grep -l "FORGE_GATE:ACCEPTANCE:APPROVED" openspec/changes/*/proposal.md 2>/dev/null
```

### 第四步：重建状态报告

基于 OpenSpec 数据构建恢复报告：

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  会话恢复报告
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

项目：[名称]
分支：[当前分支]
技术栈：[从配置中读取]

活跃变更：

### [变更名 1]
- 工件进度：[X/Y 完成]
- 设计评审：[已批准 / 未通过]
- 技术评审：[已批准 / 未通过]
- 任务进度：[X/Y 完成]
- 下一个任务：[描述]
- 最后提交：[相关提交信息]

建议下一步操作：
[基于分析的建议]
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

### 第五步：确认并继续

向用户展示恢复报告并询问：
"我已恢复会话状态。以上信息是否正确？需要从 [下一步操作] 继续吗？"

## 恢复原则
1. **文档即真相** — 信任 OpenSpec，不依赖记忆
2. **Git 是证据** — 用提交历史交叉验证任务状态
3. **不确定就问** — 状态模糊时问用户，而不是猜测
4. **不重做已审批的工作** — 如果审批关卡已通过，尊重该审批
