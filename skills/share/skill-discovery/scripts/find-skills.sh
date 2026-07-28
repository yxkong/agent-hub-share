#!/usr/bin/env bash
# find-skills.sh — 搜索本地和在线技能，可一键安装
#
# 本地搜索：
#   find-skills.sh [--query <关键词>] [--project <key>]
#
# 在线搜索（skills.sh / GitHub）：
#   find-skills.sh --remote <关键词>
#
# 搜索并安装（一条命令）：
#   find-skills.sh --remote <关键词> --install              # 安装第 1 条
#   find-skills.sh --remote <关键词> --pick 2 --install     # 安装第 2 条
#   find-skills.sh --remote <关键词> --dry-run              # 仅预览下载，不移入
#
# 其他参数：
#   --hub-root <path>        hub 根目录（默认从脚本路径推导或 AGENTS_HUB_ROOT）
#   --scope share|project    安装目标（默认 share）
#   --install-project <key>  --scope project 时指定 project-key
#   --output table|json      本地搜索输出格式（默认 table）

set -euo pipefail

HUB_ROOT="${AGENTS_HUB_ROOT:-}"
QUERY=""
REMOTE_QUERY=""
PROJECT_KEY=""
OUTPUT_FMT="table"
PICK_N=1
DO_INSTALL=0
DRY_RUN=0
SCOPE="share"
INSTALL_PROJECT=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --hub-root)         HUB_ROOT="${2:-}";         shift 2 ;;
    --query)            QUERY="${2:-}";             shift 2 ;;
    --remote)           REMOTE_QUERY="${2:-}";      shift 2 ;;
    --project)          PROJECT_KEY="${2:-}";       shift 2 ;;
    --pick)             PICK_N="${2:-1}";           shift 2 ;;
    --install)          DO_INSTALL=1;               shift   ;;
    --dry-run)          DRY_RUN=1; DO_INSTALL=1;   shift   ;;
    --scope)            SCOPE="${2:-share}";        shift 2 ;;
    --install-project)  INSTALL_PROJECT="${2:-}";  shift 2 ;;
    --output)           OUTPUT_FMT="${2:-table}";  shift 2 ;;
    *) echo "find-skills: unknown arg: $1" >&2; exit 1 ;;
  esac
done

# 推导 hub root
if [ -z "$HUB_ROOT" ]; then
  _SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" 2>/dev/null && pwd)"
  HUB_ROOT="$(cd "#!/usr/bin/env bash
# find-skills.sh — 搜索本地和在线技能，可一键安装
#
# 本地搜索：
#   find-skills.sh [--query <关键词>] [--project <key>]
#
# 在线搜索（skills.sh / GitHub）：
#   find-skills.sh --remote <关键词>
#
# 搜索并安装（一条命令）：
#   find-skills.sh --remote <关键词> --install              # 安装第 1 条
#   find-skills.sh --remote <关键词> --pick 2 --install     # 安装第 2 条
#   find-skills.sh --remote <关键词> --dry-run              # 仅预览下载，不移入
#
# 其他参数：
#   --hub-root <path>        hub 根目录（默认从脚本路径推导或 AGENTS_HUB_ROOT）
#   --scope share|project    安装目标（默认 share）
#   --install-project <key>  --scope project 时指定 project-key
#   --output table|json      本地搜索输出格式（默认 table）

set -euo pipefail

HUB_ROOT="${AGENTS_HUB_ROOT:-}"
QUERY=""
REMOTE_QUERY=""
PROJECT_KEY=""
OUTPUT_FMT="table"
PICK_N=1
DO_INSTALL=0
DRY_RUN=0
SCOPE="share"
INSTALL_PROJECT=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --hub-root)         HUB_ROOT="${2:-}";         shift 2 ;;
    --query)            QUERY="${2:-}";             shift 2 ;;
    --remote)           REMOTE_QUERY="${2:-}";      shift 2 ;;
    --project)          PROJECT_KEY="${2:-}";       shift 2 ;;
    --pick)             PICK_N="${2:-1}";           shift 2 ;;
    --install)          DO_INSTALL=1;               shift   ;;
    --dry-run)          DRY_RUN=1; DO_INSTALL=1;   shift   ;;
    --scope)            SCOPE="${2:-share}";        shift 2 ;;
    --install-project)  INSTALL_PROJECT="${2:-}";  shift 2 ;;
    --output)           OUTPUT_FMT="${2:-table}";  shift 2 ;;
    *) echo "find-skills: unknown arg: $1" >&2; exit 1 ;;
  esac
done

# 推导 hub root
if [ -z "$HUB_ROOT" ]; then
  _SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" 2>/dev/null && pwd)"
  HUB_ROOT="$(cd "$_SCRIPT_DIR/../../../.." 2>/dev/null && pwd)"
fi

SKILLS_SHARE="$HUB_ROOT/skills/share"
SKILLS_PROJECTS="$HUB_ROOT/skills/projects"
SCRIPTS_DIR="$HUB_ROOT/scripts"

# ── 在线搜索 ──────────────────────────────────────────────────────────────────

if [ -n "$REMOTE_QUERY" ]; then
  echo "🔍 在线搜索：\"$REMOTE_QUERY\" ..."
  echo ""

  # 用 Python3 调用 GitHub API（skills.sh API 优先；回退 GitHub 代码搜索）
  PY=""
  for _py in python3 python; do
    if command -v "$_py" >/dev/null 2>&1; then
      PY="$_py"; break
    fi
  done

  if [ -z "$PY" ]; then
    echo "find-skills: Python3 not found; cannot do remote search" >&2
    exit 1
  fi

  # 生成候选 TSV：name\trepo\tskill_path\tdesc
  # 策略1：抓取 skills.sh 页面内嵌 initialSkills JSON（最权威来源）
  # 策略2：GitHub repository search（回退，需 GITHUB_TOKEN 才能用 code search）
  REMOTE_TSV=$("$PY" - "$REMOTE_QUERY" <<'PYEOF'
import sys, json, re, subprocess, os

query = sys.argv[1] if len(sys.argv) > 1 else ""
GITHUB_TOKEN = os.environ.get("GITHUB_TOKEN", "")

def curl_get(url, headers=None, timeout=12):
    cmd = ["curl", "-fsSL", "--max-time", str(timeout)]
    for k, v in (headers or {}).items():
        cmd += ["-H", k + ": " + v]
    cmd.append(url)
    try:
        r = subprocess.run(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE,
                           timeout=timeout + 2)
        return r.stdout.decode("utf-8", errors="replace") if r.returncode == 0 else None
    except Exception:
        return None

def search_skills_sh(q):
    """
    从 skills.sh 首页提取内嵌的 initialSkills JSON 数组（约 600 条）。
    格式：{"source":"owner/repo","skillId":"skill-name","name":"...","installs":N}
    页面数据是 \\\" 转义的 JSON，先替换再解析。
    """
    body = curl_get("https://skills.sh/", timeout=10)
    if not body:
        return None
    # 页面内嵌 escaped JSON：\\\" -> "
    body2 = body.replace('\\"', '"')
    marker = '"initialSkills":['
    idx = body2.find(marker)
    if idx < 0:
        return None
    start = idx + len(marker) - 1  # 指向 '['
    depth, end = 0, start
    for i, c in enumerate(body2[start:], start):
        if c == '[':
            depth += 1
        elif c == ']':
            depth -= 1
            if depth == 0:
                end = i + 1
                break
    try:
        skills = json.loads(body2[start:end])
    except Exception:
        return None
    q_low = q.lower()
    results = []
    for s in skills:
        name = s.get("name", s.get("skillId", ""))
        source = s.get("source", "")  # owner/repo
        skill_id = s.get("skillId", "")
        installs = s.get("installs", 0)
        if q_low in name.lower() or q_low in source.lower():
            results.append({
                "name": name,
                "repo": source,
                "path": skill_id,   # skillId 即安装时的子路径
                "desc": f"installs={installs:,}"
            })
    return results if results else None

def search_github_repos(q):
    """GitHub repository search（不需要 token，适合搜 agent skill 仓库）"""
    import urllib.parse
    url = ("https://api.github.com/search/repositories?q="
           + urllib.parse.quote(q + " SKILL.md")
           + "&sort=stars&per_page=10")
    hdrs = {"Accept": "application/vnd.github.v3+json", "User-Agent": "agent-hub/1.0"}
    if GITHUB_TOKEN:
        hdrs["Authorization"] = f"token {GITHUB_TOKEN}"
    body = curl_get(url, hdrs, timeout=12)
    if not body:
        return []
    try:
        data = json.loads(body)
        results = []
        for item in data.get("items", []):
            repo = item["full_name"]
            desc = (item.get("description") or "")[:80]
            results.append({"name": repo.split("/")[-1], "repo": repo, "path": "", "desc": desc})
        return results
    except Exception:
        return []

results = search_skills_sh(query)
if results is None:
    # skills.sh 无匹配时，回退到 GitHub repo 搜索
    print("# skills.sh 无匹配，尝试 GitHub 仓库搜索...", file=sys.stderr)
    results = search_github_repos(query)

for r in results:
    print(f"{r['name']}\t{r['repo']}\t{r['path']}\t{r['desc']}")
PYEOF
  ) || true

  if [ -z "$REMOTE_TSV" ]; then
    echo "未找到匹配的在线技能。"
    echo "提示：可手动浏览 https://skills.sh 后用 --remote <精确名称> 重试"
    exit 0
  fi

  # 把 TSV 转为数组，打印带序号的候选表（Bash 3 兼容：不用 mapfile）
  ROWS=()
  while IFS= read -r line; do
    [ -n "$line" ] && ROWS+=("$line")
  done <<< "$REMOTE_TSV"

  printf "%3s  %-30s %-35s %-30s %s\n" "#" "SKILL" "REPO" "PATH" "DESC"
  printf "%3s  %-30s %-35s %-30s %s\n" "---" "------" "----" "----" "----"

  idx=1
  for row in "${ROWS[@]}"; do
    IFS=$'\t' read -r name repo spath desc <<< "$row"
    printf "%3d  %-30s %-35s %-30s %s\n" "$idx" "$name" "$repo" "$spath" "$desc"
    idx=$((idx + 1))
  done
  echo ""
  echo "共 ${#ROWS[@]} 条在线候选"

  # 若不需要安装，到此结束
  if [ "$DO_INSTALL" -eq 0 ]; then
    echo ""
    echo "提示：加 --install 安装第 1 条；--pick N --install 安装第 N 条"
    echo "      加 --dry-run 仅下载验证，不移入 skills/"
    exit 0
  fi

  # 安装第 PICK_N 条
  if [ "$PICK_N" -gt "${#ROWS[@]}" ]; then
    echo "find-skills: --pick $PICK_N 超出结果数量 (${#ROWS[@]})" >&2
    exit 1
  fi
  SELECTED="${ROWS[$((PICK_N - 1))]}"
  IFS=$'\t' read -r SEL_NAME SEL_REPO SEL_PATH _desc <<< "$SELECTED"

  echo ""
  echo "▶ 选中 #${PICK_N}: $SEL_NAME  ($SEL_REPO  $SEL_PATH)"

  INSTALL_SCRIPT="$SCRIPTS_DIR/install-skill-from-registry.sh"
  if [ ! -f "$INSTALL_SCRIPT" ]; then
    echo "find-skills: install-skill-from-registry.sh not found at $INSTALL_SCRIPT" >&2
    exit 1
  fi

  INSTALL_ARGS=("$SEL_REPO")
  [ -n "$SEL_PATH" ] && INSTALL_ARGS+=("$SEL_PATH")
  INSTALL_ARGS+=("--hub-root" "$HUB_ROOT" "--scope" "$SCOPE")
  [ -n "$INSTALL_PROJECT" ] && INSTALL_ARGS+=("--project" "$INSTALL_PROJECT")
  [ "$DRY_RUN" -eq 1 ] && INSTALL_ARGS+=("--dry-run")

  bash "$INSTALL_SCRIPT" "${INSTALL_ARGS[@]}"
  exit $?
fi

# ── 本地搜索 ──────────────────────────────────────────────────────────────────

. "$SCRIPTS_DIR/agent-hub-paths.sh"

if [ ! -d "$SKILLS_SHARE" ]; then
  echo "find-skills: skills/share not found under $HUB_ROOT" >&2
  exit 1
fi

parse_skill() {
  local file="$1" scope="$2" project="$3"
  local name="" desc="" in_fm=0 fm_done=0

  while IFS= read -r line; do
    if [[ $fm_done -eq 1 ]]; then break; fi
    if [[ $line == "---" ]]; then
      if [[ $in_fm -eq 0 ]]; then in_fm=1; continue; fi
      if [[ $in_fm -eq 1 ]]; then fm_done=1; break; fi
    fi
    if [[ $in_fm -eq 1 ]]; then
      if [[ $line =~ ^name:[[:space:]]*(.+)$ ]];        then name="${BASH_REMATCH[1]}"; fi
      if [[ $line =~ ^description:[[:space:]]*(.+)$ ]]; then desc="${BASH_REMATCH[1]:0:80}"; fi
    fi
  done < "$file"

  if [ -n "$QUERY" ]; then
    local combined q_lower
    combined=$(echo "$name $desc" | tr '[:upper:]' '[:lower:]')
    q_lower=$(echo "$QUERY" | tr '[:upper:]' '[:lower:]')
    if [[ "$combined" != *"$q_lower"* ]]; then return 0; fi
  fi

  local rel_path="${file#$HUB_ROOT/}"
  echo "${name}|${scope}|${project}|${rel_path}|${desc}"
}

RESULTS=()

while IFS= read -r skill_md; do
  [ -z "$skill_md" ] && continue
  rel_path="${skill_md#$HUB_ROOT/}"
  scope="share"
  project="-"
  case "$rel_path" in
    skills/projects/*/*/*)
      scope="project"
      project=$(printf '%s' "$rel_path" | cut -d/ -f3)
      ;;
    skills/media/*/*)
      scope="media"
      ;;
  esac
  row=$(parse_skill "$skill_md" "$scope" "$project")
  [ -n "$row" ] && RESULTS+=("$row")
done <<EOF
$(agent_canonical_skill_md_files "$HUB_ROOT" "$PROJECT_KEY")
EOF

if [[ "$OUTPUT_FMT" == "json" ]]; then
  echo "["
  first=1
  for row in "${RESULTS[@]+"${RESULTS[@]}"}"; do
    IFS='|' read -r name scope project path desc <<< "$row"
    [ $first -eq 0 ] && echo ","
    printf '  {"skill":"%s","scope":"%s","project":"%s","path":"%s","description_snippet":"%s"}' \
      "$name" "$scope" "$project" "$path" "$desc"
    first=0
  done
  echo ""
  echo "]"
else
  printf "%-35s %-10s %-20s %s\n" "SKILL" "SCOPE" "PROJECT" "PATH"
  printf "%-35s %-10s %-20s %s\n" "-----" "-----" "-------" "----"
  for row in "${RESULTS[@]+"${RESULTS[@]}"}"; do
    IFS='|' read -r name scope project path desc <<< "$row"
    printf "%-35s %-10s %-20s %s\n" "$name" "$scope" "$project" "$path"
  done
  echo ""
  echo "Total: ${#RESULTS[@]} skill(s)"
  echo ""
  echo "在线搜索：find-skills.sh --remote <关键词> [--pick N] [--install]"
fi
SCRIPT_DIR/../../../.." 2>/dev/null && pwd)"
fi

SKILLS_SHARE="$HUB_ROOT/skills/share"
SKILLS_PROJECTS="$HUB_ROOT/skills/projects"
SCRIPTS_DIR="$HUB_ROOT/scripts"

# ── 在线搜索 ──────────────────────────────────────────────────────────────────

if [ -n "$REMOTE_QUERY" ]; then
  echo "🔍 在线搜索：\"$REMOTE_QUERY\" ..."
  echo ""

  # 用 Python3 调用 GitHub API（skills.sh API 优先；回退 GitHub 代码搜索）
  PY=""
  for _py in python3 python; do
    if command -v "$_py" >/dev/null 2>&1; then
      PY="$_py"; break
    fi
  done

  if [ -z "$PY" ]; then
    echo "find-skills: Python3 not found; cannot do remote search" >&2
    exit 1
  fi

  # 生成候选 TSV：name\trepo\tskill_path\tdesc
  # 策略1：抓取 skills.sh 页面内嵌 initialSkills JSON（最权威来源）
  # 策略2：GitHub repository search（回退，需 GITHUB_TOKEN 才能用 code search）
  REMOTE_TSV=$("$PY" - "$REMOTE_QUERY" <<'PYEOF'
import sys, json, re, subprocess, os

query = sys.argv[1] if len(sys.argv) > 1 else ""
GITHUB_TOKEN = os.environ.get("GITHUB_TOKEN", "")

def curl_get(url, headers=None, timeout=12):
    cmd = ["curl", "-fsSL", "--max-time", str(timeout)]
    for k, v in (headers or {}).items():
        cmd += ["-H", k + ": " + v]
    cmd.append(url)
    try:
        r = subprocess.run(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE,
                           timeout=timeout + 2)
        return r.stdout.decode("utf-8", errors="replace") if r.returncode == 0 else None
    except Exception:
        return None

def search_skills_sh(q):
    """
    从 skills.sh 首页提取内嵌的 initialSkills JSON 数组（约 600 条）。
    格式：{"source":"owner/repo","skillId":"skill-name","name":"...","installs":N}
    页面数据是 \\\" 转义的 JSON，先替换再解析。
    """
    body = curl_get("https://skills.sh/", timeout=10)
    if not body:
        return None
    # 页面内嵌 escaped JSON：\\\" -> "
    body2 = body.replace('\\"', '"')
    marker = '"initialSkills":['
    idx = body2.find(marker)
    if idx < 0:
        return None
    start = idx + len(marker) - 1  # 指向 '['
    depth, end = 0, start
    for i, c in enumerate(body2[start:], start):
        if c == '[':
            depth += 1
        elif c == ']':
            depth -= 1
            if depth == 0:
                end = i + 1
                break
    try:
        skills = json.loads(body2[start:end])
    except Exception:
        return None
    q_low = q.lower()
    results = []
    for s in skills:
        name = s.get("name", s.get("skillId", ""))
        source = s.get("source", "")  # owner/repo
        skill_id = s.get("skillId", "")
        installs = s.get("installs", 0)
        if q_low in name.lower() or q_low in source.lower():
            results.append({
                "name": name,
                "repo": source,
                "path": skill_id,   # skillId 即安装时的子路径
                "desc": f"installs={installs:,}"
            })
    return results if results else None

def search_github_repos(q):
    """GitHub repository search（不需要 token，适合搜 agent skill 仓库）"""
    import urllib.parse
    url = ("https://api.github.com/search/repositories?q="
           + urllib.parse.quote(q + " SKILL.md")
           + "&sort=stars&per_page=10")
    hdrs = {"Accept": "application/vnd.github.v3+json", "User-Agent": "agent-hub/1.0"}
    if GITHUB_TOKEN:
        hdrs["Authorization"] = f"token {GITHUB_TOKEN}"
    body = curl_get(url, hdrs, timeout=12)
    if not body:
        return []
    try:
        data = json.loads(body)
        results = []
        for item in data.get("items", []):
            repo = item["full_name"]
            desc = (item.get("description") or "")[:80]
            results.append({"name": repo.split("/")[-1], "repo": repo, "path": "", "desc": desc})
        return results
    except Exception:
        return []

results = search_skills_sh(query)
if results is None:
    # skills.sh 无匹配时，回退到 GitHub repo 搜索
    print("# skills.sh 无匹配，尝试 GitHub 仓库搜索...", file=sys.stderr)
    results = search_github_repos(query)

for r in results:
    print(f"{r['name']}\t{r['repo']}\t{r['path']}\t{r['desc']}")
PYEOF
  ) || true

  if [ -z "$REMOTE_TSV" ]; then
    echo "未找到匹配的在线技能。"
    echo "提示：可手动浏览 https://skills.sh 后用 --remote <精确名称> 重试"
    exit 0
  fi

  # 把 TSV 转为数组，打印带序号的候选表（Bash 3 兼容：不用 mapfile）
  ROWS=()
  while IFS= read -r line; do
    [ -n "$line" ] && ROWS+=("$line")
  done <<< "$REMOTE_TSV"

  printf "%3s  %-30s %-35s %-30s %s\n" "#" "SKILL" "REPO" "PATH" "DESC"
  printf "%3s  %-30s %-35s %-30s %s\n" "---" "------" "----" "----" "----"

  idx=1
  for row in "${ROWS[@]}"; do
    IFS=$'\t' read -r name repo spath desc <<< "$row"
    printf "%3d  %-30s %-35s %-30s %s\n" "$idx" "$name" "$repo" "$spath" "$desc"
    idx=$((idx + 1))
  done
  echo ""
  echo "共 ${#ROWS[@]} 条在线候选"

  # 若不需要安装，到此结束
  if [ "$DO_INSTALL" -eq 0 ]; then
    echo ""
    echo "提示：加 --install 安装第 1 条；--pick N --install 安装第 N 条"
    echo "      加 --dry-run 仅下载验证，不移入 skills/"
    exit 0
  fi

  # 安装第 PICK_N 条
  if [ "$PICK_N" -gt "${#ROWS[@]}" ]; then
    echo "find-skills: --pick $PICK_N 超出结果数量 (${#ROWS[@]})" >&2
    exit 1
  fi
  SELECTED="${ROWS[$((PICK_N - 1))]}"
  IFS=$'\t' read -r SEL_NAME SEL_REPO SEL_PATH _desc <<< "$SELECTED"

  echo ""
  echo "▶ 选中 #${PICK_N}: $SEL_NAME  ($SEL_REPO  $SEL_PATH)"

  INSTALL_SCRIPT="$SCRIPTS_DIR/install-skill-from-registry.sh"
  if [ ! -f "$INSTALL_SCRIPT" ]; then
    echo "find-skills: install-skill-from-registry.sh not found at $INSTALL_SCRIPT" >&2
    exit 1
  fi

  INSTALL_ARGS=("$SEL_REPO")
  [ -n "$SEL_PATH" ] && INSTALL_ARGS+=("$SEL_PATH")
  INSTALL_ARGS+=("--hub-root" "$HUB_ROOT" "--scope" "$SCOPE")
  [ -n "$INSTALL_PROJECT" ] && INSTALL_ARGS+=("--project" "$INSTALL_PROJECT")
  [ "$DRY_RUN" -eq 1 ] && INSTALL_ARGS+=("--dry-run")

  bash "$INSTALL_SCRIPT" "${INSTALL_ARGS[@]}"
  exit $?
fi

# ── 本地搜索 ──────────────────────────────────────────────────────────────────

. "$SCRIPTS_DIR/agent-hub-paths.sh"

if [ ! -d "$SKILLS_SHARE" ]; then
  echo "find-skills: skills/share not found under $HUB_ROOT" >&2
  exit 1
fi

parse_skill() {
  local file="$1" scope="$2" project="$3"
  local name="" desc="" in_fm=0 fm_done=0

  while IFS= read -r line; do
    if [[ $fm_done -eq 1 ]]; then break; fi
    if [[ $line == "---" ]]; then
      if [[ $in_fm -eq 0 ]]; then in_fm=1; continue; fi
      if [[ $in_fm -eq 1 ]]; then fm_done=1; break; fi
    fi
    if [[ $in_fm -eq 1 ]]; then
      if [[ $line =~ ^name:[[:space:]]*(.+)$ ]];        then name="${BASH_REMATCH[1]}"; fi
      if [[ $line =~ ^description:[[:space:]]*(.+)$ ]]; then desc="${BASH_REMATCH[1]:0:80}"; fi
    fi
  done < "$file"

  if [ -n "$QUERY" ]; then
    local combined q_lower
    combined=$(echo "$name $desc" | tr '[:upper:]' '[:lower:]')
    q_lower=$(echo "$QUERY" | tr '[:upper:]' '[:lower:]')
    if [[ "$combined" != *"$q_lower"* ]]; then return 0; fi
  fi

  local rel_path="${file#$HUB_ROOT/}"
  echo "${name}|${scope}|${project}|${rel_path}|${desc}"
}

RESULTS=()

while IFS= read -r skill_md; do
  [ -z "$skill_md" ] && continue
  rel_path="${skill_md#$HUB_ROOT/}"
  scope="share"
  project="-"
  case "$rel_path" in
    skills/projects/*/*/*)
      scope="project"
      project=$(printf '%s' "$rel_path" | cut -d/ -f3)
      ;;
    skills/media/*/*)
      scope="media"
      ;;
  esac
  row=$(parse_skill "$skill_md" "$scope" "$project")
  [ -n "$row" ] && RESULTS+=("$row")
done <<EOF
$(agent_canonical_skill_md_files "$HUB_ROOT" "$PROJECT_KEY")
EOF

if [[ "$OUTPUT_FMT" == "json" ]]; then
  echo "["
  first=1
  for row in "${RESULTS[@]+"${RESULTS[@]}"}"; do
    IFS='|' read -r name scope project path desc <<< "$row"
    [ $first -eq 0 ] && echo ","
    printf '  {"skill":"%s","scope":"%s","project":"%s","path":"%s","description_snippet":"%s"}' \
      "$name" "$scope" "$project" "$path" "$desc"
    first=0
  done
  echo ""
  echo "]"
else
  printf "%-35s %-10s %-20s %s\n" "SKILL" "SCOPE" "PROJECT" "PATH"
  printf "%-35s %-10s %-20s %s\n" "-----" "-----" "-------" "----"
  for row in "${RESULTS[@]+"${RESULTS[@]}"}"; do
    IFS='|' read -r name scope project path desc <<< "$row"
    printf "%-35s %-10s %-20s %s\n" "$name" "$scope" "$project" "$path"
  done
  echo ""
  echo "Total: ${#RESULTS[@]} skill(s)"
  echo ""
  echo "在线搜索：find-skills.sh --remote <关键词> [--pick N] [--install]"
fi
