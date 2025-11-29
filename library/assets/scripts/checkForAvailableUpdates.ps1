[CmdletBinding()]
Param (
    # Path to VideoDownloader registry
    [Parameter(Mandatory = $true)]
    [String]$pRegistryDirectory,
    # Checks for VideoDownloader updates if provided
    [Parameter(Mandatory = $false)]
    [String]$pGitHubRepositoryLink,
    # Required when pGitHubRepositoryLink is provided. For example "v1.2.3.4"
    [Parameter(Mandatory = $false)]
    [String]$pCurrentVDVersionTag,
    # Checks for yt-dlp updates if provided. For example "2025.10.22.0"
    [Parameter(Mandatory = $false)]
    [String]$pCurrentYTDLPVersion,
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
function Get-InternetConnectionStatus {
    try {
        # Attempt to make a web request to a reliable URL
        $response = Invoke-WebRequest -Uri "https://www.google.com" -UseBasicParsing -TimeoutSec 5
        if ($response.StatusCode -eq 200) {
            Write-Host "[INFO] Internet connection detected."
            return $true
        }
        else {
            Write-Warning "[WARNING] No Internet connection detected. Status code: $($response.StatusCode)"
            return $false
        }
    }
    catch {
        Write-Warning "[WARNING] No Internet connection detected."
        return $false
    }
}

# Returns the higher version; "identical_versions" if equal
function Compare-Versions($v1, $v2) {
    # Helper: normalize version string to always have 4 components
    function Normalize-Version([string]$v) {
        $clean = $v.Replace("v", "").Replace("-beta", "")
        $parts = $clean -split '\.'
        while ($parts.Count -lt 4) { $parts += '0' }  # Fill missing parts with zeros
        return [version]($parts -join '.')
    }

    $ver1 = Normalize-Version $v1
    $ver2 = Normalize-Version $v2

    $isV1Beta = $v1 -match "-beta$"
    $isV2Beta = $v2 -match "-beta$"

    if ($ver1 -gt $ver2) { return $v1 }
    elseif ($ver1 -lt $ver2) { return $v2 }
    else {
        # Handle beta suffix priority
        if ($isV1Beta -and -not $isV2Beta) { return $v2 }
        elseif ($isV2Beta -and -not $isV1Beta) { return $v1 }
        else { return "identical_versions" }
    }
}

function Exit-Script($code) {
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
        Write-Error "[ERROR] Failed to query GitHub for '$OwnerRepo' : $($_.Exception.Message)"
        return $null
    }
}

# --- Ensure registry path ---
if (-not (Test-Path $pRegistryDirectory)) {
    Write-Error "[ERROR] Missing registry path at '$pRegistryDirectory'"
    Exit-Script 1
}

# --- Registry keys ---
$vdKey = "AVAILABLE_UPDATE"
$ytdlpKey = "AVAILABLE_YTDLP_UPDATE"

foreach ($key in @($vdKey, $ytdlpKey)) {
    try { Get-ItemPropertyValue -Path $pRegistryDirectory -Name $key | Out-Null }
    catch {
        Write-Host "[INFO] Missing registry key '$key', creating it..."
        New-ItemProperty -Path $pRegistryDirectory -Name $key -PropertyType String | Out-Null
    }
}

# --- Check Internet once ---
$internetAvailable = Get-InternetConnectionStatus

# --- VideoDownloader update check ---
if ($pGitHubRepositoryLink -and $pCurrentVDVersionTag) {
    Write-Host "`n[INFO] Checking VideoDownloader updates..."
    if ($pSwitchConsiderBetaReleases) {
        Write-Host "[INFO] Beta versions will be considered as available updates."
    }

    $currentVDVersion = $pCurrentVDVersionTag.Replace("v", "")
    # Find versions matching the format '1.2.3' or 'v1.2.3-beta'
    if ($currentVDVersion -notmatch "^\d+\.\d+\.\d+(\.\d+)?(-beta)?$") {
        Write-Error "[ERROR] Invalid current version tag: $currentVDVersion"
        Exit-Script 2
    }
    Write-Host "[INFO] VideoDownloader version detected: $currentVDVersion."

    if (-not $internetAvailable) {
        Write-Warning "[WARNING] Skipping VideoDownloader check, offline."
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
                $latestTag = Compare-Versions $latestTag $tag.name
            }
            # If the latestTag is higher than the currentVDVersion this means that an update is available
            $availableVersion = if ((Compare-Versions -v1 $currentVDVersion -v2 $latestTag) -eq $latestTag) { $latestTag } else { "no_available_update" }
            if ($availableVersion -ne "no_available_update") {
                Write-Host "[INFO] Update available for VideoDownloader: $latestTag."
                Set-ItemProperty -Path $pRegistryDirectory -Name $vdKey -Value $latestTag
            }
            else {
                Write-Host "[INFO] VideoDownloader is up-to-date (version: $pCurrentVDVersionTag)."
                Set-ItemProperty -Path $pRegistryDirectory -Name $vdKey -Value "no_available_update"
            }
        }
        catch {
            Write-Error "[ERROR] Failed to fetch latest tag from GitHub: $($_.Exception.Message)"
            Set-ItemProperty -Path $pRegistryDirectory -Name $vdKey -Value "no_available_update"
        }
    }
}

# --- yt-dlp update check ---
if ($pCurrentYTDLPVersion) {
    Write-Host "`n[INFO] Checking yt-dlp updates..."
    
    Write-Host "[INFO] yt-dlp version detected: $pCurrentYTDLPVersion."
    if (-not $internetAvailable) {
        Write-Warning "[WARNING] Skipping yt-dlp check, offline."
        Set-ItemProperty -Path $pRegistryDirectory -Name $ytdlpKey -Value "no_available_update"
    }
    else {
        $latestTag = Get-GitHubLatestReleaseVersion -OwnerRepo "yt-dlp/yt-dlp"
        if (-not $latestTag) { $latestTag = "v0.0.0.0" }
        Write-Host "[INFO] Latest GitHub release for yt-dlp: $latestTag."

        $highestTag = Compare-Versions -v1 $pCurrentYTDLPVersion -v2 $latestTag
        $availableVersion = if ($highestTag -ne "identical_versions" -and ($highestTag -eq $latestTag)) { $latestTag } else { "no_available_update" }
        
        if ($availableVersion -ne "no_available_update") {
            Write-Host "[INFO] A newer version of yt-dlp is available (local: $pCurrentYTDLPVersion, remote: $latestTag)."
        }
        elseif ($highestTag -eq "identical_versions") {
            Write-Host "[INFO] yt-dlp is up-to-date (version: $pCurrentYTDLPVersion)."
        }
        else {
            Write-Warning "[WARNING] Local yt-dlp version ($pCurrentYTDLPVersion) appears newer than latest release ($latestTag)."
            # Avoid unnecessary update notifications when using a higher (nightly) version of yt-dlp
            $availableVersion = "no_available_update"
        }
        Set-ItemProperty -Path $pRegistryDirectory -Name $ytdlpKey -Value $availableVersion
    }
}

# --- Exit with update status ---
$vdUpdate = if ($pGitHubRepositoryLink) { Get-ItemPropertyValue -Path $pRegistryDirectory -Name $vdKey } else { "no_check" }
$ytDlpUpdate = if ($pCurrentYTDLPVersion) { Get-ItemPropertyValue -Path $pRegistryDirectory -Name $ytdlpKey } else { "no_check" }

$exitCode = 100  # default: no updates
if (($vdUpdate -ne "no_available_update" -and $vdUpdate -ne "no_check") -or ($ytDlpUpdate -ne "no_available_update" -and $ytDlpUpdate -ne "no_check")) {
    $exitCode = 101
}

Write-Host "`n[INFO] Update check finished."
Exit-Script $exitCode

<# 
Exit Code List

Bad exit codes
Range: 1-99
1: Provided registry path where the registry keys (CURRENT_VERSION_LAST_UPDATED and AVAILABLE_UPDATE) should be, is invalid or does not exist
2: The current version registry key has an invalid version syntax
3: Could not extract version info from 'yt-dlp.exe'

Normal exit codes
Range: 100-199
100: No available updates.
101: Available update found.
#>