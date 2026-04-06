---
name: testing-strategy
description: 测试策略与方法。定义不同层次的测试覆盖要求和最佳实践。
---

# 测试策略

## 何时使用
当编写测试或验证实现质量时引用此技能。

## 测试金字塔

```
        /  E2E  \         少量，验证关键流程
       / 集成测试 \        中等，验证模块协作
      /  单元测试   \      大量，验证独立逻辑
```

## 后端测试

### 单元测试（服务层）
- 测试纯业务逻辑，mock 外部依赖
- 每个 service 方法至少覆盖：正常路径 + 1 个错误路径
- 使用工厂函数生成测试数据，不硬编码

```typescript
describe('UserService', () => {
  it('创建用户时应该哈希密码', async () => {
    const user = await userService.create({ email: 'a@b.com', password: '123456' });
    expect(user.password).not.toBe('123456');
  });

  it('邮箱已存在时应该抛出 CONFLICT 错误', async () => {
    await userService.create({ email: 'a@b.com', password: '123456' });
    await expect(userService.create({ email: 'a@b.com', password: '654321' }))
      .rejects.toThrow('RESOURCE_CONFLICT');
  });
});
```

### 集成测试（API 端点）
- 用真实数据库（测试数据库），不用 mock
- 每个端点测试：成功响应 + 验证失败 + 认证失败
- 验证响应格式与 API 契约一致

```typescript
describe('POST /api/v1/users', () => {
  it('应该返回 201 和创建的用户', async () => {
    const res = await request(app)
      .post('/api/v1/users')
      .send({ email: 'a@b.com', password: '123456' });
    expect(res.status).toBe(201);
    expect(res.body.data).toHaveProperty('id');
  });

  it('缺少邮箱时应该返回 422', async () => {
    const res = await request(app)
      .post('/api/v1/users')
      .send({ password: '123456' });
    expect(res.status).toBe(422);
    expect(res.body.code).toBe('VALIDATION_ERROR');
  });
});
```

## 前端测试

### 组件测试
- 测试用户可见的行为，不测试内部实现
- 使用 Testing Library 的查询优先级：`getByRole` > `getByLabelText` > `getByText` > `getByTestId`
- 每个交互组件测试：渲染 + 用户交互 + 状态变化

```typescript
describe('LoginForm', () => {
  it('应该在邮箱格式错误时显示错误信息', async () => {
    render(<LoginForm />);
    await userEvent.type(screen.getByLabelText('邮箱'), 'invalid');
    await userEvent.click(screen.getByRole('button', { name: '登录' }));
    expect(screen.getByText('请输入有效的邮箱地址')).toBeVisible();
  });
});
```

### Hook 测试
- 复杂的自定义 hook 单独测试
- 使用 `renderHook` 测试状态变化

## 测试命名规范

统一格式：`应该 [预期行为]（当 [条件] 时）`

```
✓ 应该返回 201 和创建的用户
✓ 应该在邮箱已存在时返回 409
✓ 应该在未登录时返回 401
✗ 测试创建用户（太模糊）
✗ createUser test（不描述预期行为）
```

## 测试数据管理

- 每个测试独立，不依赖其他测试的数据
- 使用 `beforeEach` 重置数据库状态
- 工厂函数生成测试数据，支持覆盖默认值：

```typescript
function createUser(overrides = {}) {
  return {
    email: `test-${Date.now()}@example.com`,
    password: 'password123',
    name: 'Test User',
    ...overrides,
  };
}
```

## 什么不需要测试

- 框架自身的功能（路由匹配、ORM 查询构建器）
- 简单的数据传递（getter/setter）
- 第三方库的行为
- 纯展示组件（没有交互逻辑的）
