# webapp-testing — 真实闭环样例

## 样例目标

验证一个最小静态页面是否能按“侦察 -> 动作 -> 验证”完成黑盒主链路。

目标页面：`references/examples/ui_smoke_demo.html`

## 环境准备（executed）

本轮已用本地临时 HTTP 服务提供 demo 页面，且本机确认响应成功：

```text
200
```

## 侦察（observed）

浏览器快照先确认：

- 页面标题：`Webapp Testing Demo`
- 交互元素：`Run smoke` 按钮
- 这一步没有直接猜选择器，而是先用快照识别唯一交互 ref

## 动作（observed）

对 `Run smoke` 按钮执行单击后，页面状态变为：

- `Status: done`
- 结果文案：`Smoke flow passed`

## 验证（observed）

本轮黑盒验证已满足：

- 页面能打开
- 主链路动作可执行
- 点击后有可观察状态变化
- 结果文案可见，形成最小闭环

## Evidence

- 证据等级：`executed + observed`
- 有本机 HTTP 200
- 有浏览器前后快照
- 有交互动作后的状态变化

## 限制

本样例是最小静态 UI smoke，不覆盖登录态、后端依赖、网络错误、复杂异步渲染；更复杂页面仍需按 `references/checklist.md` 扩展验证。
