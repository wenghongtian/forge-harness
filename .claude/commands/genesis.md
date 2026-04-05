---
name: genesis
description: "产品从 0 到 1。从创意到可运行软件的完整工作流。"
allowed_tools: ["Read", "Write", "Edit", "Bash", "Grep", "Glob", "Agent", "AskUserQuestion"]
---

# /genesis — 产品从零到一

当用户有一个产品创意并想从零开始构建时，使用此技能。

## 前提条件
- Forge 框架已安装（通过 `install.sh` 完成，OpenSpec 已初始化）
- 用户有创意或问题描述（可以很模糊）

## 前提检查
在开始之前，先验证 Forge 已正确安装：
```bash
# 检查 OpenSpec 是否已初始化
test -d openspec && echo "✓ OpenSpec 已就绪" || echo "✗ 请先运行 install.sh 安装框架"
# 检查 schema 是否已安装
test -f openspec/schemas/forge-lifecycle/schema.yaml && echo "✓ forge-lifecycle schema 已就绪" || echo "✗ schema 缺失"
```

如果检查不通过，提示用户运行安装脚本：
`curl -fsSL https://raw.githubusercontent.com/wenghongtian/forge-harness/main/install.sh | bash -s -- --stack <技术栈名>`

---

## 第一阶段：理解创意

**目标**：获得足够的清晰度来设计产品规格。

询问用户以下问题（使用 AskUserQuestion）：
1. "你想解决什么问题？谁会遇到这个问题？"
2. "成功是什么样子的？用户会获得什么收益？"
3. "你对技术栈有偏好吗？（可选：react-node、vue-go、nextjs-python、react-native-node、或自定义）"

如果描述模糊，进一步探问：
- "能描述一个典型用户的使用场景吗？"
- "这个产品最重要的一件事是什么？"
- "你试过哪些现有方案？为什么不满意？"

---

## 第二阶段：产品设计（人工审批关卡）

**目标**：创建用户批准的产品规格。

1. 创建新变更（OpenSpec 已在安装时初始化）：
```bash
pnpm exec openspec new change genesis-<产品名> --schema forge-lifecycle
```

2. 查看当前工件状态和指引：
```bash
pnpm exec openspec status --change genesis-<产品名> --json
pnpm exec openspec instructions proposal --change genesis-<产品名>
```

3. 委托 **product-designer** 智能体：
   - 传入用户的创意描述和发现阶段的回答
   - 智能体按照 OpenSpec 指引产出 `proposal.md`
   - 再获取下一个工件的指引：
```bash
pnpm exec openspec instructions product-spec --change genesis-<产品名>
```
   - 智能体产出 `specs/product-spec.md`

4. **人工审批关卡 — 设计评审**：
   向用户展示产品规格并询问：

   ```
   产品规格已完成，请审阅：

   产品愿景：[摘要]
   目标用户：[用户画像]
   核心功能：
   - [功能 1]
   - [功能 2]
   - [功能 3]

   完整规格位于：openspec/changes/genesis-<产品名>/specs/product-spec.md

   你批准这个产品设计吗？（批准 / 修改 / 讨论）
   ```

   - 如果"修改"：询问修改内容，更新规格，重新展示
   - 如果"讨论"：进行对话，然后更新并重新展示
   - 如果"批准"：在 proposal.md 中插入 `<!-- FORGE_GATE:DESIGN_REVIEW:APPROVED:YYYY-MM-DD -->`（用实际日期），进入第三阶段
   - **未经明确批准不得继续**

---

## 第三阶段：技术架构（人工审批关卡）

**目标**：基于批准的产品规格设计技术架构。

1. 获取设计工件的指引：
```bash
pnpm exec openspec instructions design --change genesis-<产品名>
```

2. 委托 **tech-architect** 智能体：
   - 传入批准的产品规格和技术栈配置
   - 智能体产出 `design.md`（包含架构、API 契约、数据库模型、组件设计）

3. **人工审批关卡 — 技术评审**：
   向用户展示架构并询问：

   ```
   技术架构已完成，请审阅：

   架构：[前端] + [后端]，数据库 [数据库]
   API 端点：[数量] 个端点，覆盖 [数量] 个资源
   数据库：[数量] 个表
   前端：[数量] 个页面，[数量] 个核心组件

   完整设计位于：openspec/changes/genesis-<产品名>/design.md

   你批准这个技术设计吗？（批准 / 修改 / 讨论）
   ```

   - 相同审批流程
   - 批准后在 design.md 中插入 `<!-- FORGE_GATE:TECH_REVIEW:APPROVED:YYYY-MM-DD -->`（用实际日期）
   - **未经明确批准不得继续**

---

## 第四阶段：项目脚手架

**目标**：基于选定技术栈搭建项目结构。

1. 读取技术栈配置：
```bash
cat .claude/stacks/<技术栈名>.yaml
```

2. 按照技术栈配置的 `init_commands` 初始化前后端项目

3. 验证脚手架：
```bash
cd frontend && npm install && npm run dev  # 应无错启动
cd backend && npm install && npm run dev   # 应无错启动
```

---

## 第五阶段：生成任务清单

**目标**：创建有序、可追踪的实现任务。

获取任务工件的指引并生成：
```bash
pnpm exec openspec instructions tasks --change genesis-<产品名>
```

按照模板格式在 `tasks.md` 中列出所有任务。

---

## 第六阶段：实现

**目标**：按任务清单构建产品。

使用 OpenSpec 的 apply 指引获取当前进度：
```bash
pnpm exec openspec instructions apply --change genesis-<产品名> --json
```

实现顺序：
1. **先后端** — 数据库、模型、服务、控制器、路由
2. **API 契约验证** — 确认端点与契约一致
3. **后前端** — 页面、组件、API 集成、打磨

每完成一个任务，在 `tasks.md` 中标记 `[x]`，然后再次查询进度：
```bash
pnpm exec openspec instructions apply --change genesis-<产品名> --json
```

---

## 第七阶段：验收（人工审批关卡）

**目标**：用户验证产品是否符合预期。

1. 委托 **qa-engineer** 智能体进行自动验证
2. 启动应用供用户测试
3. **人工审批关卡 — 验收**：

   ```
   产品已准备好供你审阅！

   前端：http://localhost:5173
   后端：http://localhost:3000

   QA 报告：[验证结果摘要]

   请测试以下功能：
   - [ ] [核心功能 1]
   - [ ] [核心功能 2]
   - [ ] [核心功能 3]

   你接受这个实现吗？（接受 / 修改 / 报告 Bug）
   ```

   - **未经明确接受不得继续**

---

## 第八阶段：交付

1. 运行最终测试
2. 归档 OpenSpec 变更：
```bash
pnpm exec openspec archive genesis-<产品名>
```

3. 提交代码：
```bash
git add -A
git commit -m "feat: 初始产品实现 — <产品名>"
```

4. 向用户报告完成状态
