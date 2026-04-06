#!/bin/bash
set -euo pipefail

# ============================================================================
# Forge — 安装框架
#
# 远程安装：
#   curl -fsSL https://raw.githubusercontent.com/wenghongtian/forge-harness/main/install.sh | bash
#   curl -fsSL https://raw.githubusercontent.com/wenghongtian/forge-harness/main/install.sh | bash -s -- --stack react-node
#
# 本地安装（已 clone）：
#   cd my-project && /path/to/forge-harness/install.sh --stack react-node
#
# 安装后所有文件在 .claude/ 和 openspec/ 下，无额外目录。
# 在 Claude Code 中直接输入 /genesis 即可使用。
# ============================================================================

FORGE_REPO="wenghongtian/forge-harness"
FORGE_BRANCH="main"

# ── 解析参数 ─────────────────────────────────────────────

STACK_NAME=""
while [[ $# -gt 0 ]]; do
  case $1 in
    --stack)  STACK_NAME="$2"; shift 2 ;;
    --repo)   FORGE_REPO="$2"; shift 2 ;;
    --branch) FORGE_BRANCH="$2"; shift 2 ;;
    -h|--help)
      echo "用法：$0 [选项]"
      echo ""
      echo "选项："
      echo "  --stack <名称>       技术栈（react-node, vue-go, nextjs-python, react-native-node）"
      echo "  --repo <owner/repo>  GitHub 仓库（默认：$FORGE_REPO）"
      echo "  --branch <分支>      分支（默认：$FORGE_BRANCH）"
      echo ""
      echo "示例："
      echo "  curl -fsSL https://raw.githubusercontent.com/$FORGE_REPO/$FORGE_BRANCH/install.sh | bash -s -- --stack react-node"
      exit 0
      ;;
    *) echo "未知参数：$1（使用 --help 查看帮助）"; exit 1 ;;
  esac
done

PROJECT_DIR="$(pwd)"
PROJECT_NAME=$(basename "$PROJECT_DIR")

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Forge — 安装框架"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  项目：$PROJECT_NAME"
echo "  路径：$PROJECT_DIR"
[ -n "$STACK_NAME" ] && echo "  技术栈：${STACK_NAME}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# ── 判断来源：本地 or 远程 ───────────────────────────────

FORGE_SOURCE=""
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" 2>/dev/null && pwd || echo "")"

if [ -n "$SCRIPT_DIR" ] && [ -f "$SCRIPT_DIR/CLAUDE.md" ] && [ -d "$SCRIPT_DIR/.claude/commands" ]; then
  FORGE_SOURCE="local"
  FORGE_DIR="$SCRIPT_DIR"
  echo "[来源] 本地：$FORGE_DIR"
else
  FORGE_SOURCE="remote"
  echo "[来源] 远程：github.com/$FORGE_REPO@$FORGE_BRANCH"
fi

# ── 远程下载 ─────────────────────────────────────────────

if [ "$FORGE_SOURCE" = "remote" ]; then
  tmpdir=$(mktemp -d)
  trap "rm -rf '$tmpdir'" EXIT

  echo "  正在下载..."
  archive_url="https://github.com/$FORGE_REPO/archive/refs/heads/$FORGE_BRANCH.tar.gz"

  if command -v curl &>/dev/null; then
    curl -fsSL "$archive_url" -o "$tmpdir/forge.tar.gz"
  elif command -v wget &>/dev/null; then
    wget -q "$archive_url" -O "$tmpdir/forge.tar.gz"
  else
    echo "错误：需要 curl 或 wget"; exit 1
  fi

  tar -xzf "$tmpdir/forge.tar.gz" -C "$tmpdir"
  repo_name=$(echo "$FORGE_REPO" | cut -d'/' -f2)
  FORGE_DIR="$tmpdir/${repo_name}-${FORGE_BRANCH}"

  if [ ! -f "$FORGE_DIR/CLAUDE.md" ]; then
    echo "错误：下载内容无效"; exit 1
  fi
  echo "  下载完成。"
fi

echo ""

# ── 安装 .claude/ 下所有内容 ─────────────────────────────

echo "[1/4] 安装 Claude Code 配置..."

# 指令
mkdir -p .claude/commands
if ls "$FORGE_DIR/.claude/commands/"*.md &>/dev/null; then
  for f in "$FORGE_DIR/.claude/commands/"*.md; do cp "$f" .claude/commands/; done
fi

# 技能
mkdir -p .claude/skills
if [ -d "$FORGE_DIR/.claude/skills" ]; then
  for d in "$FORGE_DIR/.claude/skills/"*/; do
    name=$(basename "$d")
    mkdir -p ".claude/skills/$name"
    cp -r "$d"* ".claude/skills/$name/"
  done
fi

# 规则
mkdir -p .claude/rules
if ls "$FORGE_DIR/.claude/rules/"*.md &>/dev/null; then
  for f in "$FORGE_DIR/.claude/rules/"*.md; do cp "$f" .claude/rules/; done
fi

# 智能体
mkdir -p .claude/agents
if ls "$FORGE_DIR/.claude/agents/"*.md &>/dev/null; then
  for f in "$FORGE_DIR/.claude/agents/"*.md; do cp "$f" .claude/agents/; done
fi

# 钩子
mkdir -p .claude/hooks
if ls "$FORGE_DIR/.claude/hooks/"*.cjs &>/dev/null; then
  for f in "$FORGE_DIR/.claude/hooks/"*.cjs; do cp "$f" .claude/hooks/; done
fi

# 技术栈预设
mkdir -p .claude/stacks
if ls "$FORGE_DIR/.claude/stacks/"*.yaml &>/dev/null; then
  for f in "$FORGE_DIR/.claude/stacks/"*.yaml; do cp "$f" .claude/stacks/; done
fi
if ls "$FORGE_DIR/.claude/stacks/"*.template &>/dev/null; then
  for f in "$FORGE_DIR/.claude/stacks/"*.template; do cp "$f" .claude/stacks/; done
fi

# settings.json
if [ ! -f ".claude/settings.json" ]; then
  cat > .claude/settings.json << 'SETTINGS_EOF'
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Bash",
        "hooks": [
          { "type": "command", "command": "node .claude/hooks/human-gate.cjs 2>/dev/null; rc=$?; [ $rc -eq 2 ] && exit 2; exit 0" },
          { "type": "command", "command": "node .claude/hooks/branch-doc-check.cjs 2>/dev/null; rc=$?; [ $rc -eq 2 ] && exit 2; exit 0" },
          { "type": "command", "command": "node .claude/hooks/pre-commit-quality.cjs 2>/dev/null; rc=$?; [ $rc -eq 2 ] && exit 2; exit 0" }
        ]
      }
    ],
    "PostToolUse": [
      {
        "matcher": "Edit|Write",
        "hooks": [
          { "type": "command", "command": "node .claude/hooks/doc-sync.cjs 2>/dev/null || true" }
        ]
      }
    ]
  }
}
SETTINGS_EOF
else
  echo "  .claude/settings.json 已存在，请手动合并钩子配置。"
fi

echo "  已安装：commands(7) skills(5) rules(4) agents(7) hooks(4) stacks(4)"

# ── 初始化 OpenSpec ──────────────────────────────────────

echo "[2/4] 初始化 OpenSpec..."

# 安装 @fission-ai/openspec
if command -v pnpm &>/dev/null; then
  pnpm add -D @fission-ai/openspec 2>/dev/null || echo "  警告：无法安装 @fission-ai/openspec，将手动创建目录结构"
else
  echo "  警告：未找到 pnpm，请先安装 pnpm（npm install -g pnpm）"
fi

if [ ! -d "openspec" ]; then
  if command -v pnpm &>/dev/null; then
    pnpm exec openspec init --tools none --profile core 2>/dev/null || {
      mkdir -p openspec/specs openspec/changes/archive
    }
  else
    mkdir -p openspec/specs openspec/changes/archive
  fi
fi

# 安装 forge-lifecycle schema
mkdir -p openspec/schemas/forge-lifecycle/templates
if [ -d "$FORGE_DIR/schemas/forge-lifecycle" ]; then
  cp -r "$FORGE_DIR/schemas/forge-lifecycle/"* openspec/schemas/forge-lifecycle/
fi

# 技术栈配置
STACK_CONTEXT=""
if [ -n "$STACK_NAME" ]; then
  if [ -f ".claude/stacks/${STACK_NAME}.yaml" ]; then
    STACK_CONTEXT="技术栈：${STACK_NAME}（详见 .claude/stacks/${STACK_NAME}.yaml）"
  else
    echo "  警告：技术栈 '$STACK_NAME' 未找到"; STACK_NAME=""
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
fi
echo "  已安装 OpenSpec + forge-lifecycle schema"

# ── 创建项目结构 ─────────────────────────────────────────

echo "[3/4] 创建项目结构..."

mkdir -p docs

if [ ! -f ".gitignore" ]; then
  cat > .gitignore << 'EOF'
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
EOF
fi

# ── 生成 CLAUDE.md ───────────────────────────────────────

echo "[4/4] 生成 CLAUDE.md..."

if [ ! -f "CLAUDE.md" ]; then
  cat > CLAUDE.md << CLAUDE_EOF
# $PROJECT_NAME

## Forge 工程框架
本项目使用 [Forge](https://github.com/$FORGE_REPO) 工程框架，支持从创意到产品落地的完整生命周期。

## 指令
| 指令 | 用途 |
|------|------|
| \`/genesis\` | 产品从 0 到 1 |
| \`/iterate\` | 功能迭代 |
| \`/hotfix\` | 线上 Bug 修复 |
| \`/recover\` | 会话恢复 |
| \`/design-review\` | 产品设计评审（人工关卡） |
| \`/tech-review\` | 技术架构评审（人工关卡） |
| \`/accept\` | 功能验收（人工关卡） |

## 技术栈
${STACK_NAME:+当前技术栈：\`${STACK_NAME}\`（详见 \`.claude/stacks/${STACK_NAME}.yaml\`）}
${STACK_NAME:-技术栈未指定，使用 /genesis 时会引导选择。}

详见 \`openspec/config.yaml\`。

## 测试
\`\`\`bash
cd frontend && pnpm test
cd backend && pnpm test
\`\`\`
CLAUDE_EOF
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Forge 安装完成！"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "  安装后目录："
echo "  .claude/commands/   — /genesis, /iterate, /hotfix 等指令"
echo "  .claude/skills/     — 产品设计、UI/UX、API、测试等知识"
echo "  .claude/rules/      — 架构、前端、后端、第一性原理规则"
echo "  .claude/agents/     — 7 个专职智能体"
echo "  .claude/hooks/      — 审批阻塞、文档同步等钩子"
echo "  .claude/stacks/     — 技术栈预设"
echo "  openspec/           — 规格文档 + forge-lifecycle schema"
echo ""
echo "  直接在 Claude Code 中输入 /genesis 开始使用！"
echo ""
