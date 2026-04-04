#!/bin/bash
set -euo pipefail

# ============================================================================
# Forge — 安装框架
#
# 远程安装（从 GitHub）：
#   curl -fsSL https://raw.githubusercontent.com/wenghongtian/forge-harness/main/install.sh | bash
#   curl -fsSL https://raw.githubusercontent.com/wenghongtian/forge-harness/main/install.sh | bash -s -- --stack react-node
#
# 本地安装（已 clone 仓库）：
#   cd my-project && /path/to/forge/install.sh --stack react-node
#
# 在当前目录安装 Forge 框架：
# 1. 从 GitHub 下载（或从本地复制）框架文件
# 2. 初始化 OpenSpec（使用 forge-lifecycle schema）
# 3. 安装 .claude/rules 和 hooks 配置
# 4. 创建必要的目录结构
# ============================================================================

# ── 配置 ─────────────────────────────────────────────────

FORGE_REPO="wenghongtian/forge-harness"        # GitHub 仓库（可自定义）
FORGE_BRANCH="main"                      # 默认分支

# ── 解析参数 ─────────────────────────────────────────────

STACK_NAME=""
while [[ $# -gt 0 ]]; do
  case $1 in
    --stack)
      STACK_NAME="$2"
      shift 2
      ;;
    --repo)
      FORGE_REPO="$2"
      shift 2
      ;;
    --branch)
      FORGE_BRANCH="$2"
      shift 2
      ;;
    -h|--help)
      echo "用法：$0 [选项]"
      echo ""
      echo "选项："
      echo "  --stack <名称>     技术栈预设（react-node, vue-go, nextjs-python, react-native-node）"
      echo "  --repo <owner/repo>  GitHub 仓库（默认：$FORGE_REPO）"
      echo "  --branch <分支>    GitHub 分支（默认：$FORGE_BRANCH）"
      echo ""
      echo "远程安装："
      echo "  curl -fsSL https://raw.githubusercontent.com/$FORGE_REPO/$FORGE_BRANCH/install.sh | bash"
      echo "  curl -fsSL ... | bash -s -- --stack react-node"
      echo ""
      echo "本地安装："
      echo "  cd my-project && /path/to/forge/install.sh --stack react-node"
      exit 0
      ;;
    *)
      echo "未知参数：$1（使用 --help 查看帮助）"
      exit 1
      ;;
  esac
done

PROJECT_DIR="$(pwd)"
PROJECT_NAME=$(basename "$PROJECT_DIR")

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Forge — 安装框架"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  项目：$PROJECT_NAME"
echo "  路径：$PROJECT_DIR"
[ -n "$STACK_NAME" ] && echo "  技术栈：$STACK_NAME"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# ── 判断安装来源：本地 or 远程 ───────────────────────────

FORGE_SOURCE=""
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" 2>/dev/null && pwd || echo "")"

if [ -n "$SCRIPT_DIR" ] && [ -f "$SCRIPT_DIR/CLAUDE.md" ] && [ -d "$SCRIPT_DIR/.claude/commands" ]; then
  # 本地模式：install.sh 在 forge 仓库中运行
  FORGE_SOURCE="local"
  FORGE_DIR="$SCRIPT_DIR"
  echo "[来源] 本地安装：$FORGE_DIR"
else
  # 远程模式：从 GitHub 下载
  FORGE_SOURCE="remote"
  echo "[来源] 远程安装：github.com/$FORGE_REPO@$FORGE_BRANCH"
fi

# ── 下载函数 ─────────────────────────────────────────────

download_forge() {
  local tmpdir
  tmpdir=$(mktemp -d)
  trap "rm -rf '$tmpdir'" EXIT

  echo "  正在从 GitHub 下载..."

  local archive_url="https://github.com/$FORGE_REPO/archive/refs/heads/$FORGE_BRANCH.tar.gz"

  if command -v curl &>/dev/null; then
    curl -fsSL "$archive_url" -o "$tmpdir/forge.tar.gz"
  elif command -v wget &>/dev/null; then
    wget -q "$archive_url" -O "$tmpdir/forge.tar.gz"
  else
    echo "错误：需要 curl 或 wget 来下载。"
    exit 1
  fi

  # 解压
  tar -xzf "$tmpdir/forge.tar.gz" -C "$tmpdir"

  # GitHub archive 解压后的目录名是 repo-branch
  local repo_name
  repo_name=$(echo "$FORGE_REPO" | cut -d'/' -f2)
  local extracted_dir="$tmpdir/${repo_name}-${FORGE_BRANCH}"

  # 如果框架文件在子目录 forge/ 中
  if [ -d "$extracted_dir/forge" ]; then
    FORGE_DIR="$extracted_dir/forge"
  elif [ -f "$extracted_dir/CLAUDE.md" ] && [ -d "$extracted_dir/.claude/commands" ]; then
    FORGE_DIR="$extracted_dir"
  else
    echo "错误：下载的仓库中未找到 Forge 框架文件。"
    echo "  检查仓库 $FORGE_REPO 是否包含 commands/、agents/ 等目录。"
    exit 1
  fi

  echo "  下载完成。"
}

# 如果是远程安装，先下载
if [ "$FORGE_SOURCE" = "remote" ]; then
  download_forge
fi

# ── 第一步：安装框架文件 ─────────────────────────────────
#
# Claude Code 的约定：
#   .claude/commands/*.md  → 用户可用 /指令名 调用
#   .claude/skills/*/SKILL.md → 领域知识，智能体可引用
#   forge/ → 框架支撑文件（agents、hooks、stacks、schemas）

echo ""
echo "[1/5] 安装框架文件..."

# 指令 → .claude/commands/（Claude Code 斜杠指令）
mkdir -p .claude/commands
if ls "$FORGE_DIR/.claude/commands/"*.md &>/dev/null; then
  for cmd in "$FORGE_DIR/.claude/commands/"*.md; do
    cp "$cmd" .claude/commands/
  done
fi
echo "  已安装指令到 .claude/commands/"

# 技能 → .claude/skills/（Claude Code 领域知识）
mkdir -p .claude/skills
if [ -d "$FORGE_DIR/.claude/skills" ]; then
  for skill_dir in "$FORGE_DIR/.claude/skills/"*/; do
    skill_name=$(basename "$skill_dir")
    mkdir -p ".claude/skills/$skill_name"
    cp -r "$skill_dir"* ".claude/skills/$skill_name/"
  done
fi
echo "  已安装技能到 .claude/skills/"

# 支撑文件 → forge/（agents、hooks、stacks、schemas）
if [ ! -d "forge" ]; then
  mkdir -p forge/{agents,hooks,stacks,schemas}
  cp -r "$FORGE_DIR/agents/"* forge/agents/
  cp -r "$FORGE_DIR/hooks/"* forge/hooks/
  cp -r "$FORGE_DIR/stacks/"* forge/stacks/
  [ -d "$FORGE_DIR/schemas" ] && cp -r "$FORGE_DIR/schemas/"* forge/schemas/
  [ -f "$FORGE_DIR/CLAUDE.md" ] && cp "$FORGE_DIR/CLAUDE.md" forge/CLAUDE.md
  echo "  已安装支撑文件到 forge/"
else
  echo "  forge/ 已存在，跳过。"
fi

# ── 第二步：初始化 OpenSpec ──────────────────────────────

echo "[2/5] 初始化 OpenSpec..."

if [ -d "openspec" ]; then
  echo "  openspec/ 已存在，跳过初始化。"
else
  if command -v npx &>/dev/null; then
    npx openspec init --tools claude --profile core 2>/dev/null || {
      echo "  OpenSpec CLI 不可用，手动创建结构..."
      mkdir -p openspec/specs
      mkdir -p openspec/changes/archive
    }
  else
    echo "  npx 不可用，手动创建 OpenSpec 结构..."
    mkdir -p openspec/specs
    mkdir -p openspec/changes/archive
  fi
fi

# ── 第三步：安装 forge-lifecycle schema ──────────────────

echo "[3/5] 安装 forge-lifecycle schema..."

mkdir -p openspec/schemas/forge-lifecycle/templates
if [ -d "$FORGE_DIR/schemas/forge-lifecycle" ]; then
  cp -r "$FORGE_DIR/schemas/forge-lifecycle/"* openspec/schemas/forge-lifecycle/
else
  cp -r forge/schemas/forge-lifecycle/* openspec/schemas/forge-lifecycle/ 2>/dev/null || true
fi
echo "  已安装到 openspec/schemas/forge-lifecycle/"

# 创建 OpenSpec 配置
STACK_CONTEXT=""
if [ -n "$STACK_NAME" ]; then
  if [ -f "forge/stacks/${STACK_NAME}.yaml" ]; then
    STACK_CONTEXT="技术栈：$STACK_NAME（详见 forge/stacks/${STACK_NAME}.yaml）"
  else
    echo "  警告：技术栈 '$STACK_NAME' 未找到，忽略。"
    STACK_NAME=""
  fi
fi

if [ ! -f "openspec/config.yaml" ]; then
  cat > openspec/config.yaml << EOF
schema: forge-lifecycle
context: |
  项目：$PROJECT_NAME
  架构模式：前后端分离
  ${STACK_CONTEXT}
rules: {}
EOF
  echo "  已创建 openspec/config.yaml"
else
  echo "  openspec/config.yaml 已存在，跳过。"
fi

# ── 第四步：安装 .claude 配置（rules + hooks）────────────

echo "[4/5] 安装 Claude Code 规则和钩子..."

# 复制规则
mkdir -p .claude/rules
if ls "$FORGE_DIR/.claude/rules/"*.md &>/dev/null; then
  for rule in "$FORGE_DIR/.claude/rules/"*.md; do
    cp "$rule" .claude/rules/
  done
fi
echo "  已安装规则：$(ls .claude/rules/*.md 2>/dev/null | wc -l | tr -d ' ') 个"

# 安装 settings.json（钩子配置）
if [ -f ".claude/settings.json" ]; then
  echo "  .claude/settings.json 已存在。"
  echo "  请手动将以下钩子配置合并进去（详见 forge/hooks/）。"
else
  cat > .claude/settings.json << 'SETTINGS_EOF'
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Bash",
        "command": "node forge/hooks/human-gate.js",
        "description": "在审批关卡阶段，未经批准时阻塞提交"
      },
      {
        "matcher": "Bash",
        "command": "node forge/hooks/branch-doc-check.js",
        "description": "确保功能分支有对应的 OpenSpec 变更文件夹"
      },
      {
        "matcher": "Bash",
        "command": "node forge/hooks/pre-commit-quality.js",
        "description": "git commit 前的质量检查"
      }
    ],
    "PostToolUse": [
      {
        "matcher": "Edit|Write",
        "command": "node forge/hooks/doc-sync.js",
        "description": "代码变更缺少规格追踪时发出警告"
      }
    ]
  }
}
SETTINGS_EOF
  echo "  已安装 .claude/settings.json（含钩子配置）"
fi

# ── 第五步：创建项目目录结构 ─────────────────────────────

echo "[5/5] 创建项目目录结构..."

mkdir -p contracts/api
mkdir -p docs

# 创建项目 CLAUDE.md
if [ ! -f "CLAUDE.md" ]; then
  cat > CLAUDE.md << CLAUDE_EOF
# 项目说明

## 项目信息
- 名称：$PROJECT_NAME
${STACK_NAME:+- 技术栈：$STACK_NAME}
- 初始化时间：$(date +%Y-%m-%d)

## Forge 框架
本项目使用 Forge 工程框架。详见 forge/ 目录。

## 指令
- \`/genesis\` — 从零构建产品
- \`/iterate\` — 添加或修改功能
- \`/hotfix\` — 修复 Bug
- \`/recover\` — 从文档恢复会话状态

## 技术栈
详见 \`openspec/config.yaml\` 中的配置。

## 测试
\`\`\`bash
cd frontend && npm test    # 前端测试
cd backend && npm test     # 后端测试
\`\`\`
CLAUDE_EOF
  echo "  已创建 CLAUDE.md"
else
  echo "  CLAUDE.md 已存在，跳过。"
fi

# 创建 .gitignore（如果不存在）
if [ ! -f ".gitignore" ]; then
  cat > .gitignore << 'GITIGNORE_EOF'
node_modules/
.env
.env.local
.DS_Store
dist/
build/
.next/
*.log
coverage/
.prisma/
__pycache__/
*.pyc
.venv/
GITIGNORE_EOF
  echo "  已创建 .gitignore"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Forge 安装完成！"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "  已安装："
echo "  ✓ 斜杠指令（.claude/commands/）— /genesis, /iterate, /hotfix 等"
echo "  ✓ 领域知识（.claude/skills/）— 产品设计、UI/UX、API、测试等"
echo "  ✓ 编码规则（.claude/rules/）— 架构、前端、后端、第一性原理"
echo "  ✓ 钩子配置（.claude/settings.json）— 审批阻塞、文档同步等"
echo "  ✓ 支撑文件（forge/）— 智能体、钩子脚本、技术栈预设"
echo "  ✓ OpenSpec + forge-lifecycle schema"
echo "  ✓ 项目目录结构（contracts/、docs/）"
echo ""
echo "  后续步骤："
echo "  在 Claude Code 中输入 /genesis 从零构建产品"
echo "  输入 /iterate 添加功能"
echo "  输入 /hotfix 修复 Bug"
echo ""
