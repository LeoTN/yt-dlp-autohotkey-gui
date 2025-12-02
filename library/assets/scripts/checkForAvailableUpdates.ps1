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
function Compare-Versions() {
    param (
        [Parameter(Mandatory = $true)]
        [string]$v1,
        [Parameter(Mandatory = $true)]
        [string]$v2
    )
    function Parse-Version([string]$v) {
        $isBeta = $v -match "b(\d+)$"
        $betaNum = if ($isBeta) { [int]$Matches[1] } else { 0 }
        $clean = $v.Replace("v", "") -replace "b\d+$", ""
        $parts = $clean -split '\.'
        while ($parts.Count -lt 4) { $parts += '0' }
        return @{Version = [version]($parts -join '.'); BetaNum = $betaNum }
    }

    $pv1 = Parse-Version $v1
    $pv2 = Parse-Version $v2

    if ($pv1.Version -gt $pv2.Version) { return $v1 }
    elseif ($pv1.Version -lt $pv2.Version) { return $v2 }
    else {
        # Both have same numeric version, compare beta number
        if ($pv1.BetaNum -eq $pv2.BetaNum) { return "identical_versions" }
        elseif ($pv1.BetaNum -eq 0) { return $v1 }           # v1 stable > v2 beta
        elseif ($pv2.BetaNum -eq 0) { return $v2 }           # v2 stable > v1 beta
        elseif ($pv1.BetaNum -gt $pv2.BetaNum) { return $v1 }
        else { return $v2 }
    }
}

function Exit-Script($code) {
    Write-Host "[INFO] Exiting with code '$code'."
    Stop-Transcript | Out-Null
    exit $code
}

function Get-GitHubLatestReleaseVersion {
    param (
        [Parameter(Mandatory = $true)]
        [string]$OwnerRepo
    )
    try {
        $apiUrl = "https://api.github.com/repos/$OwnerRepo/releases/latest"
        $json = Invoke-RestMethod -Uri $apiUrl -ErrorAction Stop
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

    # Find versions matching the format '1.2.3' or 'v1.2.3b1'
    if ($pCurrentVDVersionTag -notmatch "^v?\d+\.\d+\.\d+(b\d+)?$") {
        Write-Error "[ERROR] Invalid current version tag: $pCurrentVDVersionTag"
        Exit-Script 2
    }
    Write-Host "[INFO] VideoDownloader version detected: $pCurrentVDVersionTag."

    if (-not $internetAvailable) {
        Write-Warning "[WARNING] Skipping VideoDownloader check, offline."
        Set-ItemProperty -Path $pRegistryDirectory -Name $vdKey -Value "no_available_update"
    }
    else {
        $apiUrl = $pGitHubRepositoryLink -replace "github.com", "api.github.com/repos"
        $tagsUrl = "$apiUrl/tags"
        try {
            $tagsResponse = Invoke-RestMethod -Uri $tagsUrl -Method Get
            $latestTag = "v0.0.0"
            foreach ($tag in $tagsResponse) {
                # Skip beta releases if the switch is not set
                if ($tag.name -match "b(\d+)$" -and !$pSwitchConsiderBetaReleases) { continue }
                # Skip invalid version tags
                if ($tag.name -notmatch "^v?\d+\.\d+\.\d+(b\d+)?$") { continue }
                $latestTag = Compare-Versions -v1 $latestTag -v2 $tag.name
            }
            # If the latestTag is higher than the currentVDVersion this means that an update is available
            $availableVersion = if ((Compare-Versions -v1 $pCurrentVDVersionTag -v2 $latestTag) -eq $latestTag) { $latestTag } else { "no_available_update" }
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
        if (-not $latestTag) { $latestTag = "v0.0.0" }
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
1: Provided registry path where the registry keys (AVAILABLE_UPDATE and AVAILABLE_YTDLP_UPDATE) should be, is invalid or does not exist
2: The current version registry key has an invalid version syntax
3: Could not extract version info from 'yt-dlp.exe'

Normal exit codes
Range: 100-199
100: No available updates.
101: Available update found.
#>