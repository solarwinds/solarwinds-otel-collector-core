#!/bin/bash
# Copyright 2026 SolarWinds Worldwide, LLC. All rights reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# Two-mode license check:
#   strict — PR-changed files must carry exact header with $LICENSE_YEAR
#   loose  — untouched files must carry any copyright notice (year-agnostic)
#
# WARNING: loose mode only verifies that *some* copyright string appears in the
# first 1000 bytes (addlicense -check behaviour). It does not validate that the
# header is the correct SolarWinds Apache 2.0 template or that the year is current.
# This is an intentional trade-off: strict year enforcement is a PR-context concern.

EXPECTED_GO_LICENSE_HEADER=$1
EXPECTED_SHELL_LICENSE_HEADER=$2

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ADDLICENSE="${ADDLICENSE:-${SCRIPT_DIR}/../../.tools/addlicense}"
LICENSE_YEAR="${LICENSE_YEAR:-$(date +%Y)}"

ALL_SRC=$(find "$(pwd)" \( -name "*.go" -o -name "*.sh" \) \
    -not -path '*generated*' \
    -type f | sort)

# Build changed set (paths without leading ./ to match git diff output format).
CHANGED_SET=$("${SCRIPT_DIR}/get-changed-license-files.sh")

is_changed() {
    local file="$1"
    # Strip leading ./ from find output before comparing.
    local normalized="${file#$(pwd)/}"
    echo "$CHANGED_SET" | grep -qxF "$normalized"
}

render_template() {
    local template="$1"
    local rendered
    rendered=$(mktemp)
    sed "s/{{YEAR}}/$LICENSE_YEAR/g" "$template" > "$rendered"
    echo "$rendered"
}

strict_check_go() {
    local f="$1"
    local rendered_template="$2"
    local header_lines
    header_lines=$(wc -l < "$rendered_template")
    if ! diff -q <(head -n "$header_lines" "$f") "$rendered_template" > /dev/null; then
        echo "Missing or incorrect license header in Go file!"
        echo "Diff for ${f#$(pwd)/}:"
        diff --label="${f#$(pwd)/}" -u <(head -n "$header_lines" "$f") "$rendered_template"
        return 1
    fi
    return 0
}

strict_check_sh() {
    local f="$1"
    local rendered_template="$2"
    local header_lines
    header_lines=$(wc -l < "$rendered_template")
    # Skip shebang line when present so it does not shift the header comparison.
    if ! diff -q <(tail -n +2 "$f" | head -n "$header_lines") "$rendered_template" > /dev/null; then
        echo "Missing or incorrect license header in shell file!"
        echo "Diff for ${f#$(pwd)/}:"
        diff --label="${f#$(pwd)/}" -u <(tail -n +2 "$f" | head -n "$header_lines") "$rendered_template"
        return 1
    fi
    return 0
}

RENDERED_GO=$(render_template "$EXPECTED_GO_LICENSE_HEADER")
RENDERED_SHELL=$(render_template "$EXPECTED_SHELL_LICENSE_HEADER")

RC=0
UNTOUCHED_LIST=()

for f in $ALL_SRC; do
    if is_changed "$f"; then
        case "$f" in
            *.go)
                strict_check_go "$f" "$RENDERED_GO" || RC=1
                ;;
            *.sh)
                strict_check_sh "$f" "$RENDERED_SHELL" || RC=1
                ;;
        esac
    else
        UNTOUCHED_LIST+=("$f")
    fi
done

# Loose check: batch invocation — addlicense -check reports all failures before exiting.
if [ "${#UNTOUCHED_LIST[@]}" -gt 0 ]; then
    if ! "$ADDLICENSE" -check "${UNTOUCHED_LIST[@]}" 2>&1; then
        RC=1
    fi
fi

rm -f "$RENDERED_GO" "$RENDERED_SHELL"
exit $RC
