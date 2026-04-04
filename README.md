# Forge — 从创意到产品落地的 Claude Code 工程框架

Forge 是一个面向 [Claude Code](https://claude.ai/code) 的 harness 框架，支持软件开发的完整生命周期。它融合了 [everything-claude-code](https://github.com/affaan-m/everything-claude-code)（智能体编排）、[gstack](https://github.com/garrytan/gstack)（工作流技能）和 [OpenSpec](https://github.com/Fission-AI/OpenSpec)（规格驱动文档追踪）的最佳实践。

## 特性

- **完整生命周期** — 从模糊的创意到可运行的软件，覆盖产品设计、技术架构、实现、验收全流程
- **前后端分离** — 内置前后端分离架构规范，支持多种技术栈预设
- **规格驱动** — 基于 OpenSpec 追踪所有变更，文档即代码的唯一真实信息源
- **人工审批关卡** — 产品设计、技术架构、功能验收三个阶段强制人工把关
- **会话可恢复** — 会话丢失后可从 OpenSpec 文档完整恢复任务状态
- **第一性原理** — 产品设计和架构设计都遵循第一性原理思维框架

## 快速开始

### 安装

```bash
# 在你的项目目录中运行
curl -fsSL https://raw.githubusercontent.com/wenghongtian/forge-harness/main/install.sh | bash

# 指定技术栈
curl -fsSL https://raw.githubusercontent.com/wenghongtian/forge-harness/main/install.sh | bash -s -- --stack react-node
```

### 可用技术栈

| 名称 | 前端 | 后端 |
|------|------|------|
| `react-node` | React + TypeScript + Vite + shadcn/ui | Node.js + Express + Prisma + PostgreSQL |
| `vue-go` | Vue 3 + TypeScript + Naive UI | Go + Gin + GORM + PostgreSQL |
| `nextjs-python` | Next.js 14+ + shadcn/ui | Python + FastAPI + SQLAlchemy + PostgreSQL |
| `react-native-node` | React Native + Expo + Tamagui | Node.js + Express + Prisma + PostgreSQL |

### 安装后的项目结构

```
my-project/
├── CLAUDE.md              # 项目级说明
├── .claude/
│   ├── settings.json      # 钩子配置
│   └── rules/             # 编码规则
├── forge/                 # Forge 框架文件
│   ├── commands/          # 斜杠指令
│   ├── skills/            # 领域知识
│   ├── agents/            # 智能体定义
│   ├── hooks/             # 自动化钩子
│   └── stacks/            # 技术栈配置
├── openspec/              # 规格文档（OpenSpec）
│   ├── specs/             # 当前系统规格
│   ├── changes/           # 进行中的变更
│   └── schemas/           # forge-lifecycle schema
├── frontend/              # 前端应用（实现后生成）
├── backend/               # 后端应用（实现后生成）
└── contracts/api/         # API 契约
```

## 使用指南

### 从零创建产品：`/genesis`

当你有一个产品创意时，在 Claude Code 中输入 `/genesis`：

```
> /genesis
```

Forge 会引导你完成完整流程：

1. **理解创意** — 通过提问帮你明确需求
2. **产品设计** → 人工审批关卡
3. **技术架构** → 人工审批关卡
4. **项目脚手架** — 自动搭建前后端项目
5. **实现** — 按任务清单逐步实现
6. **验收** → 人工审批关卡
7. **交付** — 归档规格，提交代码

### 功能迭代：`/iterate`

在已有产品上添加或修改功能：

```
> /iterate
```

流程与 `/genesis` 类似，但会：
- 先阅读现有规格了解当前系统
- 使用 OpenSpec 的增量规格格式（ADDED/MODIFIED/REMOVED）
- 自动创建功能分支

### 线上 Bug 修复：`/hotfix`

快速修复 Bug 的精简流程：

```
> /hotfix
```

- 最小化修改，不做额外重构
- 强制添加回归测试
- 精简审批流程

### 会话恢复：`/recover`

当 Claude Code 会话丢失后，恢复工作状态：

```
> /recover
```

Forge 会从 OpenSpec 文档和 git 历史重建完整的工作进度。

### 独立审批关卡

也可以单独调用审批关卡：

| 指令 | 用途 |
|------|------|
| `/design-review` | 展示产品设计供人工审阅 |
| `/tech-review` | 展示技术架构供人工审阅 |
| `/accept` | 展示实现成果供人工验收 |

## 人工审批关卡

Forge 在三个关键节点强制人工审批：

```
创意 → [产品设计] → 设计评审 ✋ → [技术架构] → 技术评审 ✋ → [实现] → 验收 ✋ → 交付
```

- **设计评审** — 审阅产品规格、用户故事、功能范围
- **技术评审** — 审阅架构决策、API 设计、数据模型、技术取舍
- **验收** — 测试实现是否符合预期

审批通过后，Forge 在文档中插入结构化标记：
```html
<!-- FORGE_GATE:DESIGN_REVIEW:APPROVED:2024-01-15 -->
```

**未通过审批的变更无法提交代码**（`human-gate.js` 钩子会阻塞 `git commit`）。

## OpenSpec 集成

Forge 使用 OpenSpec 管理所有文档，不重复造轮子。

### 自定义 Schema：forge-lifecycle

```
proposal（提案）→ product-spec（产品规格）→ design（技术设计）→ tasks（任务清单）→ apply（实现）
```

每个工件依赖上一个完成后才能开始。使用 OpenSpec CLI 查看状态：

```bash
npx openspec status --change <变更名> --json
npx openspec instructions apply --change <变更名> --json
```

### 变更归档

功能完成后，OpenSpec 自动将增量规格合并到主规格：

```bash
npx openspec archive <变更名>
```

## 自动化钩子

| 钩子 | 触发时机 | 行为 |
|------|----------|------|
| `human-gate.js` | `git commit` | 缺少审批标记时**阻塞提交** |
| `doc-sync.js` | 编辑/创建文件 | 无 OpenSpec 变更追踪时**警告** |
| `branch-doc-check.js` | 切换分支 | 无对应变更文件夹时**提醒** |
| `pre-commit-quality.js` | `git commit` | console.log、debugger、.env 文件**警告** |

## 智能体

Forge 定义了 7 个专职智能体，各司其职：

| 智能体 | 角色 | 模型 |
|--------|------|------|
| `product-designer` | 产品愿景、用户故事、交互流程 | Opus |
| `tech-architect` | 架构设计、API 设计、数据库模型 | Opus |
| `frontend-dev` | 前端实现 | Sonnet |
| `backend-dev` | 后端实现 | Sonnet |
| `code-reviewer` | 代码审查与质量把控 | Opus |
| `qa-engineer` | 测试与验证 | Sonnet |
| `doc-keeper` | 文档维护与同步 | Sonnet |

## 领域知识（Skills）

可复用的知识库，供智能体和指令引用：

| 技能 | 内容 |
|------|------|
| `product-design` | 需求分析框架、用户故事规范、功能优先级判断 |
| `ui-ux` | 视觉设计检查清单、交互模式、无障碍要求 |
| `api-design` | RESTful 规范、统一响应格式、状态码、认证模式 |
| `testing-strategy` | 测试金字塔、命名规范、测试数据管理 |
| `openspec-workflow` | OpenSpec 常用命令、工件流程、审批标记格式 |

## 自定义技术栈

复制模板并填写你的技术栈：

```bash
cp stacks/custom.yaml.template stacks/my-stack.yaml
# 编辑 my-stack.yaml
```

安装时指定自定义技术栈：

```bash
curl -fsSL ... | bash -s -- --stack my-stack
```

## 多分支开发

- 每个功能分支拥有自己的 `openspec/changes/<功能>/` 文件夹
- 主分支的 `openspec/specs/` 是权威信息源
- 合并时，先归档先合并分支的变更，后合并的分支基于新基线更新增量规格

## 设计理念

- **第一性原理** — 每个决策从根本事实出发，不盲从惯例
- **规格驱动** — 文档是唯一在会话丢失后存续的真实信息源
- **人机协作** — AI 提案，人类决策
- **默认精美** — 产品必须视觉精良，符合真实用户习惯

## 参考

- [Anthropic: Harness Design for Long-Running Apps](https://www.anthropic.com/engineering/harness-design-long-running-apps)
- [Anthropic: Effective Harnesses for Long-Running Agents](https://www.anthropic.com/engineering/effective-harnesses-for-long-running-agents)
- [everything-claude-code](https://github.com/affaan-m/everything-claude-code)
- [gstack](https://github.com/garrytan/gstack)
- [OpenSpec](https://github.com/Fission-AI/OpenSpec)

## 许可

MIT
