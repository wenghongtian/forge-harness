# 架构规则

## 包管理
- 所有项目统一使用 **pnpm** 作为包管理器
- 禁止使用 npm 或 yarn
- 安装依赖：`pnpm add`，开发依赖：`pnpm add -D`
- 脚本执行：`pnpm run` 或 `pnpm exec`

## 前后端分离
- 前端和后端始终是独立的应用，位于独立目录
- 它们仅通过 API 契约通信（由后端 Swagger 自动生成，前端 @umijs/openapi 消费）
- 前后端之间不共享运行时代码

## API 契约：Swagger 驱动
- 后端通过 NestJS @nestjs/swagger 装饰器自动生成 OpenAPI 文档
- 前端通过 `@umijs/openapi` 读取后端 Swagger JSON 自动生成类型和接口调用代码
- **禁止手动编写 RESTful 接口请求代码** — 所有 API 调用必须由 @umijs/openapi 生成
- 契约变更流程：后端修改 DTO/Controller 装饰器 → 重启后端 → 前端执行 `pnpm openapi` 重新生成
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

### 后端（NestJS）
```
backend/
├── src/
│   ├── app.module.ts         # 根模块
│   ├── main.ts               # 入口（Swagger 配置在此）
│   ├── common/               # 共享装饰器、管道、过滤器、拦截器
│   │   ├── decorators/
│   │   ├── filters/
│   │   ├── guards/
│   │   ├── interceptors/
│   │   └── pipes/
│   ├── modules/              # 业务模块（按领域划分）
│   │   └── [模块]/
│   │       ├── [模块].module.ts
│   │       ├── [模块].controller.ts
│   │       ├── [模块].service.ts
│   │       ├── dto/          # 请求/响应 DTO（Swagger 装饰器在此）
│   │       └── entities/     # TypeORM 实体
│   └── config/               # 配置模块
├── prisma/（或 migrations/）
├── test/
└── package.json
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
