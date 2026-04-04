#!/usr/bin/env node

/**
 * 人工审批关卡钩子（PreToolUse — Bash）
 *
 * 在 git commit 时检查 OpenSpec 变更文档中的审批标记。
 * - 有规格但未通过设计评审 → 阻塞提交（exit 2）
 * - 有技术设计但未通过技术评审 → 阻塞提交（exit 2）
 * - 所有任务完成但未验收 → 仅提醒（不阻塞）
 *
 * 审批标记格式（结构化，防误匹配）：
 *   <!-- FORGE_GATE:DESIGN_REVIEW:APPROVED:2024-01-15 -->
 *   <!-- FORGE_GATE:TECH_REVIEW:APPROVED:2024-01-15 -->
 *   <!-- FORGE_GATE:ACCEPTANCE:APPROVED:2024-01-15 -->
 */

const fs = require('fs');
const path = require('path');

// 结构化审批标记匹配
const GATE_PATTERN = {
  design: /<!--\s*FORGE_GATE:DESIGN_REVIEW:APPROVED:\d{4}-\d{2}-\d{2}\s*-->/,
  tech: /<!--\s*FORGE_GATE:TECH_REVIEW:APPROVED:\d{4}-\d{2}-\d{2}\s*-->/,
  acceptance: /<!--\s*FORGE_GATE:ACCEPTANCE:APPROVED:\d{4}-\d{2}-\d{2}\s*-->/,
};

let data = '';
process.stdin.on('data', chunk => data += chunk);
process.stdin.on('end', () => {
  try {
    const input = JSON.parse(data);
    const { tool_input } = input;

    if (!tool_input || !tool_input.command || !tool_input.command.includes('git commit')) {
      process.stdout.write(data);
      return;
    }

    // 查找活跃的 OpenSpec 变更
    const changesDir = path.join(process.cwd(), 'openspec', 'changes');
    if (!fs.existsSync(changesDir)) {
      process.stdout.write(data);
      return;
    }

    const changes = fs.readdirSync(changesDir)
      .filter(d => d !== 'archive' && fs.statSync(path.join(changesDir, d)).isDirectory());

    let shouldBlock = false;
    const blockReasons = [];

    for (const change of changes) {
      const changeDir = path.join(changesDir, change);
      const proposalPath = path.join(changeDir, 'proposal.md');
      const designPath = path.join(changeDir, 'design.md');
      const tasksPath = path.join(changeDir, 'tasks.md');

      if (!fs.existsSync(proposalPath)) continue;

      const proposal = fs.readFileSync(proposalPath, 'utf-8');

      // 有产品规格但未通过设计评审 → 阻塞
      const specsDir = path.join(changeDir, 'specs');
      if (fs.existsSync(specsDir)) {
        const hasDesignApproval = GATE_PATTERN.design.test(proposal);
        if (!hasDesignApproval) {
          shouldBlock = true;
          blockReasons.push(
            `变更 "${change}"：有产品规格但未通过设计评审。请先运行 /design-review。`
          );
        }
      }

      // 有技术设计但未通过技术评审 → 阻塞
      if (fs.existsSync(designPath)) {
        const design = fs.readFileSync(designPath, 'utf-8');
        const hasTechApproval = GATE_PATTERN.tech.test(design);
        if (!hasTechApproval) {
          shouldBlock = true;
          blockReasons.push(
            `变更 "${change}"：有技术设计但未通过技术评审。请先运行 /tech-review。`
          );
        }
      }

      // 所有任务完成后提醒验收（仅提醒，不阻塞）
      if (fs.existsSync(tasksPath)) {
        const tasks = fs.readFileSync(tasksPath, 'utf-8');
        const totalTasks = (tasks.match(/- \[[ x]\]/g) || []).length;
        const completedTasks = (tasks.match(/- \[x\]/g) || []).length;

        if (totalTasks > 0 && completedTasks === totalTasks) {
          const hasAcceptance = GATE_PATTERN.acceptance.test(proposal);
          if (!hasAcceptance) {
            process.stderr.write(
              `[Forge:人工关卡] 提示：变更 "${change}" 的所有任务已完成。\n` +
              `建议运行 /accept 进行用户验收。\n`
            );
          }
        }
      }
    }

    if (shouldBlock) {
      process.stderr.write(
        `[Forge:人工关卡] 阻塞提交：缺少必要的人工审批。\n` +
        blockReasons.map(r => `  - ${r}`).join('\n') + '\n'
      );
      process.exit(2); // exit 2 = 阻塞 PreToolUse
    }

    process.stdout.write(data);
  } catch (e) {
    // 解析失败时放行，避免阻塞正常操作
    process.stdout.write(data);
  }
});
