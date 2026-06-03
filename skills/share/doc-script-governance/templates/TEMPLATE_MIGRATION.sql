-- =============================================================================
-- 迁移：<topic 中文说明>
-- 模块：docs/db/dev/<module>/
-- 命名：MIGRATION_<topic>_YYYYMMDD.sql
-- 设计依据：docs/design/<domain>/... 或 docs/plan/...
-- 注意：禁止写入 docs/db/online/（Agent）
-- =============================================================================

-- [必填] 幂等：重复执行不报错（示例模式，按实际表调整）

-- 示例：菜单按钮（按项目 menu-sql-generator 规范展开）
-- INSERT INTO t_sys_menu (...) SELECT ... WHERE NOT EXISTS (...);
