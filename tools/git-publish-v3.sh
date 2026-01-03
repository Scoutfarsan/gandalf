#!/usr/bin/env bash
set -euo pipefail

REPO_SSH_DEFAULT="git@github.com:Scoutfarsan/gandalf.git"
REMOTE_NAME="${REMOTE_NAME:-origin}"
REMOTE_URL="${REMOTE_URL:-$REPO_SSH_DEFAULT}"
TAG="${TAG:-v3.0}"

say() { echo "[git-v3] $*"; }

cd "$(dirname "$0")/.."  # repo root

if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  echo "[git-v3] ERROR: Kör detta inne i ett git-repo." >&2
  exit 2
fi

if [[ -n "$(git status --porcelain)" ]]; then
  echo "[git-v3] ERROR: Working tree är inte clean. Commit/stasha först." >&2
  git status --porcelain
  exit 2
fi

name="$(git config --global user.name || true)"
mail="$(git config --global user.email || true)"
if [[ -z "$name" || -z "$mail" ]]; then
  echo "[git-v3] ERROR: Saknar git user.name/user.email. Sätt globalt och kör igen." >&2
  exit 2
fi

if git remote get-url "$REMOTE_NAME" >/dev/null 2>&1; then
  say "Remote finns: $REMOTE_NAME -> $(git remote get-url "$REMOTE_NAME")"
else
  say "Skapar remote: $REMOTE_NAME -> $REMOTE_URL"
  git remote add "$REMOTE_NAME" "$REMOTE_URL"
fi

say "Fetch $REMOTE_NAME/main"
git fetch "$REMOTE_NAME" main --tags || git fetch "$REMOTE_NAME" --tags

say "Skapar/byter till integrationsbranch från $REMOTE_NAME/main"
git checkout -B integrate-v3 "$REMOTE_NAME/main"

say "Arkiverar remote-main innehåll till /old (om inte redan gjort)"
if [[ -d old ]]; then
  say "old/ finns redan. Skippar arkivering."
else
  mkdir -p old
  while IFS= read -r f; do
    [[ "$f" == old/* ]] && continue
    mkdir -p "old/$(dirname "$f")"
    git mv "$f" "old/$f"
  done < <(git ls-tree -r --name-only HEAD)
  git commit -m "chore: archive previous repo content into /old"
fi

say "Merge: tar in v3-innehållet från din lokala branch v3-local"
git merge v3-local --allow-unrelated-histories -m "feat(v3): baseline ops + keep legacy under /old"

say "Taggar release: $TAG (om den saknas)"
if git rev-parse "$TAG" >/dev/null 2>&1; then
  say "Tag $TAG finns redan. Skippar."
else
  git tag -a "$TAG" -m "Gandalf $TAG - v3.0 baseline (ops) + legacy in /old"
fi

say "Byter branchnamn till main och pushar"
git branch -M main
git push -u "$REMOTE_NAME" main --follow-tags

say "KLAR ✅  main uppdaterad + tag $TAG pushad."
