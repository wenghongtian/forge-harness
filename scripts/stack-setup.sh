#!/bin/bash
set -euo pipefail

# ============================================================================
# Forge — 技术栈配置
# 用法：./scripts/stack-setup.sh <技术栈名称>
#
# 读取技术栈配置 YAML 并展示安装命令。
# 不会自动执行 — 展示方案供用户审阅。
# ============================================================================

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
FORGE_DIR="$(dirname "$SCRIPT_DIR")"

STACK_NAME="${1:-}"

if [ -z "$STACK_NAME" ]; then
  echo "用法：$0 <技术栈名称>"
  echo ""
  echo "可用技术栈："
  for f in "$FORGE_DIR/stacks"/*.yaml; do
    name=$(basename "$f" .yaml)
    [ "$name" = "custom.yaml" ] && continue
    [ "$name" = "custom" ] && continue
    desc=$(grep '^description:' "$f" 2>/dev/null | sed 's/description: //' || echo "")
    printf "  %-20s %s\n" "$name" "$desc"
  done
  exit 1
fi

STACK_FILE="$FORGE_DIR/stacks/${STACK_NAME}.yaml"
if [ ! -f "$STACK_FILE" ]; then
  echo "错误：技术栈 '$STACK_NAME' 未找到。"
  echo "可用选项：$(ls "$FORGE_DIR/stacks/"*.yaml 2>/dev/null | xargs -I{} basename {} .yaml | tr '\n' ' ')"
  exit 1
fi

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Forge — 技术栈配置：$STACK_NAME"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

echo "## 技术栈配置"
echo ""

echo "  前端："
grep -A20 '^frontend:' "$STACK_FILE" | grep -E '^\s+\w+:' | head -12 | sed 's/^/  /'
echo ""

echo "  后端："
grep -A20 '^backend:' "$STACK_FILE" | grep -E '^\s+\w+:' | head -12 | sed 's/^/  /'
echo ""

echo "  共享："
grep -A10 '^shared:' "$STACK_FILE" | grep -E '^\s+\w+:' | head -5 | sed 's/^/  /'
echo ""

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  请审阅上方配置。"
echo "  /genesis 技能会自动处理安装过程。"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
