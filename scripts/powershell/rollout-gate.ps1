#!/usr/bin/env pwsh
# rollout-gate.ps1 — Self-gating state check shared by every rollout hook.
#
# Usage:
#   scripts/powershell/rollout-gate.ps1 [-Mode default|analyze]
#
# Resolves the current feature directory, searches for the literal
# "## Delivery Considerations" marker heading (spec.md only in "default"
# mode; spec.md, then plan.md, then tasks.md, first match wins, in
# "analyze" mode), folds in the resolved `hooks.enabled` configuration
# toggle as an override, and prints a fixed four-line machine-readable
# result to stdout, always in this order:
#
#   hasFlags=<true|false>
#   flags=<comma-separated candidate flag names, or empty>
#   source=<spec.md|plan.md|tasks.md|(empty)>
#   hooksEnabled=<true|false>
#
# Diagnostic messages go to stderr only — stdout always carries exactly
# the four lines above.
#
# Exit codes:
#   0 = rollout (marker present and hooks enabled)
#   1 = no rollout (marker absent, or hooks disabled)
#   2 = diagnostic: feature directory could not be resolved (fail-safe,
#       treated identically to exit 1 by callers that don't care to
#       distinguish it)
#
# See specs/003-rollout-gate-mechanism/contracts/rollout-gate-cli.md for
# the full contract both this script and rollout-gate.sh must satisfy
# identically.

[CmdletBinding()]
param(
    [ValidateSet("default", "analyze")]
    [string]$Mode = "default"
)

$ErrorActionPreference = "Stop"

function Write-GateResult {
    param(
        [string]$HasFlags,
        [string]$Flags,
        [string]$Source,
        [string]$HooksEnabled
    )
    Write-Output "hasFlags=$HasFlags"
    Write-Output "flags=$Flags"
    Write-Output "source=$Source"
    Write-Output "hooksEnabled=$HooksEnabled"
}

# --- Locate the Spec Kit project root by walking upward for a .specify/ dir ---
function Find-SpecifyRoot {
    $dir = Get-Location | Select-Object -ExpandProperty Path
    while ($true) {
        if (Test-Path -LiteralPath (Join-Path $dir ".specify") -PathType Container) {
            return $dir
        }
        $parent = Split-Path -Path $dir -Parent
        if ([string]::IsNullOrEmpty($parent) -or $parent -eq $dir) {
            return $null
        }
        $dir = $parent
    }
}

$specifyRoot = Find-SpecifyRoot

# --- Read feature.json's feature_directory key ---
function Read-FeatureJsonDir {
    param([string]$FeatureJsonPath)
    if (-not (Test-Path -LiteralPath $FeatureJsonPath -PathType Leaf)) {
        return $null
    }
    try {
        $json = Get-Content -LiteralPath $FeatureJsonPath -Raw | ConvertFrom-Json
        if ($json.feature_directory) {
            return [string]$json.feature_directory
        }
    } catch {
        return $null
    }
    return $null
}

# --- Resolve the feature directory ---
$featureDir = $null
$resolved = $false

$envFeatureDir = $env:SPECIFY_FEATURE_DIRECTORY
if (-not [string]::IsNullOrEmpty($envFeatureDir)) {
    if ([System.IO.Path]::IsPathRooted($envFeatureDir)) {
        $featureDir = $envFeatureDir
    } elseif ($specifyRoot) {
        $featureDir = Join-Path $specifyRoot $envFeatureDir
    } else {
        $featureDir = $envFeatureDir
    }
    $resolved = $true
} elseif ($specifyRoot) {
    $featureJsonPath = Join-Path $specifyRoot ".specify/feature.json"
    $relDir = Read-FeatureJsonDir -FeatureJsonPath $featureJsonPath
    if (-not [string]::IsNullOrEmpty($relDir)) {
        if ([System.IO.Path]::IsPathRooted($relDir)) {
            $featureDir = $relDir
        } else {
            $featureDir = Join-Path $specifyRoot $relDir
        }
        $resolved = $true
    }
}

if (-not $resolved) {
    [Console]::Error.WriteLine("rollout-gate: could not resolve the current feature directory (no SPECIFY_FEATURE_DIRECTORY env var and no readable .specify/feature.json)")
    Write-GateResult -HasFlags "false" -Flags "" -Source "" -HooksEnabled "true"
    exit 2
}

# --- Resolve hooks.enabled: extension defaults -> project config -> local override -> env var ---
# Each YAML layer is read with a small, indentation-aware line scan for a
# `hooks:` key (at whatever nesting depth it appears in that file) followed
# by an `enabled:` key indented under it — no YAML library required.
function Get-IndentWidth {
    param([string]$Line)
    $i = 0
    while ($i -lt $Line.Length -and $Line[$i] -eq ' ') {
        $i++
    }
    return $i
}

function Extract-HooksEnabled {
    param([string]$FilePath)
    if (-not (Test-Path -LiteralPath $FilePath -PathType Leaf)) {
        return $null
    }
    $lines = Get-Content -LiteralPath $FilePath -ErrorAction SilentlyContinue
    if (-not $lines) {
        return $null
    }
    $inHooks = $false
    $hooksIndent = 0
    foreach ($line in $lines) {
        if ($line -match '^[ \t]*hooks:[ \t]*$') {
            if (-not $inHooks) {
                $hooksIndent = Get-IndentWidth -Line $line
                $inHooks = $true
            }
            continue
        }
        if ($inHooks) {
            if ($line -match '^[ \t]*$') {
                continue
            }
            $curIndent = Get-IndentWidth -Line $line
            if ($curIndent -le $hooksIndent) {
                $inHooks = $false
                continue
            }
            if ($line -match '^[ \t]*enabled:[ \t]*(.*)$') {
                $val = $Matches[1]
                $val = ($val -replace '[ \t]*#.*$', '').Trim()
                if (-not [string]::IsNullOrEmpty($val)) {
                    return $val
                }
            }
        }
    }
    return $null
}

function Normalize-Bool {
    param([string]$Value)
    switch ($Value.ToLowerInvariant()) {
        "true" { return "true" }
        "1" { return "true" }
        "yes" { return "true" }
        "false" { return "false" }
        "0" { return "false" }
        "no" { return "false" }
        default { return $null }
    }
}

$hooksEnabled = "true"

if ($specifyRoot) {
    $layerFiles = @(
        (Join-Path $specifyRoot ".specify/extensions/rollout/extension.yml"),
        (Join-Path $specifyRoot ".specify/extensions/rollout/rollout-config.yml"),
        (Join-Path $specifyRoot ".specify/extensions/rollout/local-config.yml")
    )
    foreach ($layerFile in $layerFiles) {
        $raw = Extract-HooksEnabled -FilePath $layerFile
        if (-not [string]::IsNullOrEmpty($raw)) {
            $norm = Normalize-Bool -Value $raw
            if ($norm) {
                $hooksEnabled = $norm
            }
        }
    }
}

$envHooksEnabled = $env:SPECKIT_ROLLOUT_HOOKS_ENABLED
if (-not [string]::IsNullOrEmpty($envHooksEnabled)) {
    $norm = Normalize-Bool -Value $envHooksEnabled
    if ($norm) {
        $hooksEnabled = $norm
    }
}

# --- Marker search: literal "## Delivery Considerations" heading line ---
function Test-Marker {
    param([string]$FilePath)
    if (-not (Test-Path -LiteralPath $FilePath -PathType Leaf)) {
        return $false
    }
    $lines = Get-Content -LiteralPath $FilePath -ErrorAction SilentlyContinue
    if (-not $lines) {
        return $false
    }
    foreach ($line in $lines) {
        if ($line -match '^## Delivery Considerations[ \t]*$') {
            return $true
        }
    }
    return $false
}

function Extract-FlagsLine {
    param([string]$FilePath)
    $lines = Get-Content -LiteralPath $FilePath -ErrorAction SilentlyContinue
    if (-not $lines) {
        return ""
    }
    $inSection = $false
    foreach ($line in $lines) {
        if ($line -match '^## Delivery Considerations[ \t]*$') {
            $inSection = $true
            continue
        }
        if ($inSection -and $line -match '^## ') {
            $inSection = $false
        }
        if ($inSection) {
            $match = [regex]::Match($line, 'candidate flag\(s\):', [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
            if ($match.Success) {
                $rest = $line.Substring($match.Index + $match.Length).Trim()
                return $rest
            }
        }
    }
    return ""
}

if ($Mode -eq "analyze") {
    $searchFiles = @("spec.md", "plan.md", "tasks.md")
} else {
    $searchFiles = @("spec.md")
}

$source = ""
$flags = ""
$markerFound = $false

foreach ($fname in $searchFiles) {
    $candidate = Join-Path $featureDir $fname
    if (Test-Marker -FilePath $candidate) {
        $markerFound = $true
        $source = $fname
        $flags = Extract-FlagsLine -FilePath $candidate
        break
    }
}

if ($hooksEnabled -eq "false") {
    Write-GateResult -HasFlags "false" -Flags "" -Source "" -HooksEnabled "false"
    exit 1
}

if ($markerFound) {
    Write-GateResult -HasFlags "true" -Flags $flags -Source $source -HooksEnabled $hooksEnabled
    exit 0
}

Write-GateResult -HasFlags "false" -Flags "" -Source "" -HooksEnabled $hooksEnabled
exit 1
