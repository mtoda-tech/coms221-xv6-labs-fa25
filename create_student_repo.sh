#!/usr/bin/env bash
#
# create_student_repo.sh
#
# Run this *inside the cloned starter repository*.
# Requirements:
#   - GitHub CLI (gh): https://cli.github.com  ->  gh auth login
#   - git
#
# What it does:
#   1) Creates a *private* repo under the student's GitHub account.
#   2) Pushes ALL branches, tags, and refs from this starter repo to that new private repo.
#   3) Adds the instructor as a collaborator with push (write) permission.
#   4) Clones the new private repo as a sibling directory named with "-private".
#
# -------------------------------------------------------------

set -euo pipefail

# ========== EDIT THIS BEFORE YOU DISTRIBUTE ==================
INSTRUCTOR_GH="jsissler"   # <--- change me
# =============================================================

red()    { printf "\033[31m%s\033[0m\n" "$*" >&2; }
green()  { printf "\033[32m%s\033[0m\n" "$*"; }
yellow() { printf "\033[33m%s\033[0m\n" "$*"; }

need_cmd() {
  if ! command -v "$1" >/dev/null 2>&1; then
    red "Error: '$1' is required but not installed."
    exit 1
  fi
}

# --- Pre-flight checks -------------------------------------------------------
need_cmd git
need_cmd gh

if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  red "This script must be run inside a git repository (the starter repo you cloned)."
  exit 1
fi

if ! gh auth status >/dev/null 2>&1; then
  red "GitHub CLI is not authenticated. Run: gh auth login"
  exit 1
fi

# --- Gather info -------------------------------------------------------------
STUDENT_LOGIN_DEFAULT="$(gh api user -q .login 2>/dev/null || echo "")"

REPO_ROOT="$(git rev-parse --show-toplevel)"
PARENT_DIR="$(dirname "$REPO_ROOT")"
STARTER_BASENAME="$(basename "$REPO_ROOT")"
DEFAULT_NEW_REPO_NAME="${STARTER_BASENAME}-private"
TARGET_DIR="${PARENT_DIR}/${DEFAULT_NEW_REPO_NAME}"

echo
yellow "=== Configure your private repository ==="
read -rp "Your GitHub username [${STUDENT_LOGIN_DEFAULT}]: " STUDENT_LOGIN
STUDENT_LOGIN="${STUDENT_LOGIN:-$STUDENT_LOGIN_DEFAULT}"
if [[ -z "$STUDENT_LOGIN" ]]; then
  red "GitHub username cannot be empty."
  exit 1
fi

read -rp "Name for your PRIVATE repo [${DEFAULT_NEW_REPO_NAME}]: " NEW_REPO_NAME
NEW_REPO_NAME="${NEW_REPO_NAME:-$DEFAULT_NEW_REPO_NAME}"
TARGET_FULL="${STUDENT_LOGIN}/${NEW_REPO_NAME}"

# Recompute local target dir in case they overrode the name
TARGET_DIR="${PARENT_DIR}/${NEW_REPO_NAME}"

read -rp "Instructor's GitHub username [${INSTRUCTOR_GH}]: " INSTRUCTOR_INPUT
INSTRUCTOR_GH="${INSTRUCTOR_INPUT:-$INSTRUCTOR_GH}"

echo
yellow "You are about to create: https://github.com/${TARGET_FULL} (private)"
read -rp "Continue? [y/N]: " CONFIRM
CONFIRM="${CONFIRM:-N}"
if [[ ! "$CONFIRM" =~ ^[Yy]$ ]]; then
  red "Aborted."
  exit 1
fi

# --- Create the repo ---------------------------------------------------------
green "Creating private repository ${TARGET_FULL} ..."
if gh repo view "$TARGET_FULL" >/dev/null 2>&1; then
  yellow "Repo ${TARGET_FULL} already exists. Will reuse it."
else
  gh repo create "$TARGET_FULL" --private --description "Private labs for ${STUDENT_LOGIN}" --confirm >/dev/null
  green "Created."
fi

# --- Push EVERYTHING to the new repo ----------------------------------------
# 1) Ensure we have *all* remote refs locally.
#    We'll assume the current 'origin' is the public starter. If not, we still fetch --all.
yellow "Fetching all branches and tags from all remotes..."
git fetch --all --prune --tags

# 2) Add a temporary remote to the new private repo.
CLONE_URL="$(gh api "repos/${TARGET_FULL}" -q .clone_url)"
STUDENT_REMOTE="student"
if git remote get-url "$STUDENT_REMOTE" >/dev/null 2>&1; then
  git remote remove "$STUDENT_REMOTE"
fi
git remote add "$STUDENT_REMOTE" "$CLONE_URL"

# 3) Mirror push (branches, tags, all refs)
green "Pushing ALL refs (branches & tags) to the private repo..."
git push --mirror "$STUDENT_REMOTE"

# 4) (Optional) Remove the temporary remote to keep the local repo clean.
git remote remove "$STUDENT_REMOTE"

# --- Add instructor as collaborator -----------------------------------------
green "Adding instructor (${INSTRUCTOR_GH}) as collaborator with 'push' permission..."
gh api \
  -X PUT \
  -H "Accept: application/vnd.github+json" \
  "repos/${TARGET_FULL}/collaborators/${INSTRUCTOR_GH}" \
  -f permission=push >/dev/null

# --- Clone the new private repo next to the current directory ----------------
if [[ -e "$TARGET_DIR" ]]; then
  yellow "Directory '${TARGET_DIR}' already exists. Skipping clone."
else
  green "Cloning the new private repo to: ${TARGET_DIR}"
  gh repo clone "${TARGET_FULL}" "${TARGET_DIR}" >/dev/null
fi

green "Done!"

cat <<EOF

=============================================================
Success!

- Your private repo: https://github.com/${TARGET_FULL}
- Local clone created at: ${TARGET_DIR}
- Instructor (${INSTRUCTOR_GH}) has been added as a collaborator.
- You can now start working on the correct lab branch, e.g.:

    cd "${TARGET_DIR}"
    git checkout util

Don't forget to commit & push your work regularly:

    git add .
    git commit -m "util lab progress"
    git push

Preferrably, you should use the GitHub Desktop application to manage your repository.

=============================================================
EOF

