#!/bin/sh
set -eu

mode="${1:---tracked}"
case "$mode" in
  --tracked)
    tracked_files=$(git ls-files)
    grep_command="git grep -n -I -E"
    ;;
  --staged)
    tracked_files=$(git diff --cached --name-only --diff-filter=ACMR)
    grep_command="git grep --cached -n -I -E"
    ;;
  *)
    echo "Usage: $0 [--tracked|--staged]" >&2
    exit 2
    ;;
esac

blocked_files=$(printf '%s\n' "$tracked_files" | grep -Ei '\.(xlsx|xls|xlsm|csv|tsv|numbers|sqlite|sqlite3|db|parquet|feather)$' || true)
if [ -n "$blocked_files" ]; then
  echo "Blocked business-data file type detected:" >&2
  printf '%s\n' "$blocked_files" >&2
  exit 1
fi

pattern='小程序|一级订单归属|商户类型|最终支付GMV|最终发货采购价|最终发货毛利率'
if sh -c "$grep_command \"$pattern\" -- Gridnote/Office" >/dev/null 2>&1; then
  echo "Potential production-report field detected in Gridnote/Office." >&2
  exit 1
fi

echo "Repository hygiene check passed."
