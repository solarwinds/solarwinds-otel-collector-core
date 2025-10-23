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

if [ "$#" -lt 1 ]; then
    echo "Usage: $0 <version> <go.mod package sources to update (comma-separated)> (optional)"
    exit 1
fi
VERSION=$1
IFS=',' read -ra PACKAGE_SOURCES_TO_UPDATE <<< "$2"
SRC_ROOT=$(pwd)

PACKAGE_SOURCES_TO_UPDATE+=(
    "github.com/solarwinds/solarwinds-otel-collector-core"
    "github.com/solarwinds/solarwinds-otel-collector-contrib"
    "github.com/solarwinds/solarwinds-otel-collector-releases"
)

# Update CHANGELOG.md
CHANGELOG_FILE="$SRC_ROOT/CHANGELOG.md"
if [ ! -f "$CHANGELOG_FILE" ]; then
    echo "CHANGELOG.md not found!"; exit 1
fi
if ! grep -q "## v$VERSION" "$CHANGELOG_FILE"; then
    # Capture current vNext block (lines after '## vNext' up to first blank line)
    VNEXT_CONTENT=$(awk ' $0=="## vNext" {capture=1; next} capture && NF==0 {exit} capture {print} ' "$CHANGELOG_FILE")
    if [ -z "$VNEXT_CONTENT" ]; then
        # vNext was empty -> insert version section with placeholder
        perl -pi -e "s/^## vNext/## vNext\n\n## v$VERSION\n- No changes/" "$CHANGELOG_FILE"
        echo "CHANGELOG.md updated with version v$VERSION (placeholder added as vNext was empty)"
    else
        # vNext had content -> just create empty version section (content stays in vNext for future edits)
        perl -pi -e "s/^## vNext/## vNext\n\n## v$VERSION/" "$CHANGELOG_FILE"
        echo "CHANGELOG.md updated with version v$VERSION"
    fi
else
    echo "CHANGELOG.md already contains 'v$VERSION', no update made."
fi

if [ $PACKAGE_SOURCES_TO_UPDATE ]; then
    ALL_GO_MOD=$(find $SRC_ROOT -name "go.mod" -type f | sort)

    # First pass: check Go version consistency
    UNIQUE_GO_VERSION=""
    for f in $ALL_GO_MOD; do
        ver=$(grep '^go [0-9]\+\.[0-9]\+' "$f" | awk '{print $2}')
        if [ -n "$ver" ]; then
            if [ -z "$UNIQUE_GO_VERSION" ]; then
                UNIQUE_GO_VERSION="$ver"
            elif [ "$ver" != "$UNIQUE_GO_VERSION" ]; then
                echo -e "\033[0;31m❌ Error: Multiple Go versions found! '$UNIQUE_GO_VERSION' and '$ver' (in $f)\033[0m"
                exit 1
            fi
        fi
    done

    # Second pass: update package sources and run go mod tidy
    for f in $ALL_GO_MOD; do
        for package_source in "${PACKAGE_SOURCES_TO_UPDATE[@]}"; do
            perl -pi -e "s|^(\s+$package_source/[^ ]*) v[0-9]+\.[0-9]+\.[0-9]+(\s+// indirect)?$|\1 v$VERSION\2|" "$f"
            echo "References to '$package_source' in ${f#$(pwd)/} updated with version v$VERSION"
        done
        (cd "$(dirname "$f")" && go mod tidy)
    done
fi


# update pkg\version\version.go to set the actual release version
GO_VERSION_FILE="$SRC_ROOT/pkg/version/version.go"
if [ ! -f "$GO_VERSION_FILE" ]; then
    echo -e "\033[0;31m❌ version.go not found!\033[0m"
    exit 1
fi
perl -pi -e "s|^(const Version =) \"[0-9]+\.[0-9]+\.[0-9]+\"$|\1 \"$VERSION\"|" "$GO_VERSION_FILE"
echo "Version.go updated with version $VERSION"
