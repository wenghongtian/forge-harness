# 架构规则

## 前后端分离
- 前端和后端始终是独立的应用，位于独立目录
- 它们仅通过 `contracts/` 中定义的 API 契约通信
- 前后端之间不共享运行时代码
- 共享的类型/接口可以提取到 `contracts/types/` 目录

## API 契约优先
- 在实现端点之前，先定义 API 契约（OpenAPI/GraphQL schema）
- 将契约存储在 `contracts/api/`
- 前后端都必须遵守契约
- 对契约的破坏性变更需要创建新的 OpenSpec 变更提案

## 数据库设计
- 使用迁移，永远不要手动修改 schema
- 每张表都有：`id`（主键）、`created_at`、`updated_at`
- 面向用户的数据使用软删除（`deleted_at`）
- 外键设置合适的级联规则
- 在 WHERE 子句和 JOIN 中使用的所有列上建索引

## 项目结构规范

### 前端
```
frontend/
├── src/
│   ├── app/              # 应用入口、路由、Provider
│   ├── components/       # 可复用 UI 组件
│   │   ├── ui/           # 基础 UI 原子组件（来自 UI 库）
│   │   └── [领域]/       # 领域相关组件
│   ├── features/         # 功能模块（就近组织相关逻辑）
│   │   └── [功能]/
│   │       ├── components/
│   │       ├── hooks/
│   │       ├── api/
│   │       └── types.ts
│   ├── hooks/            # 共享 hooks
│   ├── lib/              # 工具函数、辅助方法
│   ├── stores/           # 全局状态
│   └── types/            # 共享类型
├── public/
└── package.json
```

### 后端
```
backend/
├── src/
│   ├── app/              # 应用入口、服务器配置
│   ├── routes/           # 路由定义
│   ├── controllers/      # 请求处理器
│   ├── services/         # 业务逻辑
│   ├── models/           # 数据模型 / ORM 实体
│   ├── middleware/        # 中间件
│   ├── validators/       # 输入验证模式
│   ├── lib/              # 工具函数
│   └── types/            # 类型定义
├── prisma/（或 migrations/）
└── package.json（或 go.mod、requirements.txt）
```

## 错误处理
- 后端：所有错误返回统一的 JSON 格式 `{ error: { code: string, message: string, details?: any } }`
- 前端：全局错误边界 + 按路由的错误处理
- API 错误：正确使用标准 HTTP 状态码（400 输入错误、401 认证、403 授权、404 未找到、422 验证、500 服务器错误）

## 认证与授权
- 使用 JWT 或基于会话的认证（根据技术栈配置）
- 所有受保护路由添加认证中间件
- 需要时使用基于角色的访问控制（RBAC）
- 永远不要明文存储密码
- 永远不要在 API 响应中暴露敏感数据

## 环境配置
- 使用 `.env` 文件进行本地开发（永远不要提交）
- 所有因部署环境而异的配置使用环境变量
- 启动时验证所有环境变量，缺失则快速失败
