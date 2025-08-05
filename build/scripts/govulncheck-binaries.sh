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

# SCRIPT TAKES 1 ARGUMENT, PATH TO BINARIES TO CHECK
# ./govulncheck-binaries.sh "/Users/glutius.maximus/go/bin"

if [ "$#" -ne 1 ]; then
  echo "Error: Missing BINARY PATH parameter. Please provide a value."
  exit 2
fi

# Finds all binaries in the provided directory and runs govulncheck on them
echo "CHECKING ALL BINARIES IN DIRECTORY: $1"
for binary in ${1}/*; do
  if [ -f "$binary" ]; then
    printf "\n%s\n" "$binary"
    # Run govulncheck on the binary
    govulncheck -mode=binary "$binary" || true
  fi
done
