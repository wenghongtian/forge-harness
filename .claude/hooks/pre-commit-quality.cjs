#!/usr/bin/env node

/**
 * 提交前质量检查钩子（PreToolUse — Bash）
 *
 * git commit 前运行基本质量检查：
 * - 检测常见问题（console.log、无任务的 TODO、调试工件）
 * - 检查 .env 文件是否被暂存
 * - 大量文件提交时发出警告
 */

const fs = require('fs');
const path = require('path');
const { execSync } = require('child_process');

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

    const warnings = [];

    try {
      const stagedFiles = execSync('git diff --cached --name-only', { encoding: 'utf-8' })
        .trim().split('\n').filter(f => f);

      // 大量文件提交警告
      if (stagedFiles.length > 20) {
        warnings.push(`大量提交：暂存了 ${stagedFiles.length} 个文件。建议拆分为更小的提交。`);
      }

      // 检查源码文件中的问题
      const sourceFiles = stagedFiles.filter(f =>
        /\.(ts|tsx|js|jsx|py|go|vue|svelte)$/.test(f) &&
        !f.includes('node_modules') &&
        !f.includes('.test.') && !f.includes('.spec.')
      );

      for (const file of sourceFiles) {
        const fullPath = path.join(process.cwd(), file);
        if (!fs.existsSync(fullPath)) continue;

        const content = fs.readFileSync(fullPath, 'utf-8');
        const lines = content.split('\n');

        lines.forEach((line, i) => {
          if (/console\.(log|debug|warn)\(/.test(line) && !file.includes('logger')) {
            warnings.push(`${file}:${i + 1} — 检测到 console.log（请使用结构化日志）`);
          }
          if (/^\s*debugger\s*;?\s*$/.test(line)) {
            warnings.push(`${file}:${i + 1} — 发现 debugger 语句`);
          }
        });
      }

      // 检查 .env 文件
      const envFiles = stagedFiles.filter(f => f.includes('.env') && !f.endsWith('.example'));
      if (envFiles.length > 0) {
        warnings.push(`安全警告：.env 文件被暂存了：${envFiles.join(', ')}`);
      }
    } catch (e) {
      // git 不可用或不在仓库中
    }

    if (warnings.length > 0) {
      process.stderr.write(
        `[Forge:质量检查] 提交前警告：\n` +
        warnings.map(w => `  - ${w}`).join('\n') + '\n'
      );
    }

    process.stdout.write(data);
  } catch (e) {
    process.stdout.write(data);
  }
});
