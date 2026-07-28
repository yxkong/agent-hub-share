#!/usr/bin/env sh
set -eu

# Validates *.prompt.md under hub prompts/share and prompts/projects (excludes **/bak).
#
# Usage: check-prompts.sh [--hub-root DIR]

SKILL_SCRIPT_DIR=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd -P)
HUB_SCRIPTS_DIR=$(CDPATH='' cd -- "$SKILL_SCRIPT_DIR/../../../../scripts" && pwd -P)
SCRIPT_DIR="$HUB_SCRIPTS_DIR"
. "$HUB_SCRIPTS_DIR/agent-hub-paths.sh"

HUB_ROOT=''
while [ $# -gt 0 ]; do
  case "$1" in
    --hub-root) HUB_ROOT=$2; shift 2 ;;
    *) agent_fail "check-prompts: unknown arg: $1" ;;
  esac
done

AGENTS_ROOT=$(agent_resolve_hub_root "$HUB_ROOT" "$SCRIPT_DIR")
PROMPTS_ROOT="$AGENTS_ROOT/prompts"
VALIDATE_BODY_AWK="$SKILL_SCRIPT_DIR/validate-prompt-body.awk"
[ -f "$VALIDATE_BODY_AWK" ] || agent_fail "check-prompts: missing $VALIDATE_BODY_AWK"
command -v awk >/dev/null 2>&1 || agent_fail 'check-prompts requires awk（POSIX；macOS/Linux 自带；Windows 请用 check-prompts.ps1）'
COUNT=0

record() {
  printf 'PROMPT_CHECK_VIOLATION=%s reason=%s\n' "$1" "$2"
  COUNT=$((COUNT + 1))
}

extract_fm_value() {
  key=$1
  file=$2
  awk -v k="$key" '
    BEGIN { infm=0 }
    /^---$/ {
      if (infm == 0) { infm = 1; next }
      if (infm == 1) { exit 0 }
    }
    infm == 1 && $0 ~ "^" k ":" {
      sub("^" k ":[ \t]*", "")
      val=$0
      gsub(/^[ \t]+|[ \t]+$/, "", val)
      if (val == "''" || val == "\"\"") val=""
      print val
      exit 0
    }
  ' "$file"
}

LIST_TMP=$(mktemp)
IDS_TMP=$(mktemp)
trap 'rm -f "$LIST_TMP" "$IDS_TMP"' EXIT

find "$PROMPTS_ROOT/share" "$PROMPTS_ROOT/projects" -name '*.prompt.md' 2>/dev/null | sort > "$LIST_TMP" || true

while IFS= read -r f || [ -n "$f" ]; do
  [ -n "$f" ] || continue
  case "$f" in */bak/*) continue ;; esac

  id=$(extract_fm_value id "$f")
  sc=$(extract_fm_value scope "$f")
  pj=$(extract_fm_value project "$f")
  ty=$(extract_fm_value type "$f")
  ow=$(extract_fm_value owner_skill "$f")
  st=$(extract_fm_value status "$f")
  rb=$(extract_fm_value replaced_by "$f")

  [ -n "$id" ] || record "$f" 'front matter 缺少 id:'
  if [ -z "$sc" ]; then
    record "$f" 'front matter 缺少 scope:（须为 share 或 project）'
  elif [ "$sc" != 'share' ] && [ "$sc" != 'project' ]; then
    record "$f" "scope 非法（当前: ${sc}，须 share|project）"
  fi

  [ -n "$ty" ] || record "$f" 'front matter 缺少 type:'
  [ -n "$ow" ] || record "$f" 'front matter 缺少 owner_skill:'
  if [ -z "$st" ]; then
    record "$f" 'front matter 缺少 status:（须为 active 或 deprecated）'
  elif [ "$st" != 'active' ] && [ "$st" != 'deprecated' ]; then
    record "$f" "status 非法（当前: ${st}，须 active|deprecated）"
  fi

  if [ "$sc" = 'project' ]; then
    [ -n "$pj" ] || record "$f" 'scope=project 时 project: 必填（填 project-key）'
  fi
  if [ "$sc" = 'share' ] && [ -n "$pj" ]; then
    record "$f" 'scope=share 时 project: 必须为空'
  fi

  if [ "$st" = 'active' ] && [ -n "$rb" ]; then
    record "$f" 'status=active 时不应设置 replaced_by（请留空）'
  fi
  if [ "$st" = 'deprecated' ] && [ -z "$rb" ]; then
    record "$f" 'status=deprecated 时必须填写 replaced_by: <替代 id>'
  fi
  if [ "$st" = 'deprecated' ] && [ -n "$rb" ] && [ -n "$id" ] && [ "$rb" = "$id" ]; then
    record "$f" 'replaced_by 不能与本文件 id 相同'
  fi

  if grep -E -n '\bTODO\b' "$f" >/dev/null 2>&1; then
    record "$f" '正文或元数据包含 TODO（占位未清）'
  fi

  if grep -E -i -n '(api_key|apikey|client_secret|secret_key|password[[:space:]]*=[[:space:]]*[^[:space:]]+|Bearer[[:space:]]+[A-Za-z0-9_-]{24,})' "$f" >/dev/null 2>&1; then
    record "$f" '疑似密钥/令牌模式（请人工复核并改用占位符）'
  fi

  viol_out=$(awk -v apath="$f" -f "$VALIDATE_BODY_AWK" "$f")
  if [ -n "$viol_out" ]; then
    while IFS= read -r viol || [ -n "$viol" ]; do
      [ -z "$viol" ] && continue
      vp=${viol%%	*}
      rs=${viol#*	}
      record "$vp" "$rs"
    done <<EOF
$viol_out
EOF
  fi

  if [ -n "$id" ]; then
    printf '%s\t%s\t%s\n' "$id" "$f" "$st" >> "$IDS_TMP"
  fi
done < "$LIST_TMP"

if [ -s "$IDS_TMP" ]; then
  dup=$(cut -f 1 "$IDS_TMP" | sort | uniq -d)
  if [ -n "$dup" ]; then
    while IFS= read -r did || [ -n "$did" ]; do
      [ -z "$did" ] && continue
      m=$(awk -F'	' -v id="$did" '$1==id{printf "%s ", $2}' "$IDS_TMP")
      record "id=$did" "id 重复（须全局唯一）: $m"
    done <<EOF
$dup
EOF
  fi
fi

if [ -s "$IDS_TMP" ]; then
  while IFS= read -r f || [ -n "$f" ]; do
    [ -n "$f" ] || continue
    case "$f" in */bak/*) continue ;; esac
    st=$(extract_fm_value status "$f")
    rb=$(extract_fm_value replaced_by "$f")
    if [ "$st" = 'deprecated' ] && [ -n "$rb" ]; then
      rb_status=$(awk -F'\t' -v id="$rb" '$1==id{print $3; exit}' "$IDS_TMP")
      if [ -z "$rb_status" ]; then
        record "$f" "replaced_by 指向的 id 在 hub 中不存在: $rb"
      elif [ "$rb_status" != 'active' ]; then
        record "$f" "replaced_by 目标 status 非 active（当前: ${rb_status}），替代链无效: $rb"
      fi
    fi
  done < "$LIST_TMP"
fi

if [ "$COUNT" -eq 0 ]; then
  printf '%s\n' 'PROMPTS_CHECK=ok'
  exit 0
fi

printf 'PROMPTS_CHECK=fail count=%s\n' "$COUNT"
exit 1
