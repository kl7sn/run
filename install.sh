#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")" && pwd)"
install_one() {
  local dest="$1"
  mkdir -p "$(dirname "$dest")"
  rm -rf "$dest"
  ln -s "$ROOT/skills/run" "$dest"
  echo "linked $dest -> $ROOT/skills/run"
}
case "${1:-}" in
  cursor) install_one "$HOME/.cursor/skills/run" ;;
  claude) install_one "$HOME/.claude/skills/run" ;;
  codex)  install_one "$HOME/.codex/skills/run" ;;
  all)
    install_one "$HOME/.cursor/skills/run"
    install_one "$HOME/.claude/skills/run"
    install_one "$HOME/.codex/skills/run"
    ;;
  *)
    echo "Usage: $0 {cursor|claude|codex|all}"
    exit 1
    ;;
esac
