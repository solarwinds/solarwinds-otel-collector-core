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
$origDirPath = $origDir.Path
$platform = "windows"
$coverageDir = Join-Path $origDir "coverage" $platform
New-Item -ItemType Directory -Force -Path $coverageDir | Out-Null

Get-ChildItem -Recurse -Filter 'go.mod' | ForEach-Object {
    Push-Location $_.Directory

    # Keep the full path to the go.mod file for logging and naming
    $modfile = $_.FullName

    $testFiles = Get-ChildItem -Recurse -Filter '*_test.go'
    if ($testFiles.Count -eq 0) {

        # Build needs to be excluded for tools module.
        if ($_.FullName -like '*\tools\go.mod') {
            Write-Host "Skipping build for tools module"
            Pop-Location
            return
        }

        Write-Host "Processing build for module $modfile"
        go build .
        if ($LASTEXITCODE -ne 0) {
            Write-Host "Build failed for module $modfile"
            $hasFailure = $true
        }
    } else {
        Write-Host "Processing tests for module $modfile"

        # Build a safe module name based on the module path so we can produce
        # a per-module coverage file similar to the Linux/Darwin script.
        $modulePath = Split-Path -Parent $modfile
        # Prefer a repository-relative path so the generated filename doesn't
        # contain a drive letter (which can introduce colons and break file
        # name handling). Trim the repo root from the module path if present.
        $relPath = $modulePath
        if ($relPath.StartsWith($origDirPath)) {
            $relPath = $modulePath.Substring($origDirPath.Length).TrimStart('\','/')
        } 
        # Replace backslashes, forward slashes and dots with underscores
        $moduleName = ($relPath -replace '[\\/\.]','_')
        $coverFile = Join-Path $coverageDir ($moduleName + '.out')

        go test -v -coverprofile="$coverFile" -covermode=atomic ./...

        if ($LASTEXITCODE -ne 0) {
            Write-Host "Test suite failed for module $modfile"
            $hasFailure = $true
        }
    }

    Pop-Location
}

# Merge coverage profiles into single coverage.out for Codecov
$mergedFile = Join-Path $coverageDir 'coverage.out'

# Ensure old merged file is removed before starting
Remove-Item -Force -ErrorAction SilentlyContinue $mergedFile

# Collect all coverage fragment files except the final merged file
$coverageFiles = Get-ChildItem -Path $coverageDir -Filter '*.out' -File |
    Where-Object { $_.FullName -ne $mergedFile }

if ($coverageFiles.Count -gt 0) {
    # Build merged lines in memory to ensure we write UTF-8 without BOM
    $outLines = @()
    $outLines += 'mode: atomic'

    foreach ($cf in $coverageFiles) {
        if ($cf.Length -gt 0) {
            $lines = Get-Content -Path $cf.FullName
            if ($lines.Count -gt 0 -and ($lines[0] -match '^mode:')) {
                # Skip header line and normalize each coverage line
                $body = $lines | Select-Object -Skip 1
                foreach ($ln in $body) {
                    if ([string]::IsNullOrWhiteSpace($ln)) { continue }
                    # Normalize Windows backslashes to forward slashes
                    $normalized = $ln -replace '\\','/'
                    # If the line contains the absolute repo path, strip it to make paths repo-relative
                    if ($normalized.StartsWith(($origDirPath -replace '\\','/'))) {
                        $normalized = $normalized.Substring(($origDirPath -replace '\\','/').Length).TrimStart('/','\\')
                    }
                    $outLines += $normalized
                }
            } else {
                Write-Host "Warning: Skipping malformed coverage file: $($cf.Name)"
            }
        } else {
            Write-Host "Warning: Skipping empty coverage file: $($cf.Name)"
        }
    }

    try {
        # Write all lines as UTF8 without BOM to avoid Codecov parser issues
        $utf8NoBom = New-Object System.Text.UTF8Encoding($false)
        [System.IO.File]::WriteAllLines($mergedFile, $outLines, $utf8NoBom)

        # Remove original fragment files
        foreach ($cf in $coverageFiles) {
            Remove-Item -Force -ErrorAction SilentlyContinue $cf.FullName
        }
    } catch {
        Write-Host "Error writing merged coverage file: $($_.Exception.Message)"
        throw
    }
} else {
    Write-Host "No coverage files found in $coverageDir"
    # Print directory listing to aid CI debugging
    Get-ChildItem -Path $coverageDir -Force | ForEach-Object { Write-Host " - $($_.Name) (Length=$($_.Length))" }
}

if ($hasFailure) {
    Write-Host "Some tests failed"
    exit 1
}

if (-not (Test-Path $mergedFile)) {
    Write-Error "Required file '$mergedFile' not found."
    exit 1
}

Write-Host "All tests passed"
exit 0
