# Webapp Testing 检查清单

## 开始前

- [ ] 已明确验证目标是页面、交互、回归还是 bug 复现
- [ ] 已确认页面是静态 HTML 还是动态应用
- [ ] 已确认本地服务是否已启动
- [ ] 已确认是否依赖后端、登录态或 Mock

## 侦察阶段

- [ ] 已等待页面稳定，例如 `networkidle`
- [ ] 已截图或观察渲染后的真实 DOM
- [ ] 已识别可靠选择器，而不是纯猜测
- [ ] 已在需要时记录控制台日志

## 动作阶段

- [ ] 优先走主链路
- [ ] 动作脚本保持最小闭环
- [ ] 优先复用已有脚本、命令或 helper
- [ ] 没有为简单验证编写过重脚本

## 验证阶段

- [ ] 主链路结果可观测
- [ ] 关键按钮、输入、表格或弹窗状态已检查
- [ ] 页面无明显控制台错误
- [ ] 如失败，已留下截图或日志

## 最小 Playwright 骨架

```python
from playwright.sync_api import sync_playwright

with sync_playwright() as p:
    browser = p.chromium.launch(headless=True)
    page = browser.new_page()
    page.goto("http://127.0.0.1:5173")
    page.wait_for_load_state("networkidle")

    page.screenshot(path="artifacts/home.png", full_page=True)
    page.get_by_role("button", name="查询").click()

    assert "接口管理" in page.content()
    browser.close()
```