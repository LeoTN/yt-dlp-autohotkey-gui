[CmdletBinding()]
Param (
    # Path to VideoDownloader registry
    [Parameter(Mandatory = $true)]
    [String]$pRegistryDirectory,
    # Checks for VideoDownloader updates if provided
    [Parameter(Mandatory = $false)]
    [String]$pGitHubRepositoryLink,
    # Required when pGitHubRepositoryLink is provided
    [Parameter(Mandatory = $false)]
    [String]$pCurrentVDVersionTag,
    # Checks for yt-dlp updates if provided
    [Parameter(Mandatory = $false)]
    [String]$pYTDLPFileLocation,
    # Consider beta releases
    [Parameter(Mandatory = $false)]
    [switch]$pSwitchConsiderBetaReleases
)

# --- Console setup ---
$Host.UI.RawUI.BackgroundColor = "Black"
$Host.UI.RawUI.ForegroundColor = "White"
$Host.UI.RawUI.WindowTitle = "VideoDownloader - Check for Updates"
$scriptParentDirectory = Split-Path -Parent $MyInvocation.MyCommand.Path
$logFileLocation = Join-Path -Path $scriptParentDirectory -ChildPath $(if ([string]::IsNullOrEmpty($MyInvocation.MyCommand.Path)) { "ScriptStartedFromTerminal.log" } else { "$([System.IO.Path]::GetFileNameWithoutExtension($MyInvocation.MyCommand.Path)).log" })
Start-Transcript -Path $logFileLocation -ErrorAction "Continue"
Clear-Host
Write-Host "Terminal ready..."

# --- Helper functions ---
function checkInternetConnectionStatus {
    try {
        Test-Connection -ComputerName "www.google.com" -Count 1 -ErrorAction Stop | Out-Null
        Write-Host "[INFO] Internet connection detected."
        return $true
    }
    catch {
        Write-Host "[WARNING] No Internet connection detected." -ForegroundColor "Yellow"
        return $false
    }
}

# Returns the higher version; "identical_versions" if equal
function compareVersions($v1, $v2) {
    $ver1 = [version]$v1.Replace("v", "").Replace("-beta", "")
    $ver2 = [version]$v2.Replace("v", "").Replace("-beta", "")
    $isV1Beta = $v1 -match "-beta$"
    $isV2Beta = $v2 -match "-beta$"

    if ($ver1 -gt $ver2) { return $v1 }
    elseif ($ver1 -lt $ver2) { return $v2 }
    else {
        if ($isV1Beta -and !$isV2Beta) { return $v2 }
        elseif ($isV2Beta -and !$isV1Beta) { return $v1 }
        else { return "identical_versions" }
    }
}

function exitScript($code) {
    Write-Host "[INFO] Exiting with code '$code'."
    Stop-Transcript | Out-Null
    exit $code
}

function Get-GitHubLatestReleaseVersion {
    param ([Parameter(Mandatory = $true)][string]$OwnerRepo)
    try {
        $apiUrl = "https://api.github.com/repos/$OwnerRepo/releases/latest"
        $response = Invoke-WebRequest -Uri $apiUrl -UseBasicParsing -ErrorAction Stop
        $json = $response.Content | ConvertFrom-Json
        return $json.tag_name
    }
    catch {
        Write-Host "[ERROR] Failed to query GitHub for '$OwnerRepo' : $($_.Exception.Message)"
        return $null
    }
}

# --- Ensure registry path ---
if (-not (Test-Path $pRegistryDirectory)) {
    Write-Host "[ERROR] Missing registry path at '$pRegistryDirectory'!" -ForegroundColor Red
    exitScript 1
}

# --- Registry keys ---
$vdKey = "AVAILABLE_UPDATE"
$ytDlpKey = "AVAILABLE_YTDLP_UPDATE"

foreach ($key in @($vdKey, $ytDlpKey)) {
    try { Get-ItemPropertyValue -Path $pRegistryDirectory -Name $key | Out-Null }
    catch {
        Write-Host "[INFO] Missing registry key '$key', creating it..."
        New-ItemProperty -Path $pRegistryDirectory -Name $key -PropertyType String | Out-Null
    }
}

# --- Check Internet once ---
$internetAvailable = checkInternetConnectionStatus

# --- VideoDownloader update check ---
if ($pGitHubRepositoryLink -and $pCurrentVDVersionTag) {
    Write-Host "`n[INFO] Checking VideoDownloader updates..."

    $currentVDVersion = $pCurrentVDVersionTag.Replace("v", "").Replace("-beta", "")
    if ($currentVDVersion -notmatch '^\d+\.\d+\.\d+(\.\d+)?$') {
        Write-Host "[ERROR] Invalid current version tag: $currentVDVersion." -ForegroundColor Red
        exitScript 2
    }
    Write-Host "[INFO] VideoDownloader version detected: $currentVDVersion"

    if (-not $internetAvailable) {
        Write-Host "[WARNING] Skipping VideoDownloader check, offline." -ForegroundColor Yellow
        Set-ItemProperty -Path $pRegistryDirectory -Name $vdKey -Value "no_available_update"
    }
    else {
        $apiUrl = $pGitHubRepositoryLink -replace "github.com", "api.github.com/repos"
        $tagsUrl = "$apiUrl/tags"
        try {
            $tagsResponse = Invoke-RestMethod -Uri $tagsUrl -Method Get
            $latestTag = "v0.0.0.0"
            foreach ($tag in $tagsResponse) {
                $tmpTag = $tag.name.Replace("v", "")
                if ($tmpTag -like "*-beta" -and !$pSwitchConsiderBetaReleases) { continue }
                $tmpTag = $tmpTag.Replace("-beta", "")
                if ($tmpTag -notmatch '^\d+\.\d+\.\d+(\.\d+)?$') { continue }
                $latestTag = compareVersions $latestTag $tag.name
            }

            $availableVersion = if ($latestTag -ne $currentVDVersion) { $latestTag } else { "no_available_update" }
            if ($availableVersion -ne "no_available_update") {
                Write-Host "[INFO] Update available for VideoDownloader: $latestTag"
                Set-ItemProperty -Path $pRegistryDirectory -Name $vdKey -Value $latestTag
            }
            else {
                Write-Host "[INFO] No update available for VideoDownloader."
                Set-ItemProperty -Path $pRegistryDirectory -Name $vdKey -Value "no_available_update"
            }
        }
        catch {
            Write-Host "[ERROR] Failed to fetch latest tag from GitHub: $($_.Exception.Message)" -ForegroundColor Red
            Set-ItemProperty -Path $pRegistryDirectory -Name $vdKey -Value "no_available_update"
        }
    }
}

# --- yt-dlp update check ---
if ($pYTDLPFileLocation) {
    Write-Host "`n[INFO] Checking yt-dlp updates..."
    try {
        $currentYTDLPVersion = & $pYTDLPFileLocation --version 2>&1
        if (-not $currentYTDLPVersion) { 
            Write-Host "[ERROR] Failed to extract version info from '$pYTDLPFileLocation'"
            exitScript 3 
        }
        Write-Host "[INFO] yt-dlp version detected: $currentYTDLPVersion"
    }
    catch {
        Write-Host "[ERROR] Failed to extract version info from '$pYTDLPFileLocation': $($_.Exception.Message)"
        exitScript 3 
    }

    if (-not $internetAvailable) {
        Write-Host "[WARNING] Skipping yt-dlp check, offline." -ForegroundColor Yellow
        Set-ItemProperty -Path $pRegistryDirectory -Name $ytDlpKey -Value "no_available_update"
    }
    else {
        $latestTag = Get-GitHubLatestReleaseVersion -OwnerRepo "yt-dlp/yt-dlp"
        if (-not $latestTag) { $latestTag = "v0.0.0.0" }
        Write-Host "[INFO] Latest GitHub release for yt-dlp: $latestTag"

        $highestTag = compareVersions $currentYTDLPVersion $latestTag
        $availableVersion = if ($highestTag -ne "identical_versions" -and ($highestTag -eq $latestTag)) { $latestTag } else { "no_available_update" }
        Set-ItemProperty -Path $pRegistryDirectory -Name $ytDlpKey -Value $availableVersion

        if ($availableVersion -ne "no_available_update") {
            Write-Host "[INFO] A newer version of yt-dlp is available (local: $currentYTDLPVersion, remote: $latestTag)."
        }
        elseif ($highestTag -eq "identical_versions") {
            Write-Host "[INFO] yt-dlp is up-to-date (version $currentYTDLPVersion)."
        }
        else {
            Write-Host "[WARNING] Local yt-dlp version ($currentYTDLPVersion) appears newer than latest release ($latestTag)."
        }
    }
}

# --- Exit with update status ---
$vdUpdate = if ($pGitHubRepositoryLink) { Get-ItemPropertyValue -Path $pRegistryDirectory -Name $vdKey } else { "no_check" }
$ytDlpUpdate = if ($pYTDLPFileLocation) { Get-ItemPropertyValue -Path $pRegistryDirectory -Name $ytDlpKey } else { "no_check" }

$exitCode = 100  # default: no updates
if (($vdUpdate -ne "no_available_update" -and $vdUpdate -ne "no_check") -or ($ytDlpUpdate -ne "no_available_update" -and $ytDlpUpdate -ne "no_check")) {
    $exitCode = 101
}

Write-Host "`n[INFO] Update check finished."
exitScript $exitCode

<# 
Exit Code List

Bad exit codes
Range: 1-99
1: Provided registry path where the registry keys (CURRENT_VERSION_LAST_UPDATED and AVAILABLE_UPDATE) should be, is invalid or does not exist
2: The current version registry key has an invalid version syntaxt.
3: Could not extract version info from the 'yt-dlp.exe'

Normal exit codes
Range: 100-199
100: No available updates.
101: Available update found.
#>