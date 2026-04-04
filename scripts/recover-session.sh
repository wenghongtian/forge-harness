#!/bin/bash
set -euo pipefail

# ============================================================================
# Forge — 会话恢复
# 用法：./scripts/recover-session.sh
#
# 读取 OpenSpec 文档重建当前工作状态。
# 输出恢复报告，用于在丢失的会话后继续工作。
# ============================================================================

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Forge — 会话恢复"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# 检查是否在项目中
if [ ! -d "openspec" ]; then
  echo "错误：未找到 openspec/ 目录。你在 Forge 项目中吗？"
  exit 1
fi

echo ""

# Git 状态
echo "## Git 状态"
BRANCH=$(git branch --show-current 2>/dev/null || echo "未知")
echo "  分支：$BRANCH"
echo "  最近提交："
git log --oneline -5 2>/dev/null | sed 's/^/    /'
echo ""

# 使用 OpenSpec 获取变更列表
echo "## 活跃变更"
echo ""

if command -v npx &> /dev/null; then
  npx openspec list --changes 2>/dev/null || {
    echo "  OpenSpec CLI 不可用，使用文件系统检查..."
    echo ""
  }
fi

# 文件系统回退检查
CHANGES_DIR="openspec/changes"
ACTIVE_CHANGES=$(find "$CHANGES_DIR" -maxdepth 1 -mindepth 1 -type d ! -name "archive" 2>/dev/null || true)

if [ -z "$ACTIVE_CHANGES" ]; then
  echo "  无活跃变更。使用 /genesis 或 /iterate 开始工作。"
  exit 0
fi

for CHANGE_DIR in $ACTIVE_CHANGES; do
  CHANGE_NAME=$(basename "$CHANGE_DIR")
  echo "### $CHANGE_NAME"

  # 尝试使用 OpenSpec 获取状态
  if command -v npx &> /dev/null; then
    npx openspec status --change "$CHANGE_NAME" 2>/dev/null || true
  fi

  # 检查审批状态
  if [ -f "$CHANGE_DIR/proposal.md" ]; then
    DESIGN_APPROVED="否"
    if grep -q "FORGE_GATE:DESIGN_REVIEW:APPROVED" "$CHANGE_DIR/proposal.md" 2>/dev/null; then
      DESIGN_APPROVED="是"
    fi
    echo "  设计评审已通过：$DESIGN_APPROVED"
  fi

  if [ -f "$CHANGE_DIR/design.md" ]; then
    TECH_APPROVED="否"
    if grep -q "FORGE_GATE:TECH_REVIEW:APPROVED" "$CHANGE_DIR/design.md" 2>/dev/null; then
      TECH_APPROVED="是"
    fi
    echo "  技术评审已通过：$TECH_APPROVED"
  fi

  # 检查任务进度
  if [ -f "$CHANGE_DIR/tasks.md" ]; then
    TOTAL=$(grep -c '\- \[[ x]\]' "$CHANGE_DIR/tasks.md" 2>/dev/null || echo "0")
    COMPLETED=$(grep -c '\- \[x\]' "$CHANGE_DIR/tasks.md" 2>/dev/null || echo "0")
    echo "  任务进度：$COMPLETED/$TOTAL 完成"

    NEXT_TASK=$(grep -m1 '\- \[ \]' "$CHANGE_DIR/tasks.md" 2>/dev/null | sed 's/- \[ \] //' || echo "无")
    echo "  下一个任务：$NEXT_TASK"
  fi

  echo ""
done

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  在 Claude Code 中使用 /recover 继续"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
