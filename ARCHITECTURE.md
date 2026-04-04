# Forge 架构文档

## 架构概览

```
┌─────────────────────────────────────────────────────────────────┐
│                        用户（Claude Code）                        │
│                                                                   │
│  /genesis    /iterate    /hotfix    /recover    /design-review   │
│      │           │          │           │             │           │
└──────┼───────────┼──────────┼───────────┼─────────────┼──────────┘
       │           │          │           │             │
       ▼           ▼          ▼           ▼             ▼
┌─────────────────────────────────────────────────────────────────┐
│                      Commands（指令层）                           │
│                                                                   │
│  编排完整工作流，协调智能体执行，控制人工审批关卡                      │
│  文件位置：commands/*.md                                          │
└──────────────────────────┬──────────────────────────────────────┘
                           │
              ┌────────────┼────────────┐
              │            │            │
              ▼            ▼            ▼
┌──────────────────┐ ┌──────────┐ ┌──────────────────┐
│  Agents（智能体） │ │  Skills  │ │  Hooks（钩子）    │
│                  │ │（领域知识）│ │                  │
│  执行具体任务     │ │          │ │  自动化守护       │
│  agents/*.md     │ │  提供方法 │ │  hooks/*.js      │
│                  │ │  论参考   │ │                  │
│  product-designer│ │  skills/  │ │  human-gate      │
│  tech-architect  │ │  *.md    │ │  doc-sync        │
│  frontend-dev    │ │          │ │  branch-doc-check│
│  backend-dev     │ │          │ │  pre-commit-qual │
│  code-reviewer   │ │          │ │                  │
│  qa-engineer     │ │          │ │                  │
│  doc-keeper      │ │          │ │                  │
└────────┬─────────┘ └──────────┘ └────────┬─────────┘
         │                                  │
         ▼                                  ▼
┌─────────────────────────────────────────────────────────────────┐
│                      OpenSpec（文档层）                           │
│                                                                   │
│  规格文档：openspec/specs/          变更追踪：openspec/changes/    │
│  自定义 Schema：forge-lifecycle     归档：openspec/changes/archive/ │
│                                                                   │
│  proposal → product-spec → design → tasks → apply                │
└──────────────────────────┬──────────────────────────────────────┘
                           │
                           ▼
┌─────────────────────────────────────────────────────────────────┐
│                      基础设施层                                   │
│                                                                   │
│  .claude/rules/   编码规则（架构、前端、后端、第一性原理）            │
│  .claude/settings.json   钩子注册                                 │
│  stacks/*.yaml    技术栈预设                                      │
│  schemas/         OpenSpec 自定义 schema                          │
└─────────────────────────────────────────────────────────────────┘
```

## 分层设计

### 第一层：指令层（Commands）

**职责**：编排工作流，是用户的直接交互入口。

指令不包含具体的业务逻辑，而是：
1. 定义工作流阶段和顺序
2. 在合适的时机委托给对应的智能体
3. 在关键节点触发人工审批关卡
4. 调用 OpenSpec CLI 管理文档状态

```
/genesis ─── 完整生命周期编排（8 个阶段）
/iterate ─── 增量开发编排（6 个阶段）
/hotfix ──── 精简修复编排（5 个阶段）
/recover ─── 状态重建（不涉及编排）
/design-review ── 独立审批关卡
/tech-review ──── 独立审批关卡
/accept ────────── 独立审批关卡
```

**设计决策**：指令与技能分离。指令回答"做什么、什么顺序"，不回答"怎么做好"。

### 第二层：智能体层（Agents）

**职责**：执行具体任务，每个智能体有明确的角色边界。

```
                    ┌─────────────────┐
                    │ product-designer │ ← 产品设计（Opus）
                    └────────┬────────┘
                             │ 产出规格
                    ┌────────▼────────┐
                    │  tech-architect  │ ← 技术架构（Opus）
                    └────────┬────────┘
                             │ 产出设计
               ┌─────────────┼─────────────┐
               ▼                           ▼
      ┌─────────────┐              ┌─────────────┐
      │ backend-dev  │              │ frontend-dev │ ← 实现（Sonnet）
      └──────┬──────┘              └──────┬──────┘
             │                            │
             └────────────┬───────────────┘
                          ▼
                 ┌─────────────────┐
                 │  code-reviewer   │ ← 代码审查（Opus）
                 └────────┬────────┘
                          ▼
                 ┌─────────────────┐
                 │   qa-engineer    │ ← 质量验证（Sonnet）
                 └────────┬────────┘
                          ▼
                 ┌─────────────────┐
                 │    doc-keeper    │ ← 文档维护（Sonnet）
                 └─────────────────┘
```

**设计决策**：
- 决策类角色（product-designer、tech-architect、code-reviewer）使用 Opus 模型
- 执行类角色（frontend-dev、backend-dev、qa-engineer、doc-keeper）使用 Sonnet 模型
- 每个智能体只声明需要的工具，遵循最小权限原则

### 第三层：领域知识层（Skills）

**职责**：提供可复用的方法论和规范参考，被智能体和指令引用。

```
skills/
├── product-design/     需求分析、用户故事、优先级判断
├── ui-ux/              视觉规范、交互模式、无障碍标准
├── api-design/         RESTful 规范、统一格式、错误码
├── testing-strategy/   测试金字塔、命名规范、数据管理
└── openspec-workflow/  OpenSpec 命令参考、工件流程
```

**设计决策**：Skills 是被动的知识文档，不是可执行的流程。它们不定义"做什么"，只定义"做到什么标准"。

### 第四层：守护层（Hooks）

**职责**：自动化质量守护，在工具执行前后触发。

```
PreToolUse                              PostToolUse
    │                                       │
    ├── human-gate.js ──── git commit ────── 阻塞（exit 2）
    │   检查审批标记                          或放行
    │
    ├── branch-doc-check.js ── git checkout ── 提醒创建变更
    │   检查变更文件夹
    │                                       ├── doc-sync.js ──── Edit/Write
    ├── pre-commit-quality.js ── git commit  │   检查 OpenSpec 变更
    │   检查 console.log/.env/debugger       │   追踪是否存在
    │                                       │
```

**设计决策**：
- `human-gate.js` 是唯一**阻塞**的钩子（exit 2），其他都只警告
- 钩子遵循 Claude Code 钩子协议：stdin 接收 JSON，stdout 输出原始数据，stderr 输出警告
- 钩子出错时**放行**（不会因钩子 bug 阻塞正常工作）

### 第五层：文档层（OpenSpec）

**职责**：管理所有规格和变更追踪。Forge 不重新实现 OpenSpec 的功能。

```
openspec/
├── specs/                        ← 权威规格（归档后更新）
│   └── <领域>/spec.md
├── changes/                      ← 活跃变更
│   ├── <变更名>/
│   │   ├── .meta.json            ← OpenSpec 元数据
│   │   ├── proposal.md           ← 提案（为什么）
│   │   ├── specs/                ← 增量规格（改什么）
│   │   │   └── product-spec.md
│   │   ├── design.md             ← 技术设计（怎么做）
│   │   └── tasks.md              ← 任务清单（追踪进度）
│   └── archive/                  ← 已归档变更
└── schemas/
    └── forge-lifecycle/          ← 自定义 schema
        ├── schema.yaml
        └── templates/
```

**自定义 Schema：forge-lifecycle**

```yaml
artifacts:
  proposal    → (无依赖)
  product-spec → (依赖 proposal)     ← 需人工审批
  design      → (依赖 product-spec)  ← 需人工审批
  tasks       → (依赖 design)

apply:
  requires: [tasks]
  tracks: tasks.md                   ← 需人工验收
```

**设计决策**：
- 人工审批关卡由指令层控制，不作为 schema 中的独立工件
- 审批状态记录在文档中（`<!-- FORGE_GATE:xxx:APPROVED:日期 -->`），而非外部状态
- 这保证了审批状态能随文档存活，支持会话恢复

### 第六层：基础设施层

**编码规则**（`.claude/rules/`）：

| 规则 | 作用域 |
|------|--------|
| `first-principles.md` | 所有决策场景 |
| `architecture.md` | 项目结构、分层、错误处理 |
| `frontend.md` | UI/UX 质量、响应式、无障碍 |
| `backend.md` | API 设计、安全、数据库、日志 |

**技术栈预设**（`stacks/*.yaml`）：

每个预设定义：
- 前后端框架、语言、工具链
- 初始化命令（`init_commands`）
- 编码规范（`conventions`）

## 关键流程

### 产品创建流程（/genesis）

```
用户输入创意
    │
    ▼
[第一阶段] 理解创意
    │ 通过提问明确需求
    ▼
[第二阶段] 产品设计
    │ product-designer 智能体
    │ 产出 proposal.md + specs/product-spec.md
    ▼
┌──────────────┐
│ 设计评审 ✋   │ ← 人工审批关卡
│ 批准/修改/拒绝│
└──────┬───────┘
       │ 批准后插入 <!-- FORGE_GATE:DESIGN_REVIEW:APPROVED:日期 -->
       ▼
[第三阶段] 技术架构
    │ tech-architect 智能体
    │ 产出 design.md
    ▼
┌──────────────┐
│ 技术评审 ✋   │ ← 人工审批关卡
│ 批准/修改/拒绝│
└──────┬───────┘
       │ 批准后插入 <!-- FORGE_GATE:TECH_REVIEW:APPROVED:日期 -->
       ▼
[第四阶段] 项目脚手架
    │ 按技术栈配置初始化前后端
    ▼
[第五阶段] 生成任务清单
    │ 产出 tasks.md
    ▼
[第六阶段] 实现
    │ backend-dev → frontend-dev → code-reviewer
    │ 每完成一个任务标记 [x]
    ▼
┌──────────────┐
│ 验收 ✋       │ ← 人工审批关卡
│ 接受/Bug/修改 │
└──────┬───────┘
       │ 接受后插入 <!-- FORGE_GATE:ACCEPTANCE:APPROVED:日期 -->
       ▼
[第八阶段] 交付
    │ openspec archive → git commit
    ▼
  完成
```

### 会话恢复流程（/recover）

```
新会话开始
    │
    ▼
读取 git 状态 ──────────── 当前分支、最近提交
    │
    ▼
读取 OpenSpec 状态 ────── npx openspec list --changes --json
    │                     npx openspec status --change <名> --json
    ▼
检查审批标记 ──────────── grep FORGE_GATE 文档
    │
    ▼
检查任务进度 ──────────── npx openspec instructions apply --json
    │
    ▼
生成恢复报告 ──────────── 展示给用户确认
    │
    ▼
从中断处继续
```

### 审批标记机制

```
                     指令层                          钩子层
                       │                               │
  /design-review ──────┤                               │
  用户说"批准"         │                               │
        │              │                               │
        ▼              │                               │
  在 proposal.md       │                               │
  中插入标记 ──────────┤                               │
  <!-- FORGE_GATE:     │                               │
  DESIGN_REVIEW:       │                               │
  APPROVED:日期 -->    │                               │
                       │                               │
                       │      git commit 时            │
                       │           │                   │
                       │           ▼                   │
                       │    human-gate.js              │
                       │    读取 proposal.md ──────────┤
                       │    检查标记是否存在            │
                       │           │                   │
                       │     ┌─────┴─────┐             │
                       │     │           │             │
                       │   有标记      无标记           │
                       │     │           │             │
                       │   放行     exit 2 阻塞        │
```

## 安装架构

### 远程安装流程

```
curl ... | bash
    │
    ▼
install.sh 检测来源
    │
    ├── 本地（脚本旁有 CLAUDE.md + commands/）
    │   └── 直接 cp -r
    │
    └── 远程（通过 curl 管道执行）
        │
        ▼
    下载 GitHub archive tar.gz
        │
        ▼
    解压到临时目录
        │
        ▼
    复制到项目的 forge/ 目录
```

### 安装产物

```
install.sh 执行后在用户项目中创建：

[1] forge/           ← 框架文件副本（commands、agents、skills、hooks、stacks）
[2] openspec/        ← OpenSpec 初始化 + forge-lifecycle schema
[3] .claude/rules/   ← 编码规则
[4] .claude/settings.json ← 钩子注册
[5] contracts/api/   ← API 契约目录
[6] CLAUDE.md        ← 项目级说明
```

**设计决策**：安装时**复制**而非 symlink。保证用户项目独立于 Forge 源仓库，不存在路径依赖。

## 数据流

### 文档是唯一真实信息源

```
                    ┌─────────────┐
                    │  OpenSpec    │
                    │  文档        │ ← 唯一在会话丢失后存续的状态
                    └──────┬──────┘
                           │
            ┌──────────────┼──────────────┐
            │              │              │
            ▼              ▼              ▼
      工件状态         任务进度        审批状态
   proposal.md       tasks.md     FORGE_GATE 标记
   design.md         [x] / [ ]    APPROVED:日期
   specs/*.md
```

### 前后端分离的数据契约

```
   frontend/                contracts/api/               backend/
       │                         │                          │
       │    ┌────────────────────┤                          │
       │    │   API 契约          │                          │
       │    │  (OpenAPI 3.1)     │                          │
       │    │                    │                          │
       ▼    ▼                    ▼                          ▼
  前端按契约调用            双方共同遵守              后端按契约实现
  API 客户端               请求/响应格式             路由 + 控制器
       │                                                    │
       └──────────── HTTP(S) ──────────────────────────────┘
```

## 扩展点

### 添加新的技术栈预设

在 `stacks/` 中创建新的 YAML 文件，遵循已有预设的格式。

### 添加新的领域知识

在 `skills/` 中创建新目录和 `SKILL.md` 文件。

### 添加新的智能体

在 `agents/` 中创建新的 `.md` 文件，包含 YAML frontmatter（name、description、tools、model）。

### 添加新的指令

在 `commands/` 中创建新的 `.md` 文件，包含 YAML frontmatter（name、description、allowed_tools）。

### 自定义 OpenSpec Schema

在 `schemas/` 中创建新目录，定义 `schema.yaml` 和 `templates/`。修改 `openspec/config.yaml` 引用新 schema。
