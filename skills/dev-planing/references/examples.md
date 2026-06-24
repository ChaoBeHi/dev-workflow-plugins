# Planing 范例

## 方案文档范例

以下是一个完整方案文档的参考结构：

```markdown
# 方案：用户注销功能

## 改动范围
- `src/auth/logout.ts` — 新增注销接口
- `src/middleware/session.ts` — 添加 session 清理逻辑
- `tests/auth/logout.test.ts` — 新增测试文件

## 核心变更

### 接口
- `POST /api/auth/logout` — 接收 refresh_token，清除服务端 session
- 返回值：`{ success: true }` 或 `{ error: "TOKEN_INVALID" }`

### 数据流
1. 前端调用 logout，传入 refresh_token
2. 服务端验证 token → 删除 session → 清除 cookie
3. 前端收到成功响应 → 清除本地 token → 跳转登录页

## 风险点与缓解

| 风险 | 缓解措施 |
|------|---------|
| token 已在别处被刷新导致当前 token 失效 | 忽略 token 验证失败，仍然清除客户端状态 |
| 并发请求在注销后仍携带旧 cookie | 中间件层添加 session 黑名单检查 |

## 依赖变更
无新增依赖。
```

## 测试用例范例

### 正常路径

| ID | 用例 | 前置条件 | 预期结果 |
|----|------|---------|---------|
| TC-01 | 已登录用户注销 | 持有有效 token | 返回 `{ success: true }`，session 被清除 |
| TC-02 | 注销后再次访问受保护接口 | TC-01 执行后 | 返回 401 |

### 边界条件

| ID | 用例 | 前置条件 | 预期结果 |
|----|------|---------|---------|
| TC-03 | 传入空 token | — | 返回 `{ success: true }`（幂等） |
| TC-04 | 传入已过期的 token | token 已失效 | 返回 `{ success: true }`（忽略验证失败） |
| TC-05 | 连续调用注销两次 | — | 两次均返回 `{ success: true }` |

### 异常路径

| ID | 用例 | 前置条件 | 预期结果 |
|----|------|---------|---------|
| TC-06 | 数据库连接中断 | 模拟 DB 不可用 | 返回 500，记录错误日志 |
| TC-07 | token 格式非法（非 JWT） | — | 返回 `{ success: true }`（不抛异常） |

### 并发场景

| ID | 用例 | 前置条件 | 预期结果 |
|----|------|---------|---------|
| TC-08 | 注销同时发起新请求 | 两个请求并发 | 注销优先，另一请求正确返回 401 |
