---
name: api-design
description: RESTful API 设计规范。统一的请求/响应格式、错误处理和认证模式。
---

# API 设计规范

## 何时使用
当设计或实现 API 端点时引用此技能。确保前后端契约一致。

## URL 设计

```
GET    /api/v1/users          # 列表
POST   /api/v1/users          # 创建
GET    /api/v1/users/:id      # 详情
PUT    /api/v1/users/:id      # 全量更新
PATCH  /api/v1/users/:id      # 部分更新
DELETE /api/v1/users/:id      # 删除
```

### 命名规则
- 资源名用复数名词：`/users` 不是 `/user`
- 嵌套资源最多两层：`/users/:id/posts` 可以，`/users/:id/posts/:id/comments` 太深
- 操作用 HTTP 方法表达，不用动词 URL：用 `POST /users` 不用 `/createUser`

## 统一响应格式

### 成功（单个资源）
```json
{
  "code": "",
  "data": {
    "id": "uuid",
    "name": "...",
    "createdAt": "2024-01-01T00:00:00Z"
  },
  "errorMsg": ""
}
```

### 成功（列表）
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

### 错误
```json
{
  "code": "VALIDATION_ERROR",
  "data": null,
  "errorMsg": "邮箱格式无效"
}
```

### HTTP 状态码使用
| 状态码 | 含义 | 使用场景 |
|--------|------|----------|
| 200 | 成功 | GET、PUT、PATCH、DELETE 成功 |
| 201 | 已创建 | POST 创建资源成功 |
| 204 | 无内容 | DELETE 成功，无需返回体 |
| 400 | 请求错误 | 请求体格式错误 |
| 401 | 未认证 | 未登录或 token 过期 |
| 403 | 未授权 | 已登录但没有权限 |
| 404 | 未找到 | 资源不存在 |
| 409 | 冲突 | 唯一约束冲突（如邮箱已注册） |
| 422 | 验证失败 | 格式正确但业务验证不通过 |
| 429 | 频率限制 | 请求过于频繁 |
| 500 | 服务器错误 | 未预期的服务端异常 |

## 分页

### 偏移分页（简单场景）
```
GET /api/v1/users?page=2&limit=20&sort=-createdAt
```

### 游标分页（大数据集）
```
GET /api/v1/users?cursor=abc123&limit=20
```

响应的 `meta` 中包含 `nextCursor`。

## 筛选与排序

```
GET /api/v1/users?status=active&role=admin&sort=-createdAt,name
```

- 筛选：查询参数直接对应字段名
- 排序：`sort` 参数，`-` 前缀表示降序
- 搜索：`q` 参数做全文搜索

## 认证

### Bearer Token
```
Authorization: Bearer <token>
```

### 刷新机制
- Access Token：短期（15 分钟）
- Refresh Token：长期（7 天），httpOnly Cookie
- Access Token 过期后用 Refresh Token 换新的

## 错误码规范

统一前缀分类：
- `AUTH_*` — 认证相关（AUTH_TOKEN_EXPIRED, AUTH_INVALID_CREDENTIALS）
- `VALIDATION_*` — 验证相关（VALIDATION_ERROR, VALIDATION_REQUIRED）
- `RESOURCE_*` — 资源相关（RESOURCE_NOT_FOUND, RESOURCE_CONFLICT）
- `RATE_*` — 频率相关（RATE_LIMIT_EXCEEDED）
- `SERVER_*` — 服务端（SERVER_ERROR）
