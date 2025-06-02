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

$hasFailure = $false

Get-ChildItem -Recurse -Filter 'go.mod' | ForEach-Object {
    Push-Location $_.Directory

    $testFiles = Get-ChildItem -Recurse -Filter '*_test.go'
    if ($testFiles.Count -eq 0) {

        # Build needs to be excluded for tools module.
        if ($_.FullName -like '*\tools\go.mod') {
            Write-Host "Skipping build for tools module"
            Pop-Location
            return
        }

        Write-Host "Processing build for module $($_.FullName)"
        go build .
        if ($LASTEXITCODE -ne 0) {
            Write-Host "Build failed for module $modfile"
            $hasFailure = $true
        }
    } else {
        Write-Host "Processing tests for module $($_.FullName)"
        go test -v ./...

        if ($LASTEXITCODE -ne 0) {
            Write-Host "Test suite failed for module $modfile"
            $hasFailure = $true
        }
    }

    Pop-Location
}

if ($hasFailure) {
    Write-Host "Some tests failed"
    exit 1
}

Write-Host "All tests passed"
exit 0
