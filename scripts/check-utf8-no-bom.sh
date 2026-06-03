#!/usr/bin/env sh
set -eu

SCRIPT_DIR=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd -P)
. "$SCRIPT_DIR/agent-hub-paths.sh"

STAGED_ONLY=0
REPO_ROOT=''

while [ $# -gt 0 ]; do
  case "$1" in
    --staged-only) STAGED_ONLY=1; shift ;;
    --repo-root|--workspace-root) REPO_ROOT=$2; shift 2 ;;
    *) agent_fail "Unknown argument: $1" ;;
  esac
done

RESOLVED_REPO_ROOT=$(agent_resolve_workspace_root "$REPO_ROOT" 1)
[ -n "$RESOLVED_REPO_ROOT" ] || agent_fail 'A repository root is required. Pass --repo-root, set AGENTS_DEFAULT_PROJECT_ROOT, or run the script from the target repository.'
[ -d "$RESOLVED_REPO_ROOT/.git" ] || agent_fail "Not a Git repository root (missing .git): $RESOLVED_REPO_ROOT"

cd "$RESOLVED_REPO_ROOT"

is_text_target() {
  case "$1" in
    *.java|*.xml|*.yml|*.yaml|*.properties|*.md|*.sql|*.js|*.ts|*.vue|*.json|*.css|*.scss|*.html|*.ps1|*.sh)
      return 0 ;;
    *)
      return 1 ;;
  esac
}

get_target_files() {
  if [ "$STAGED_ONLY" = '1' ]; then
    git diff --cached --name-only --diff-filter=ACMR
  else
    git ls-files
  fi
}

invalid_found=0
for file in $(get_target_files); do
  [ -f "$file" ] || continue
  is_text_target "$file" || continue
  bom=$(LC_ALL=C od -An -t x1 -N 3 "$file" | tr -d ' \n')
  if [ "$bom" = 'efbbbf' ]; then
    if [ "$invalid_found" = '0' ]; then
      echo
      echo 'The following files use UTF-8 BOM. Convert them to UTF-8 without BOM before commit:'
      invalid_found=1
    fi
    echo "  $file"
  fi
done

if [ "$invalid_found" = '1' ]; then
  echo
  echo 'Shell fix for one file:'
  echo "perl -i -pe 'BEGIN{binmode STDIN; binmode STDOUT} s/^\x{FEFF}//' relative/path"
  echo 'UTF8_NO_BOM=fail'
  exit 1
fi

echo 'UTF8_NO_BOM=ok'
