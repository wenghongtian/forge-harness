# Forge — 从创意到产品落地

Forge 是一个面向 Claude Code 的工程框架（harness），支持软件开发的完整生命周期。它融合了 everything-claude-code（智能体编排）、gstack（工作流技能）和 OpenSpec（规格驱动的文档追踪）的最佳实践。

## 核心理念

**第一性原理思维** — 每一个设计和架构决策都从根本事实出发，而非类比或惯例。在确定方案之前，连续追问五次"为什么"。构建用户真正需要的东西，而非看起来炫酷的东西。

**规格驱动开发** — 所有工作通过 OpenSpec 追踪。没有对应规格文档的代码变更不允许提交。文档是唯一能在会话丢失后存续的真实信息源。

**人机协作** — 产品设计、技术架构和功能验收必须经过人工明确审批。AI 负责提案，人类负责决策。

**默认精美** — 产品必须视觉精良，符合真实用户的使用习惯。不允许出现占位 UI、不允许使用通用模板。带着同理心做设计。

---

## 架构：前后端分离

所有项目采用前后端分离架构：

```
project-root/
├── openspec/                  # 规格文档（唯一真实信息源）
│   ├── specs/                 # 当前系统规格
│   ├── changes/               # 进行中的变更
│   └── config.yaml            # OpenSpec 配置
├── frontend/                  # 前端应用
│   ├── src/
│   ├── public/
│   └── package.json
├── backend/                   # 后端应用
│   ├── src/
│   └── ...
├── contracts/                 # API 契约（前后端共享）
│   └── api/
├── docs/                      # 补充文档
└── CLAUDE.md                  # 项目级指令
```

## 技术栈配置

技术栈定义在 `stacks/*.yaml` 中。项目初始化时选定技术栈，存储在 `openspec/config.yaml` 的 `context` 字段中。

### 可用预设
- `react-node` — React + TypeScript / Node.js + Express + PostgreSQL
- `vue-go` — Vue 3 + TypeScript / Go + Gin + PostgreSQL
- `nextjs-python` — Next.js 14+ / Python + FastAPI + PostgreSQL
- `react-native-node` — React Native + Expo / Node.js + Express + PostgreSQL
- `custom` — 自定义技术栈（使用 `custom.yaml.template`）

### 技术栈文件结构
```yaml
name: 技术栈名称
frontend:
  framework: React
  language: TypeScript
  build_tool: Vite
  ui_library: Tailwind CSS + shadcn/ui
  state_management: Zustand
  testing: Vitest + Testing Library
backend:
  framework: Express
  language: TypeScript
  runtime: Node.js
  database: PostgreSQL
  orm: Prisma
  testing: Vitest
  api_style: RESTful
shared:
  api_contract: OpenAPI 3.1
  monorepo: false
  package_manager: pnpm
```

生成代码时，务必先读取当前技术栈配置，并严格遵循其规范。

---

## 工作流生命周期

### 阶段一：愿景与产品设计（人工审批关卡）
1. 用户描述创意（可以是模糊的）
2. **product-designer** 智能体分析并产出产品愿景文档
3. `/design-review` 技能 — **必须人工审批**
   - 用户审阅产品规格、用户故事、交互描述
   - 必须明确批准后才能继续

### 阶段二：技术架构设计（人工审批关卡）
1. **tech-architect** 智能体基于批准的产品规格产出技术设计
2. 定义 API 契约、数据库模型、组件架构
3. `/tech-review` 技能 — **必须人工审批**
   - 用户审阅架构决策和取舍
   - 必须明确批准后才能继续

### 阶段三：实现
1. OpenSpec 根据批准的规格生成任务清单
2. **frontend-dev** 和 **backend-dev** 智能体实现功能
3. **code-reviewer** 智能体对每个重要变更进行代码审查
4. 所有变更通过 OpenSpec 变更文档追踪

### 阶段四：验收（人工审批关卡）
1. **qa-engineer** 智能体根据规格验证实现
2. `/accept` 技能 — **必须人工审批**
   - 用户测试功能，对照验收标准检查
   - 必须明确批准后才能标记完成

### 阶段五：归档与交付
1. OpenSpec 归档已完成的变更，合并规格
2. 代码提交，创建 PR

---

## 封装指令

### `/genesis` — 产品从 0 到 1
从一个创意创建完整产品的全流程：
1. 产品愿景与规格设计 → 人工审阅
2. 技术架构设计 → 人工审阅
3. 基于选定技术栈搭建项目脚手架
4. 实现（后端 → 契约 → 前端）
5. 功能验收 → 人工审阅
6. 交付

### `/iterate` — 产品功能迭代
在现有产品上添加或增强功能：
1. 阅读现有规格，理解当前状态
2. 设计变更 → 人工审阅
3. 增量技术设计 → 人工审阅
4. 通过 OpenSpec 变更追踪实现
5. 验收 → 人工审阅
6. 归档变更，合并规格

### `/hotfix` — 线上 Bug 修复
修复 Bug 的快速通道：
1. 复现并记录 Bug
2. 根因分析
3. 修复实现（最小化、精准修改）
4. 回归测试
5. 快速验收 → 人工审阅
6. 带紧急标记交付

### `/recover` — 会话恢复
当会话丢失时，从 OpenSpec 文档恢复任务状态：
1. 读取 `openspec/` 目录，查找活跃变更
2. 检查任务完成状态（复选框状态）
3. 读取 git 日志，查看最近提交
4. 重建当前进度和后续步骤
5. 从中断处继续工作

---

## 文档追踪（OpenSpec 集成）

所有变更必须通过 OpenSpec 追踪：

### 创建变更
```bash
# OpenSpec 创建包含工件的变更文件夹
openspec new <变更名称>
```

### 变更工件流程
1. `proposal.md` — 为什么要做这个变更（关联产品规格）
2. `specs/*.md` — 变更内容（增量规格：新增/修改/删除）
3. `design.md` — 如何实现（技术方案）
4. `tasks.md` — 实现清单，使用 `[ ]` / `[x]` 追踪

### 会话恢复协议
当会话丢失时，恢复流程读取：
1. `openspec/changes/` — 查找活跃（未归档）的变更
2. `tasks.md` — 检查哪些任务是 `[x]` 已完成，哪些是 `[ ]` 待完成
3. `git log` — 验证哪些代码已实际提交
4. `specs/` — 理解变更的目标
5. 从第一个未完成的任务继续

### 多分支文档管理

**分支策略：**
- 每个功能分支有自己的 `openspec/changes/<功能>/` 文件夹
- 主分支的规格（`openspec/specs/`）是权威信息源
- 功能分支只在自己的变更文件夹内增加/修改

**合并协议：**
1. 如果两个分支修改了同一规格领域：
   - 先归档先合并分支的变更（将增量应用到规格）
   - 变基第二个分支，基于新基线更新其增量规格
2. 合并后运行 `openspec archive` 将增量应用到主规格

**冲突解决规则：**
- 规格冲突：后合并的变更必须基于已合并的基线重写增量
- 任务冲突：每个分支拥有自己的 tasks.md，不会冲突
- 提案冲突：独立的，不会冲突
- 设计冲突：如果涉及同一组件，需要人工审查

---

## 指令（commands/）

用户直接调用的斜杠指令，定义完整的工作流编排：

| 指令 | 用途 |
|------|------|
| `/genesis` | 产品从 0 到 1，完整创建流程 |
| `/iterate` | 在现有产品上迭代功能 |
| `/hotfix` | 线上 Bug 快速修复 |
| `/recover` | 从 OpenSpec 文档恢复会话状态 |
| `/design-review` | 人工审批关卡：产品设计评审 |
| `/tech-review` | 人工审批关卡：技术架构评审 |
| `/accept` | 人工审批关卡：功能验收 |

---

## 技能（skills/）

可复用的领域知识，供智能体和指令引用：

| 技能 | 用途 |
|------|------|
| product-design | 产品设计方法论（需求分析、用户故事、优先级判断） |
| ui-ux | UI/UX 设计标准（视觉规范、交互模式、无障碍） |
| api-design | RESTful API 设计规范（统一格式、状态码、认证） |
| testing-strategy | 测试策略（测试金字塔、命名规范、数据管理） |
| openspec-workflow | OpenSpec 工作流参考（常用命令、工件流程） |

---

## 智能体（agents/）

| 智能体 | 角色 | 工具 | 模型 |
|--------|------|------|------|
| product-designer | 产品愿景、用户故事、交互流程 | Read, Write, Grep, Glob, WebSearch | opus |
| tech-architect | 架构设计、API 设计、数据库模型 | Read, Write, Grep, Glob, Bash | opus |
| frontend-dev | 前端实现 | Read, Write, Edit, Bash, Grep, Glob | sonnet |
| backend-dev | 后端实现 | Read, Write, Edit, Bash, Grep, Glob | sonnet |
| code-reviewer | 代码审查与质量把控 | Read, Grep, Glob | opus |
| qa-engineer | 测试与验证 | Read, Bash, Grep, Glob | sonnet |
| doc-keeper | 文档维护 | Read, Write, Edit, Grep, Glob | sonnet |

---

## 钩子

| 钩子 | 类型 | 触发器 | 用途 |
|------|------|--------|------|
| doc-sync | PostToolUse | Edit, Write | 代码变更缺少规格追踪时发出警告 |
| branch-doc-check | PreToolUse | Bash (git checkout/switch) | 确保分支有对应的 OpenSpec 变更文件夹 |
| human-gate | PreToolUse | Bash (git commit) | 缺少审批标记时阻塞提交（exit 2） |
| pre-commit-quality | PreToolUse | Bash (git commit) | 提交前进行代码检查、类型检查、测试 |

---

## 设计原则

### 产品设计（第一性原理）
1. **从用户痛点出发** — 这到底解决了什么真实问题？
2. **最简交互路径** — 能够传递价值的最简流程是什么？
3. **渐进式披露** — 只在需要时展示复杂性
4. **一致性优于新奇** — 遵循平台规范，除非有充分理由不这样做

### UI/UX 标准
- 使用技术栈中指定的 UI 库（如 shadcn/ui）
- 遵循间距系统：4px 基础单元（4, 8, 12, 16, 24, 32, 48, 64）
- 字体比例：使用框架默认字体 + 1 个展示字体
- 颜色：语义化调色板（primary, secondary, destructive, muted）— 不使用魔法十六进制值
- 响应式：移动端优先，断点 sm(640) md(768) lg(1024) xl(1280)
- 动画：微妙、有目的，UI 反馈不超过 300ms
- 无障碍：最低 WCAG 2.1 AA — 合适的对比度、焦点环、aria 标签
- 深色模式：如果 UI 库支持，从第一天起就支持

### 架构设计（第一性原理）
1. **分离变化与不变** — 模块之间有清晰的边界
2. **数据单向流动** — 可预测的状态管理
3. **显式失败** — 不允许静默错误，不允许吞掉异常
4. **API 即契约** — 前后端约定接口，各自独立实现
5. **无状态服务** — 后端服务不应持有会话状态

### 代码质量
- TypeScript 中不使用 `any` 类型（使用正确的泛型或 `unknown`）
- 生产代码中不使用 `console.log`（使用结构化日志）
- 每个 API 端点都有输入验证
- 每个数据库查询都使用参数化输入
- 错误响应遵循统一格式：`{ error: { code, message, details? } }`

---

## 快速参考

```bash
# ── 安装 ──────────────────────────────
# 远程安装（从 GitHub）：
curl -fsSL https://raw.githubusercontent.com/wenghongtian/forge-harness/main/install.sh | bash
curl -fsSL ... | bash -s -- --stack react-node

# 本地安装（已 clone）：
cd <项目目录> && /path/to/forge-harness/install.sh --stack <技术栈名称>

# 新项目快速初始化：
./scripts/init-project.sh <项目名称> <技术栈名称>

# ── 工作流 ────────────────────────────
# 从零开始创建产品
# 使用 /genesis 技能

# 添加功能
# 使用 /iterate 技能

# 修复 Bug
# 使用 /hotfix 技能

# 恢复丢失的会话
# 使用 /recover 技能

# ── 工具 ──────────────────────────────
# 查看技术栈配置
./scripts/stack-setup.sh <技术栈名称>
```
