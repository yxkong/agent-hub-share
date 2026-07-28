#!/usr/bin/env sh
set -eu

SKILL_SCRIPT_DIR=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd -P)
REPO_ROOT=$(CDPATH='' cd -- "$SKILL_SCRIPT_DIR/../../../.." && pwd -P)
SCRIPT_DIR="$SKILL_SCRIPT_DIR"
RUN_ID=$(date '+%Y%m%d-%H%M%S')
WORK_DIR="$REPO_ROOT/.tmp/backup-policy-check-$RUN_ID"
SAMPLE_FILE="$WORK_DIR/sample.name.md"

mkdir -p "$WORK_DIR"
printf '%s\n' 'backup policy check' > "$SAMPLE_FILE"

OUTPUT=$(sh "$SCRIPT_DIR/backup-file.sh" --file-path "$SAMPLE_FILE")
ARCHIVE_PATH=$(printf '%s\n' "$OUTPUT" | awk -F= '/^ARCHIVE_BACKUP=/{print $2; exit}')

[ -n "$ARCHIVE_PATH" ] || {
  printf '%s\n' 'backup-file.sh did not output ARCHIVE_BACKUP.' >&2
  exit 1
}

MONTH_BUCKET=$(date '+%Y%m')
EXPECTED_FRAGMENT="bak/$MONTH_BUCKET/sample_name_md"

case "$ARCHIVE_PATH" in
  *"$EXPECTED_FRAGMENT"*) ;;
  *)
    printf 'Archive path does not follow policy. Expected fragment: %s Actual: %s\n' "$EXPECTED_FRAGMENT" "$ARCHIVE_PATH" >&2
    exit 1
    ;;
esac

[ -f "$ARCHIVE_PATH" ] || {
  printf 'Archive backup was not created: %s\n' "$ARCHIVE_PATH" >&2
  exit 1
}

printf '%s\n' 'BACKUP_POLICY=ok'
printf 'ARCHIVE_BACKUP=%s\n' "$ARCHIVE_PATH"
