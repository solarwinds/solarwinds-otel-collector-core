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
$origDir = Get-Location
$platform = "windows"
$coverageDir = Join-Path (Join-Path $origDir "coverage") $platform

if (!(Test-Path $coverageDir)) {
    New-Item -ItemType Directory -Path $coverageDir -Force | Out-Null
}

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
            Write-Host "Build failed for module $($_.FullName)"
            $hasFailure = $true
        }
    } else {
        Write-Host "Processing tests for module $($_.FullName)"

        # Generate module name for coverage file
        $modulePath = Split-Path $_.FullName -Parent
        $relativePath = Resolve-Path -Relative $modulePath
        $moduleName = $relativePath -replace '[/\\.]', '_'
        $coverageFile = Join-Path $coverageDir "$moduleName.out"

        go test -v -coverprofile="$coverageFile" -covermode=atomic ./...

        if ($LASTEXITCODE -ne 0) {
            Write-Host "Test suite failed for module $($_.FullName)"
            $hasFailure = $true
        }
    }

    Pop-Location
}

# Merge coverage profiles per OS for Codecov
Write-Host "Starting coverage files merge process..."

# Find all coverage files except the final output file
$coverageFiles = Get-ChildItem -Path $coverageDir -Filter "*.out" -File | Where-Object { $_.Name -ne "coverage.out" }

if ($coverageFiles.Count -eq 0) {
    Write-Host "No coverage files found in $coverageDir"
    return
}

$mergedCoverageFile = Join-Path $coverageDir "coverage.out"
$tempMergedFile = "$mergedCoverageFile.tmp"

try {
    "mode: atomic" | Out-File -FilePath $tempMergedFile -Encoding UTF8 -NoNewline
    "`n" | Out-File -FilePath $tempMergedFile -Append -Encoding UTF8 -NoNewline

    $mergedCount = 0
    foreach ($coverageFile in $coverageFiles) {
        if (!(Test-Path $coverageFile.FullName) -or (Get-Item $coverageFile.FullName).Length -eq 0) {
            Write-Host "Warning: Skipping empty or missing file: $($coverageFile.Name)"
            continue
        }

        try {
            $lines = Get-Content $coverageFile.FullName -Encoding UTF8
            if ($lines.Count -eq 0 -or $lines[0] -notmatch "^mode:") {
                Write-Host "Warning: Skipping malformed coverage file: $($coverageFile.Name)"
                continue
            }

            $lines | Select-Object -Skip 1 | Out-File -FilePath $tempMergedFile -Append -Encoding UTF8
            Write-Host "Merged: $($coverageFile.Name)"
            $mergedCount++
        }
        catch {
            Write-Host "Error processing file $($coverageFile.Name): $($_.Exception.Message)"
        }
    }

    if ($mergedCount -eq 0) {
        Write-Host "Error: No valid coverage files were merged"
        Remove-Item $tempMergedFile -Force -ErrorAction SilentlyContinue
        exit 1
    }

    Move-Item $tempMergedFile $mergedCoverageFile -Force

    foreach ($coverageFile in $coverageFiles) {
        Remove-Item $coverageFile.FullName -Force -ErrorAction SilentlyContinue
    }

    Write-Host "Merged coverage output created at $mergedCoverageFile ($mergedCount files merged)"
}
catch {
    Write-Host "Error during coverage merge: $($_.Exception.Message)"
    Remove-Item $tempMergedFile -Force -ErrorAction SilentlyContinue
    exit 1
}

if ($hasFailure) {
    Write-Host "Some tests failed"
    exit 1
}

Write-Host "All tests passed"
exit 0
