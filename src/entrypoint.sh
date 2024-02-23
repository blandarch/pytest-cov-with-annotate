#!/bin/bash
# If a command fails, exit
set -e
# Treat unset variables as error
set -u
# Fail if command fails
set -o pipefail
# Print commands and their arguments
set -x


# We need GITHUB_TOKEN to operate
if [[ -z "${{secrets.GITHUB_TOKEN}}" ]]; then
	echo "GITHUB_TOKEN should be set."
	exit 1
fi


main() {
    curl -sSL -H  "Accept: application/vnd.github.v3+json" -H "Authorization: token ${{secrets.GITHUB_TOKEN}}" \
    "${{secrets.GITHUB_API_URL}}/repos/${{secrets.GITHUB_REPOSITORY}}/pulls?head=${{secrets.GITHUB_REPOSITORY_OWNER}}:${{secrets.GITHUB_REF##*/}}" > pull_request.json

    PR_BASE_SHA=$(jq -r '.[0].base.sha' < pull_request.json)
    PR_HEAD_SHA=$(jq -r '.[0].head.sha' < pull_request.json)

    export PR_BASE_SHA
    export PR_HEAD_SHA

    changed_files=$(git diff --name-only --diff-filter=AM "$PR_BASE_SHA" "$PR_HEAD_SHA" | grep '\.py$' | tr '\n' ' ')

    python3 -m coverage run -m pytest $changed_files
    python3 -m coverage json
    python3 /src/main.py
    if [-f coverage.json]; then rm coverage.json; fi
}

main "$@"
