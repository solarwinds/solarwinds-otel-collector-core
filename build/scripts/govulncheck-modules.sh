#!/bin/bash
# Copyright 2025 SolarWinds Worldwide, LLC. All rights reserved.
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

# SCRIPT TAKES NO ARGUMENTS
# ./govulncheck-modules.sh

# Files to exclude from govulncheck
excludeDirs=(
  "./internal/e2e"
  "./submodules/solarwinds-otel-collector-core/internal/tools"
)

pruneExpr=""
for dir in "${excludeDirs[@]}"; do
  pruneExpr="$pruneExpr -path \"$dir\" -prune -o"
done

# Find all go.mod files and run govulncheck in their directories
echo "CHECKING ALL MODULES EXCEPT EXCLUDED DIRECTORIES: ${excludeDirs[*]}"
eval find . $pruneExpr -name "go.mod" -print0 | while IFS= read -r -d '' modfile; do
    dir=$(dirname "$modfile")
    printf "\n%s\n" "$dir"
    # Run govulncheck in the module directory
    govulncheck -C ${dir} -mode=source -scan=module || true
done