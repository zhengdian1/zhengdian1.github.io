#!/usr/bin/env bash
set -euo pipefail

repo_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
cd -- "$repo_dir"

export GIT_TERMINAL_PROMPT=0

if [[ "$(git branch --show-current)" != "main" ]]; then
    printf 'Error: switch to main before uploading.\n' >&2
    exit 1
fi

if [[ ! -f index.html ]]; then
    printf 'Error: index.html is missing.\n' >&2
    exit 1
fi

# Do not include files staged by another workflow in the page commit.
while IFS= read -r -d '' staged_file; do
    if [[ "$staged_file" != "index.html" ]]; then
        printf 'Error: another file is staged: %s\nCommit or unstage it first.\n' "$staged_file" >&2
        exit 1
    fi
done < <(git diff --cached --name-only -z)

git add -- index.html
if ! git diff --cached --quiet -- index.html; then
    git commit -m "${1:-Update homepage}" -- index.html
else
    printf 'index.html has no new changes; uploading existing commits.\n'
fi

if ! git -c http.lowSpeedLimit=1 -c http.lowSpeedTime=30 \
    push origin HEAD:refs/heads/main; then
    printf '\nUpload failed. The local commit is preserved.\nCheck the GitHub credentials, proxy, or remote changes shown above, then rerun this script.\n' >&2
    exit 1
fi

printf '\nUploaded successfully: https://github.com/zhengdian1/zhengdian1.github.io\n'
printf 'Website: https://zhengdian1.github.io/ (GitHub Pages may need time to deploy.)\n'
