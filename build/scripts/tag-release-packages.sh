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

FOLDERS=($1)
VERSION_TAG="$2"
EXCLUDED_FOLDERS=($3)

for folder in "${FOLDERS[@]}"; do
    for package_folder in $folder/*/; do
        # Skip if package_folder is in EXCLUDED_FOLDERS
        if [ "${#EXCLUDED_FOLDERS[@]}" -gt 0 ]; then
            for excluded in "${EXCLUDED_FOLDERS[@]}"; do
                if [ "$package_folder" = "$excluded" ]; then
                    echo "Skipped $excluded"
                    continue 2
                fi
            done
        fi
        if [ -f "$package_folder/go.mod" ]; then
            git tag "${package_folder#./}$VERSION_TAG"
            git push origin "${package_folder#./}$VERSION_TAG"
            echo "Pushed tag ${package_folder#./}$VERSION_TAG"
        fi
    done
done
