param(
  [Parameter(Mandatory = $true)]
  [string]$SubscriptionId,
  [Parameter(Mandatory = $true)]
  [string]$ResourceGroupName,
  [string]$ConfigPath
)

$ErrorActionPreference = "Stop"

if ([string]::IsNullOrWhiteSpace($ConfigPath)) {
  $ConfigPath = Join-Path -Path $PSScriptRoot -ChildPath "../references/azops-config.json"
}

if (-not (Test-Path -LiteralPath $ConfigPath)) {
  Write-Error "Config file not found: $ConfigPath"
}

try {
  $config = Get-Content -LiteralPath $ConfigPath -Raw | ConvertFrom-Json
}
catch {
  Write-Error "Invalid config JSON in ${ConfigPath}: $($_.Exception.Message)"
}

if (-not $config.discovery -or $null -eq $config.discovery.maxDepth) {
  Write-Error "Config is missing required discovery.maxDepth: ${ConfigPath}"
}

$azopsRoot = $config.azopsRoot
if (-not $azopsRoot) {
  Write-Error "Config is missing required azopsRoot: ${ConfigPath}"
}

try {
  $maxDepth = [int]$config.discovery.maxDepth
}
catch {
  Write-Error "Config contains non-numeric discovery.maxDepth: ${ConfigPath}"
}

if ($maxDepth -lt 1) {
  Write-Error "Config contains invalid discovery.maxDepth ($maxDepth): ${ConfigPath}"
}

$resolvedConfigPath = (Resolve-Path -LiteralPath $ConfigPath).Path
$configDirectory = Split-Path -Path $resolvedConfigPath -Parent
$resolvedAzopsRoot = if ([System.IO.Path]::IsPathRooted($azopsRoot)) {
  $azopsRoot
} else {
  Join-Path -Path $configDirectory -ChildPath $azopsRoot
}

if (-not $azopsRoot -or -not (Test-Path -LiteralPath $resolvedAzopsRoot)) {
  Write-Error "AzOps root missing or invalid in config: $azopsRoot (resolved: $resolvedAzopsRoot)"
}

$subscriptionIdLower = $SubscriptionId.ToLowerInvariant()
$rgNameLower = $ResourceGroupName.ToLowerInvariant()
$escapedSubscriptionId = [regex]::Escape($subscriptionIdLower)
$subscriptionFolderRegex = "\($escapedSubscriptionId\)"

$candidate = @()
$subscriptionDirs = @()

foreach ($dir in Get-ChildItem -Path $resolvedAzopsRoot -Recurse -Directory -Filter "*($SubscriptionId)*" -ErrorAction SilentlyContinue) {
  $relative = $dir.FullName.Substring($resolvedAzopsRoot.Length).TrimStart('\', '/')
  if ([string]::IsNullOrWhiteSpace($relative)) {
    continue
  }

  $depth = ($relative -split "[\\/]").Count
  if ($depth -gt $maxDepth) {
    continue
  }

  $nameLower = $dir.Name.ToLowerInvariant()
  if ($nameLower -match $subscriptionFolderRegex) {
    $subscriptionDirs += $dir
  }
}

$subscriptionDirs = @($subscriptionDirs | Sort-Object -Property FullName -Unique)

foreach ($subDir in $subscriptionDirs) {
  $childDirs = Get-ChildItem -Path $subDir.FullName -Directory -ErrorAction SilentlyContinue
  foreach ($child in $childDirs) {
    if ($child.Name.ToLowerInvariant() -eq $rgNameLower) {
      $candidate += $child.FullName
    }
  }
}

$candidate = @($candidate | Sort-Object -Unique)

if ($candidate.Count -eq 1) {
  [pscustomobject]@{
    status = "resolved"
    resolvedAzopsPath = $candidate[0]
    candidateCount = 1
  } | ConvertTo-Json -Depth 4
  exit 0
}

if ($candidate.Count -eq 0) {
  [pscustomobject]@{
    status = "blocked"
    reason = "no_match"
    subscriptionId = $SubscriptionId
    resourceGroupName = $ResourceGroupName
    candidates = @()
  } | ConvertTo-Json -Depth 6
  exit 2
}

[pscustomobject]@{
  status = "blocked"
  reason = "multiple_matches"
  subscriptionId = $SubscriptionId
  resourceGroupName = $ResourceGroupName
  candidates = $candidate
} | ConvertTo-Json -Depth 6
exit 3
