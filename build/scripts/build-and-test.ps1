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

############################################################
# Windows build & test with coverage aggregation
# Mirrors logic from build-and-test.sh (Linux/Darwin) but
# actively merges coverage profiles into a single file
# coverage/windows/coverage.out so Codecov upload succeeds.
############################################################

$hasFailure = $false

$origDir = Get-Location
$platform = "windows"
$coverageDir = Join-Path $origDir "coverage" | Join-Path -ChildPath $platform
New-Item -ItemType Directory -Force -Path $coverageDir | Out-Null

# Collect all go.mod files
Get-ChildItem -Recurse -Filter 'go.mod' | ForEach-Object {
    Push-Location $_.Directory

    $modPath = $_.FullName
    $testFiles = Get-ChildItem -Recurse -Filter '*_test.go'
    if ($testFiles.Count -eq 0) {

        # Build needs to be excluded for tools module.
        if ($modPath -like '*\tools\go.mod') {
            Write-Host "Skipping build for tools module"
            Pop-Location
            return
        }

    Write-Host "Processing build for module $modPath"
        go build .
        if ($LASTEXITCODE -ne 0) {
            Write-Host "Build failed for module $modPath"
            $hasFailure = $true
        }
    } else {
    Write-Host "Processing tests for module $modPath"
        # Derive a relative module name safe for Windows filenames (remove drive colon)
        $fullModulePath = $_.Directory.FullName
        if ($fullModulePath.StartsWith($origDir, [System.StringComparison]::OrdinalIgnoreCase)) {
            $relativePart = $fullModulePath.Substring($origDir.Length)
        } else {
            $relativePart = $fullModulePath
        }
        $relativePart = $relativePart.TrimStart('\\')
        if ([string]::IsNullOrWhiteSpace($relativePart)) { $relativePart = 'root' }
        # Replace invalid/special chars (: \ / .) with underscore
        $moduleName = ($relativePart -replace '[:\\/.]', '_')
        $coverFile = Join-Path $coverageDir "$moduleName.out"
    go test -v -coverprofile "$coverFile" -covermode atomic ./...

        if ($LASTEXITCODE -ne 0) {
            Write-Host "Test suite failed for module $modPath"
            $hasFailure = $true
        }
    }

    Pop-Location
}

# Merge coverage profiles into single coverage.out for Codecov
Write-Host "Starting coverage files merge process..."
$mergedFile = Join-Path $coverageDir 'coverage.out'
Remove-Item -Force -ErrorAction SilentlyContinue $mergedFile

$coverageFiles = Get-ChildItem -Path $coverageDir -Filter '*.out' | Where-Object { $_.FullName -ne $mergedFile }
if ($coverageFiles.Count -gt 0) {
    "mode: atomic" | Out-File -FilePath $mergedFile -Encoding utf8
    foreach ($cf in $coverageFiles) {
        if ($cf.Length -gt 0) {
            $firstLine = Get-Content -Path $cf.FullName -TotalCount 1
            if ($firstLine -match '^mode:') {
                (Get-Content -Path $cf.FullName | Select-Object -Skip 1) | Add-Content -Path $mergedFile
            }
        }
    }
    if (-not ((Test-Path $mergedFile) -and ((Get-Item $mergedFile).Length -gt 0))) {
        $hasFailure = $true
    }
} else {
    # Match linux script behavior (no extra message beyond initial line)
}

if ($hasFailure) {
    Write-Host "Some tests failed"
    exit 1
}

if (-not (Test-Path $mergedFile)) { }

Write-Host "All tests passed"
exit 0
