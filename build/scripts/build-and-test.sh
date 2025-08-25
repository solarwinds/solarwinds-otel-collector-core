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

set +e

HAS_FAILURE=false
ORIG_DIR=$(pwd)
GO_MOD_FILES=$(find . -name go.mod)

OS=$(uname -s)
case "$OS" in
    Linux*)     PLATFORM="linux";;
    Darwin*)    PLATFORM="darwin";;
    *)          PLATFORM="unknown";;
esac

COVERAGE_DIR="$ORIG_DIR/coverage/$PLATFORM"
mkdir -p "$COVERAGE_DIR"

for modfile in $GO_MOD_FILES; do
    cd $(dirname "$modfile")

    count=$(find . -name '*_test.go' | wc -l)
    if [[ "$count" -eq 0 ]]; then

      # Build needs to be excluded for tools module.
      if [[ "$modfile" == */tools/go.mod ]]; then
        echo "Skipping build for tools module"
        cd "$ORIG_DIR"
        continue
      fi

      echo "Processing build for module $modfile"
      go build .

      if [[ $? != 0 ]]; then
        echo "Build failed for module $modfile"
        HAS_FAILURE=true
      fi
      else
        echo "Processing tests for module $modfile"
        MODULE_PATH=$(dirname "$modfile")
        MODULE_NAME=$(echo "$MODULE_PATH" | sed 's/[\/\.]/_/g')
        go test -v -coverprofile="${COVERAGE_DIR}/${MODULE_NAME}.out" -covermode=atomic ./...

        if [[ $? != 0 ]]; then
          echo "Test suite failed for module $modfile"
          HAS_FAILURE=true
        fi
      fi

    cd "$ORIG_DIR"
done

# Merge coverage profiles per OS for Codecov
echo "Starting coverage files merge process..."
# Find coverage files but exclude the final output file
COVERAGE_FILES=$(find "$COVERAGE_DIR" -name "*.out" -type f ! -name "coverage.out" 2>/dev/null)

if [[ -n "$COVERAGE_FILES" ]]; then
    # Remove any existing merged coverage file first
    rm -f "$COVERAGE_DIR/coverage.out"

    echo "mode: atomic" > "$COVERAGE_DIR/coverage.out"

    while IFS= read -r -d '' coverage_file; do
        echo "Processing coverage file: $coverage_file"
        if [[ -f "$coverage_file" && -s "$coverage_file" ]]; then
            if head -n 1 "$coverage_file" | grep -q "^mode:"; then
                tail -n +2 "$coverage_file" >> "$COVERAGE_DIR/coverage.out"
                echo "Successfully merged: $coverage_file"
            else
                echo "Warning: Skipping malformed coverage file: $coverage_file"
            fi
        else
            echo "Warning: Skipping empty or missing coverage file: $coverage_file"
        fi
    done < <(find "$COVERAGE_DIR" -name "*.out" -type f ! -name "coverage.out" -print0 2>/dev/null)

    echo "Merged coverage output created at $COVERAGE_DIR/coverage.out"

    # Verify the merged file
    if [[ -f "$COVERAGE_DIR/coverage.out" && -s "$COVERAGE_DIR/coverage.out" ]]; then
        # Clean up individual coverage files after successful merge
        while IFS= read -r -d '' coverage_file; do
            if [[ "$coverage_file" != "$COVERAGE_DIR/coverage.out" ]]; then
                rm -f "$coverage_file"
            fi
        done < <(find "$COVERAGE_DIR" -name "*.out" -type f -print0 2>/dev/null)
        echo "Cleanup completed - only coverage.out remains"
    else
        echo "Error: Merged coverage file is empty or missing"
        exit 1
    fi
else
    echo "No coverage files found in $COVERAGE_DIR"
fi

if [ "$HAS_FAILURE" = true ]; then
    echo "Some tests failed"
    exit 1
fi

echo "All tests passed"
exit 0
