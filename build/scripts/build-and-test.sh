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
    go test -v ./...
    if [[ $? != 0 ]]; then
        echo "Test suite failed for module $modfile"
        HAS_FAILURE=true
    fi
    fi

    cd "$ORIG_DIR"
done

if [ "$HAS_FAILURE" = true ]; then
    echo "Some tests failed"
    exit 1
fi

echo "All tests passed"
exit 0