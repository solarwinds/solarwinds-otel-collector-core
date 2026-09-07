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

# Prints the list of .go and .sh files changed relative to the base branch,
# one path per line (no leading ./), for use by check-licenses.sh and Makefile.Licenses.
#
# REFERENCE: Decision 1 in plan.md — git diff --diff-filter=ACRM against BASE_REF.
#
# WARNING: Only committed changes relative to the base branch are detected.
# Staged, unstaged, and untracked files are excluded even when LICENSE_BASE_REF
# is set. For local repair of uncommitted/new files, commit first or run
# `addlicense -y $YEAR <file>` directly.
#
# Usage: get-changed-license-files.sh [BASE_REF]
# BASE_REF defaults to $LICENSE_BASE_REF then $GITHUB_BASE_REF when not provided as argument.

BASE_REF="${1:-${LICENSE_BASE_REF:-${GITHUB_BASE_REF:-}}}"

if [ -z "$BASE_REF" ]; then
    exit 0
fi

if ! git rev-parse --verify "origin/${BASE_REF}" > /dev/null 2>&1; then
    echo "WARNING: origin/${BASE_REF} does not exist locally; falling back to empty changed set." >&2
    exit 0
fi

# ACRM: Added, Copied, new-name-of-Renamed, Modified — excludes deleted and pre-rename paths.
if ! changed=$(git diff --name-only --diff-filter=ACRM "origin/${BASE_REF}...HEAD" 2>/dev/null); then
    echo "WARNING: git diff failed; falling back to empty changed set." >&2
    exit 0
fi

echo "$changed" | grep -E '\.(go|sh)$' | grep -v generated
