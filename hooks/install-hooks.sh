#!/usr/bin/env bash
# install-hooks.sh — Install Security-Oracle pre-commit hooks across all oracle repos
# Usage: ./install-hooks.sh [repo-name]  (no args = all repos)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HOOK_SRC="$SCRIPT_DIR/pre-commit-secrets"
BASE_DIR="$HOME/repos/github.com/BankCurfew"

ALL_REPOS=(
  BoB-Oracle Dev-Oracle QA-Oracle Researcher-Oracle Writer-Oracle
  Designer-Oracle HR-Oracle AIA-Oracle Data-Oracle Admin-Oracle
  BotDev-Oracle Creator-Oracle Doc-Oracle Editor-Oracle Security-Oracle
)

if [ $# -gt 0 ]; then
  REPOS=("$@")
else
  REPOS=("${ALL_REPOS[@]}")
fi

INSTALLED=0
SKIPPED=0

for repo in "${REPOS[@]}"; do
  HOOK_DIR="$BASE_DIR/$repo/.git/hooks"
  HOOK_DST="$HOOK_DIR/pre-commit"

  if [ ! -d "$BASE_DIR/$repo/.git" ]; then
    echo "⏭️  $repo — not a git repo, skipping"
    ((SKIPPED++))
    continue
  fi

  mkdir -p "$HOOK_DIR"

  if [ -f "$HOOK_DST" ] && ! grep -q "Security-Oracle" "$HOOK_DST" 2>/dev/null; then
    # Existing hook that's not ours — append
    echo "" >> "$HOOK_DST"
    echo "# Security-Oracle secrets check (appended)" >> "$HOOK_DST"
    echo "\"$HOOK_SRC\" || exit 1" >> "$HOOK_DST"
    echo "✅ $repo — appended to existing pre-commit hook"
  else
    cp "$HOOK_SRC" "$HOOK_DST"
    chmod +x "$HOOK_DST"
    echo "✅ $repo — installed pre-commit hook"
  fi
  ((INSTALLED++))
done

echo ""
echo "Done: $INSTALLED installed, $SKIPPED skipped"
