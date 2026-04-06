# 后端开发规则（NestJS）

## 框架规范
- 使用 **NestJS** 框架，遵循其模块化架构
- 每个业务领域一个 Module，包含 Controller、Service、DTO、Entity
- 使用依赖注入（DI），禁止手动实例化服务
- 使用 **@nestjs/swagger** 装饰器为所有 DTO 和 Controller 添加 API 文档
- 所有 DTO 属性必须有 `@ApiProperty()` 装饰器，确保 Swagger 文档完整

## API 设计
- RESTful 风格
- 面向资源的 URL：`/api/v1/[资源]`
- 使用正确的 HTTP 方法：GET（读取）、POST（创建）、PUT（全量更新）、PATCH（部分更新）、DELETE（删除）
- 分页：大数据集用游标分页，小数据集用偏移分页
- 过滤：查询参数使用清晰命名（`?status=active&sort=-created_at`）
- 版本管理：URL 前缀 `/api/v1/`

## 请求/响应规范

所有接口统一返回以下格式：
```json
{
  "code": "",
  "data": null,
  "errorMsg": ""
}
```

### 成功响应
`code` 和 `errorMsg` 为空字符串，`data` 为实际数据：
```json
{
  "code": "",
  "data": { "id": 1, "name": "example" },
  "errorMsg": ""
}
```

分页数据放在 `data` 内部：
```json
{
  "code": "",
  "data": {
    "list": [...],
    "total": 100,
    "page": 1,
    "pageSize": 20
  },
  "errorMsg": ""
}
```

### 错误响应
仅异常时 `code` 和 `errorMsg` 有值，`data` 为 null：
```json
{
  "code": "VALIDATION_ERROR",
  "data": null,
  "errorMsg": "邮箱格式无效"
}
```

## 输入验证
- 使用 **class-validator** + **class-transformer** 验证 DTO
- 在 `main.ts` 中全局启用 `ValidationPipe`
- 永远不要只依赖客户端验证
- 清理字符串以防止 XSS
- 使用 TypeORM 参数化查询，禁止拼接 SQL

## 业务逻辑
- 业务逻辑放在 Service 中，不放在 Controller
- Controller：解析请求 → 调用 Service → 返回响应
- Service：纯业务逻辑，不涉及 HTTP 概念
- Entity：TypeORM 实体定义 + 数据库映射
- 保持 Controller 精简，Service 可测试

## 数据库
- 始终使用迁移进行 schema 变更
- 编写幂等迁移（可安全重复运行）
- 为外键和高频查询列建索引
- 多表操作使用事务
- 合理配置连接池

## 认证
- 认证中间件作为链中的第一个中间件
- 会话使用 httpOnly、secure、sameSite 的 Cookie（或 JWT 用 Authorization 头）
- 长时间会话的令牌刷新机制
- 认证端点（登录、注册、重置密码）添加速率限制
- 多次登录失败后锁定账户

## Swagger 文档
- 在 `main.ts` 中配置 `SwaggerModule`，生成 `/api-docs` 端点
- 所有 Controller 方法使用 `@ApiOperation`、`@ApiResponse` 装饰器
- 所有 DTO 属性使用 `@ApiProperty` 装饰器（含 description、example）
- 枚举类型使用 `@ApiProperty({ enum: ... })`
- 分页响应使用统一的泛型 DTO
- Swagger JSON 是前端 @umijs/openapi 生成接口代码的唯一数据源

## 日志与监控
- 使用 NestJS 内置 Logger（不用 console.log）
- 日志级别：error、warn、log、debug、verbose
- 所有日志包含请求 ID 用于链路追踪
- 记录所有入站请求（方法、路径、状态、耗时）
- 永远不要记录敏感数据（密码、令牌、个人信息）

## 错误处理
- 使用 NestJS ExceptionFilter 全局捕获异常
- 生产环境响应中不暴露堆栈信息
- 自定义业务异常继承 `HttpException`
- 服务端记录完整错误细节，客户端返回安全消息

## 测试
- 使用 NestJS 默认的 **Jest** 测试框架
- Service 层单元测试（模拟依赖）
- Controller 层使用 `@nestjs/testing` 的 `Test.createTestingModule`
- E2E 测试使用 Supertest
- 测试错误场景，不只是正常路径
- 使用工厂/Fixture 生成测试数据
