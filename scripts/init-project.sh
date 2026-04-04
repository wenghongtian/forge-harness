#!/bin/bash
set -euo pipefail

# ============================================================================
# Forge — 初始化新项目
# 用法：./scripts/init-project.sh <项目名称> [技术栈名称]
#
# 创建新项目目录并安装 Forge 框架。
# 本质上是：mkdir + git init + install.sh 的封装。
# ============================================================================

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
FORGE_DIR="$(dirname "$SCRIPT_DIR")"

PROJECT_NAME="${1:-}"
STACK_NAME="${2:-}"

if [ -z "$PROJECT_NAME" ]; then
  echo "用法：$0 <项目名称> [技术栈名称]"
  echo ""
  echo "可用技术栈："
  for f in "$FORGE_DIR/stacks"/*.yaml; do
    name=$(basename "$f" .yaml)
    [[ "$name" == *"template"* ]] && continue
    desc=$(grep '^description:' "$f" | sed 's/description: //')
    echo "  $name — $desc"
  done
  exit 1
fi

PROJECT_DIR="$(pwd)/$PROJECT_NAME"

if [ -d "$PROJECT_DIR" ]; then
  echo "错误：目录 '$PROJECT_DIR' 已存在。"
  echo "如果要在已有项目中安装 Forge，请直接运行："
  echo "  cd $PROJECT_DIR && $FORGE_DIR/install.sh${STACK_NAME:+ --stack $STACK_NAME}"
  exit 1
fi

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Forge — 初始化新项目"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# 创建项目目录
mkdir -p "$PROJECT_DIR"
cd "$PROJECT_DIR"

# 初始化 git
git init --quiet
echo "node_modules/
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
" > .gitignore

echo "  已创建项目目录并初始化 Git"

# 调用 install.sh 完成框架安装
if [ -n "$STACK_NAME" ]; then
  "$FORGE_DIR/install.sh" --stack "$STACK_NAME"
else
  "$FORGE_DIR/install.sh"
fi

echo ""
echo "后续步骤："
echo "  cd $PROJECT_NAME"
echo "  # 使用 /genesis 开始从零构建产品"
echo ""
