#!/usr/bin/env node

/**
 * 分支文档检查钩子（PreToolUse — Bash）
 *
 * 切换分支时，检查目标分支是否有关联的 OpenSpec 变更文件夹。
 * 如果在功能分支上工作但没有正确的文档追踪，发出警告。
 */

const fs = require('fs');
const path = require('path');

let data = '';
process.stdin.on('data', chunk => data += chunk);
process.stdin.on('end', () => {
  try {
    const input = JSON.parse(data);
    const { tool_input } = input;

    if (!tool_input || !tool_input.command) {
      process.stdout.write(data);
      return;
    }

    const cmd = tool_input.command;

    // 检测分支切换命令
    const branchSwitchPatterns = [
      /git\s+checkout\s+(?!-b)(\S+)/,
      /git\s+switch\s+(\S+)/,
      /git\s+checkout\s+-b\s+(\S+)/,
      /git\s+switch\s+-c\s+(\S+)/
    ];

    let targetBranch = null;
    let isNewBranch = false;

    for (const pattern of branchSwitchPatterns) {
      const match = cmd.match(pattern);
      if (match) {
        targetBranch = match[1];
        isNewBranch = cmd.includes('-b') || cmd.includes('-c');
        break;
      }
    }

    if (!targetBranch) {
      process.stdout.write(data);
      return;
    }

    // 跳过主分支
    if (['main', 'master', 'develop', 'dev'].includes(targetBranch)) {
      process.stdout.write(data);
      return;
    }

    if (isNewBranch) {
      process.stderr.write(
        `[Forge:分支文档] 提示：正在创建分支 "${targetBranch}"。\n` +
        `记得创建 OpenSpec 变更：pnpm exec openspec new change <变更名>\n`
      );
    } else {
      const changesDir = path.join(process.cwd(), 'openspec', 'changes');
      if (fs.existsSync(changesDir)) {
        const changes = fs.readdirSync(changesDir).filter(d => d !== 'archive');
        const branchSlug = targetBranch.replace(/^(feature|hotfix|bugfix)\//, '');
        const hasChange = changes.some(c => c.includes(branchSlug) || branchSlug.includes(c));

        if (!hasChange) {
          process.stderr.write(
            `[Forge:分支文档] 警告：分支 "${targetBranch}" 没有匹配的 OpenSpec 变更。\n` +
            `建议创建：pnpm exec openspec new change <变更名>\n`
          );
        }
      }
    }

    process.stdout.write(data);
  } catch (e) {
    process.stdout.write(data);
  }
});
