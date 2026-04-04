#!/usr/bin/env node

/**
 * 文档同步钩子（PostToolUse — Edit|Write）
 *
 * 当编辑或创建代码文件后，检查是否有活跃的 OpenSpec 变更在追踪工作。
 * 如果代码变更缺少规格追踪，发出警告。
 */

const fs = require('fs');
const path = require('path');

let data = '';
process.stdin.on('data', chunk => data += chunk);
process.stdin.on('end', () => {
  try {
    const input = JSON.parse(data);
    const { tool_input } = input;

    if (!tool_input || !tool_input.file_path) {
      process.stdout.write(data);
      return;
    }

    const filePath = tool_input.file_path;

    // 跳过非源码文件
    const skipPatterns = [
      'openspec/', 'node_modules/', '.git/', 'package-lock.json',
      'CLAUDE.md', '.claude/', 'contracts/', '.env', 'docs/'
    ];

    if (skipPatterns.some(p => filePath.includes(p))) {
      process.stdout.write(data);
      return;
    }

    // 只检查源代码文件
    const sourceExtensions = ['.ts', '.tsx', '.js', '.jsx', '.py', '.go', '.vue', '.svelte', '.css', '.scss'];
    const ext = path.extname(filePath);
    if (!sourceExtensions.includes(ext)) {
      process.stdout.write(data);
      return;
    }

    // 检查是否有活跃的 OpenSpec 变更
    const changesDir = path.join(process.cwd(), 'openspec', 'changes');
    if (!fs.existsSync(changesDir)) {
      process.stderr.write(
        `[Forge:文档同步] 警告：正在编辑源代码但没有找到 OpenSpec 变更目录。\n` +
        `请先安装 Forge 框架：curl -fsSL https://raw.githubusercontent.com/wenghongtian/forge-harness/main/install.sh | bash\n`
      );
      process.stdout.write(data);
      return;
    }

    const activeChanges = fs.readdirSync(changesDir)
      .filter(d => d !== 'archive' && fs.statSync(path.join(changesDir, d)).isDirectory());

    if (activeChanges.length === 0) {
      process.stderr.write(
        `[Forge:文档同步] 警告：正在编辑源代码但没有活跃的 OpenSpec 变更。\n` +
        `请先创建变更：npx openspec new change <变更名>\n`
      );
    }

    process.stdout.write(data);
  } catch (e) {
    process.stdout.write(data);
  }
});
