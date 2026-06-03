# `*.prompt.md` 文件契约

## 命名

- 后缀 **`.prompt.md`**，便于 `check-prompts` 与 `build-prompt-index` 扫描。
- **`id` 全局唯一**，不要用日期当 id；同一 id 在 `share` + 所有 `projects` 中只出现一次。

## Front matter（YAML，少而稳）

```yaml
---
id: my-prompt-id
scope: share               # share | project
project:                   # scope=project 时必填 project-key；scope=share 时留空或可省略整键
type: debug                # debug | review | generation | extraction | rewrite（可扩展）
owner_skill: prompt-engineering
status: active             # active | deprecated
replaced_by: ''            # 仅 status=deprecated 时必填，值为替代本条目的 active id
---
```

- `scope=project` → `project:` **必填**（与 hub `prompts/projects/<key>/` 一致）。
- `scope=share` → **不得**为非空 `project`（键省略或空即视为空；`project: ''` 经校验脚本等价空）。
- `type`、`owner_skill` 必填；`status` 仅 `active` / `deprecated`。
- **`replaced_by`**：`deprecated` **必须**指向仍存在且 **`status=active`** 的 **`id`**；`active` **不得**出现 `replaced_by`。

**可选字段（非 CI 校验，但从项目/设计文档/代码提炼时强烈推荐填写）**：

```yaml
source_kind: design_doc    # conversation | design_doc | code | sql_config
source_anchor: 'docs/design/ai/SMART_DATA_QUERY_IMPROVEMENT_DESIGN.md §系统提示词'
target_runtime: <runtime-module>   # 该 prompt 在哪个运行时/模块中被加载（可选）
```

- `source_kind`：标识 prompt 的来源类型，便于后续定位与更新维护。
- `source_anchor`：源文件的路径和章节（形如 `文件路径 §章节名` 或 `文件路径:行号`）；从设计文档或代码提炼时必填，从会话提炼时可省略。
- `target_runtime`：该 prompt 实际被加载的运行时模块，有助于判断 prompt 的影响面。

> 这三个字段写在正式 `---` front matter 里，`check-prompts` 不校验、不报错；但可在正文「提炼来源」段中重复引用以提高可读性。

## 正文四段（与模板一致；**CI 校验**）

以下 **四级 `##` 标题必须按顺序各出现一次**，且 **`## Prompt 正文`**、**`## 验收标准`** 下须有非空正文（`check-prompts.sh` 调用 `scripts/validate-prompt-body.awk`；`check-prompts.ps1` 为等效原生实现）。

1. **适用场景**
2. **输入要求**
3. **Prompt 正文**
4. **验收标准**

可在四段之前插入其它 `##`（如「提炼来源」），但不得打乱上述四段的前后顺序。

## CI 与 `check-prompts` 会拦什么

- front matter：`id`、`scope`、`type`、`owner_skill`、`status`、`project/replaced_by` 组合规则
- 正文 / front matter 含 **`TODO`**、疑似**密钥/令牌**模式
- **重复 `id`**
- **四段标题**缺失、重复、**顺序错误**
- **`## Prompt 正文`** 或 **`## 验收标准`** 为空

备份与编码：改动前 **`backup-file`**；UTF-8 无 BOM 为佳。
