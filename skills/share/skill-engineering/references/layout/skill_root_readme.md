# 技能根目录 README.md 规范

每个 **hub 真源技能**（`skills/share/<name>/` 或 `skills/projects/<key>/<name>/`）根目录**必须有** `README.md`。

## 1. 为什么要写（不是装饰）

| 问题 | README 如何解决 |
|------|-----------------|
| 后续改 skill 跑偏 | 固定「核心用途」一句话 + §不负责，扩写前先对照 |
| 与别的 skill 职责重复 | §边界与转交表写清「谁做、谁不做」 |
| 新人/维护者不知入口 | 指向 `SKILL.md`；`references/INDEX.md` 仅维护用 |
| `SKILL.md` 变长失焦 | README 给人读的总纲；细则仍在 references |
| 后续维护越改越飘 | 用「设计理解 / 分层原则 / 维护约束」固定设计哲学 |

**分工**：

- `README.md` — **章程**（用途、边界、去重、入口），变更频率低，宜负责人维护
- `SKILL.md` — **路由器**（触发、30 秒决策、红线），给 Agent 加载
- `references/` — **细则与模板**

**硬约束**：`README.md` 不是 Agent 运行入口，不得把 README 当作 `SKILL.md` 的替身。

## 2. 必填章节（复制 [TEMPLATE_SKILL_README.md](../templates/TEMPLATE_SKILL_README.md)）

1. **核心用途**（1–3 句，禁止空泛「提升效率」）
2. **设计理解 / 设计哲学**（为什么这样设计；不要只写“做什么”）
3. **分层原则 / 结构约定**（README / SKILL / references / scripts / templates 各自干什么）
4. **维护约束**（哪些地方不能漂、改一个点时必须联动哪些文件）
5. **单一职责**（本 skill **唯一**拥有的能力列表，≤5 条）
6. **不负责 / 转交**（表格：场景 → 转哪个 skill）
7. **入口**（`SKILL.md`；`references/INDEX.md` 若有，meta 禁止 Agent 入口）
8. **真源与挂载**（hub 路径；项目 `.claude/skills` 仅为 junction 时注明）
9. **§修订记录（人读）** — 技能资产版本与变更要点；**禁止**在 `references/*.md` 重复 YAML/修订表（Agent 不读、占上下文）

### 2.1 新增建议（命中时写入）

若该 skill 会定义 trigger / eval / 审查方法，README 建议额外写清：

- `description` 是技能发现入口，不应提前替正文总结 workflow
- 高风险 / 纪律执行类 skill 是否需要行为验证
- 指令具体度是否应按任务脆弱性区分高 / 中 / 低自由度

若存在像 `behavioral_eval.md` 这样的增强文档，README 应说明它：

- 是独立主路由，还是挂靠 `review` / `refine-trigger`
- 何种 skill 类型必须追加读取

禁止出现“references 里有增强文档，但 README / SKILL 没写入口关系”的状态。

## 3. 何时必须更新 README

- 首次 `create` 技能时 **与 SKILL.md 同批** 创建 README
- 扩展 `SKILL.md` 边界（新增「负责」项）前：先改 README §单一职责，避免与其它 skill 撞车
- `review` 发现职责重叠：在 README §不负责 补一行转交，而非在多个 skill 重复写同一套 SOP
- 设计哲学、分层、门禁、评分模型发生变化时：先更新 README 对应章节，再改运行细则
- trigger / eval 方法发生变化时：README 应同步写明是主路由变化，还是挂靠型增强变化
- **禁止**：把 README 写成第二份完整 SKILL（规则细节放 references）

## 4. 与工程完成门的关系

`create` / 重大 `review` 收尾时：

- [ ] 根目录存在 `README.md`
- [ ] README 明确写出“这是维护章程，不是运行入口”
- [ ] README 含 §设计理解 / §分层原则 / §维护约束
- [ ] §不负责 至少列出 2 个相邻 skill 的转交
- [ ] 核心用途与 `SKILL.md` frontmatter `description` 语义一致
- [ ] 若本次引入 trigger / eval 增强文档：README 已写清它是独立路由还是挂靠路由

## 5. 反模式

| 反模式 | 处理 |
|--------|------|
| 只有 SKILL.md 没有 README | 补 README，从 description 提炼核心用途 |
| README 与 SKILL 全文重复 | 删减 README，只留章程 |
| 多个 skill 都写「文档放哪」 | 只保留 `doc-script-governance`，其它 README 写转交 |
| README 堆实现细节 | 下沉 `references/` |
| README 只写用途，不写设计理解 | 补 §设计理解 / §维护约束，固定维护共识 |
| 新增增强文档但 README 没写入口关系 | 在 §入口 / §维护约束 说明它是独立路由还是挂靠路由 |
