[CmdletBinding()]
Param (
    # The GitHub repository link where to check for updates.
    [Parameter(Mandatory = $true)]
    [String]$pGitHubRepositoryLink,
    # The program's registry path. The update information will be stored there.
    [Parameter(Mandatory = $true)]
    [String]$pRegistryDirectory,
    # If provided, will force the script to find the highest available update version, even if the current version is already the highest.
    [Parameter(Mandatory = $false)]
    [switch]$pSwitchForceUpdate,
    # If provided, the script will consider beta releases as available update versions.
    [Parameter(Mandatory = $false)]
    [switch]$pSwitchConsiderBetaReleases
)

$Host.UI.RawUI.BackgroundColor = "Black"
$Host.UI.RawUI.ForegroundColor = "White"
$Host.UI.RawUI.WindowTitle = "VideoDownloader - Update Script"
$scriptParentDirectory = Split-Path -Parent $MyInvocation.MyCommand.Path
$logFileName = "checkForAvailableUpdates.log"
$logFilePath = Join-Path -Path $scriptParentDirectory -ChildPath $logFileName
$null = Start-Transcript -Path $logFilePath -Force
$null = Clear-Host
$null = Write-Host "Terminal ready..."

function onInit() {
    # A list of all exit codes can be found at the end of this script.

    # Checks if the provided registry path exists.
    If (-not (Test-Path -Path $pRegistryDirectory)) {
        $null = Write-Host "[onInit()] [ERROR] Missing registry path at [$pRegistryDirectory]!" -ForegroundColor "Red"
        exitScript -pExitCode 2
    }

    # This registry key must exist. It stores the current version of the program which could receive an update.
    $global:currentVersionKeyName = "CURRENT_VERSION"
    Try {
        $null = Get-ItemPropertyValue -Path $pRegistryDirectory -Name $global:currentVersionKeyName -ErrorAction "SilentlyContinue"
    }
    Catch {
        $null = Write-Host "[onInit()] [ERROR] Missing registry key [$global:currentVersionKeyName] at [$pRegistryDirectory]. This key cannot be created." -ForegroundColor "Red"
        exitScript -pExitCode 3
    }
    # This registry key stores the last update date of the current version. It isn't bad, when it has no value.
    $global:currentVersionLastUpdateKeyName = "CURRENT_VERSION_LAST_UPDATED"
    Try {
        $null = Get-ItemPropertyValue -Path $pRegistryDirectory -Name $global:currentVersionLastUpdateKeyName
    }
    Catch {
        $null = Write-Host "[onInit()] [WARNING] Missing registry key [$global:currentVersionLastUpdateKeyName] at [$pRegistryDirectory]. Creating key..." -ForegroundColor "Yellow"
        $null = New-ItemProperty -Path $pRegistryDirectory -Name $global:currentVersionLastUpdateKeyName -PropertyType "String" -ErrorAction "Stop"
    }
    # This registry key stores the available update version depending on the current version and if the user wants beta versions.
    $global:availableUpdateKeyName = "AVAILABLE_UPDATE"
    Try {
        $null = Get-ItemPropertyValue -Path $pRegistryDirectory -Name $global:availableUpdateKeyName
    }
    Catch {
        $null = Write-Host "[onInit()] [WARNING] Missing registry key [$global:availableUpdateKeyName] at [$pRegistryDirectory]. Creating key..." -ForegroundColor "Yellow"
        $null = New-ItemProperty -Path $pRegistryDirectory -Name $global:availableUpdateKeyName -PropertyType "String" -ErrorAction "Stop"
    }

    # These variables store information about the update.
    $global:currentVersion = Get-ItemPropertyValue -Path $pRegistryDirectory -Name $global:currentVersionKeyName
    $global:currentVersionLastUpdateDate = Get-ItemPropertyValue -Path $pRegistryDirectory -Name $global:currentVersionLastUpdateKeyName
    
    # Exit code list at the end of this file.
    $exitCode = evaluateUpdate
    exitScript -pExitCode $exitCode
}

function exitScript() {
    [CmdletBinding()]
    Param (
        # The exit code that the script will return to it's caller.
        [Parameter(Mandatory = $true)]
        [int]$pExitCode
    )

    $null = Write-Host "[onInit()] [exitScript()] Exiting with exit code [$pExitCode]."
    # Speeds up the script when it's ran without the user seeing it.
    If (checkIfScriptWindowIsHidden) {
        $null = Start-Sleep -Seconds 3
    }
    Exit $pExitCode
}

# Evaluates, if an update is available and returns an exit code accordingly.
function evaluateUpdate() {
    # A list of all exit codes can be found at the end of this script.

    # This function fills the two variables above with values from the registry keys.
    If (-not (extractVersionInformation)) {
        Return 1
    }
    $null = Write-Host "`n`n[evaluateUpdate()] [INFO] The current version [$global:currentVersion] had it's last update on [$global:currentVersionLastUpdateDate].`n`n" -ForegroundColor "Green"

    $availableUpdateVersion = getAvailableUpdateTag
    If ($availableUpdateVersion -eq "no_available_update") {
        $null = Write-Host "`n`n[evaluateUpdate()] [INFO] There are no updates available.`n`n" -ForegroundColor "Green"
        Return 100
    }
    # Updates the available update registry key.
    $null = Set-ItemProperty -Path $pRegistryDirectory -Name $global:availableUpdateKeyName -Value $availableUpdateVersion
    $null = Write-Host "`n`n[evaluateUpdate()] [INFO] There is an update available [$availableUpdateVersion].`n`n" -ForegroundColor "Green"
    Return 101
}

function extractVersionInformation() {
    # Checks if the provided tag has a valid syntaxt.
    $tmpTag = $global:currentVersion.Replace("v", "").Replace("-beta", "")
    If (-not ($tmpTag -match '^\d+\.\d+\.\d+(\.\d+)?$')) {
        $null = Write-Host "[extractVersionInformation()] [ERROR] Found tag name which couldn't be converted to version: [$global:currentVersion]." -ForegroundColor "Red"
        Return $false
    }
    If (($global:currentVersionLastUpdateDate -eq "not_updated_yet") -or ([String]::IsNullOrEmpty($global:currentVersionLastUpdateDate))) {
        $null = Write-Host "[extractVersionInformation()] [INFO] This version [$global:currentVersion] has not been updatet yet. Trying to fetch latest update date..."
        $global:currentVersionLastUpdateDate = getLastUpdatedDateFromTag -pTagName $global:currentVersion
        # This happens, when there is still no latest update date available.
        If ($global:currentVersionLastUpdateDate -eq "not_updated_yet") {
            $null = Write-Host "[extractVersionInformation()] [INFO] Could not fetch any update dates for [$global:currentVersion]."
        }
        Else {
            $null = Write-Host "[extractVersionInformation()] [INFO] Fetched last update date: [$global:currentVersionLastUpdateDate]. Updating current version file..."
        }
        # Corrects the last update data registry key.
        $null = Set-ItemProperty -Path $pRegistryDirectory -Name $global:currentVersionLastUpdateKeyName -Value $global:currentVersionLastUpdateDate
        Return $true
    }
    If (-not (checkIfStringIsValidDate -pDateTimeString $global:currentVersionLastUpdateDate)) {
        $null = Write-Host "[extractVersionInformation()] [ERROR] Found an invalid last update date [$global:currentVersionLastUpdateDate] for [$global:currentVersion]." -ForegroundColor "Red"
        Return $false
    }
    # Forcing an internationally valid date format here should prevent issues.
    $currentDateTime = Get-Date -Format "yyyy-MM-ddTHH:mm:ss"
    $highestDateTime = compareDates -pDateString1 $global:currentVersionLastUpdateDate -pDateString2 $currentDateTime
    # This mean the current last update date lies in the future.
    If ((compareDates -pDateString1 $highestDateTime -pDateString2 $currentDateTime) -ne "identical_dates") {
        $null = Write-Host "[extractVersionInformation()] [WARNING] The last update date [$global:currentVersionLastUpdateDate] from [$global:currentVersion] lies in the future." -ForegroundColor "Yellow"
        Return $false
    }
    Return $true
}

# Checks for available updates and returns either "no_available_update" or the update tag name.
function getAvailableUpdateTag() {
    If (-not (checkInternetConnectionStatus)) {
        $null = Write-Host "[getAvailableUpdateTag()] [WARNING] No active Internet connection found." -ForegroundColor "Yellow"
        Return "no_available_update"
    }

    $currentTag = $global:currentVersion
    $latestTag = getLatestTag
    $highestTag = compareVersions -pVersion1 $currentTag -pVersion2 $latestTag
    # This means there is an update available. We are returning the latest tag and not the highest tag, because returning the
    # highest tag could result in an update to the "current" beta version, when pSwitchConsiderBetaReleases is not true.
    If ($pSwitchForceUpdate) {
        $null = Write-Host "[getAvailableUpdateTag()] [INFO] Forced update. Highest available version: [$latestTag]."
        Return $latestTag
    }
    If ($highestTag -eq $latestTag) {
        $null = Write-Host "[getAvailableUpdateTag()] [INFO] Found a higher version to update: [$highestTag]."
        Return $highestTag
    }

    $currentTagLatestUpdateDate = $global:currentVersionLastUpdateDate
    $latestTagLatestUpdateDate = getLastUpdatedDateFromTag -pTagName $latestTag
    # This might happen with new releases or if a non existing current version has been supplied.
    If (($latestTagLatestUpdateDate -eq "not_updated_yet") -or ($currentTagLatestUpdateDate -eq "not_updated_yet")) {
        $null = Write-Host "[getAvailableUpdateTag()] [INFO] Could not find any available updates."
        Return "no_available_update"
    }
    $highestLatestUpdateDate = compareDates -pDateString1 $currentTagLatestUpdateDate -pDateString2 $latestTagLatestUpdateDate
    # This means there is an update available.
    If ($highestLatestUpdateDate -eq $latestTagLatestUpdateDate) {
        $null = Write-Host "[getAvailableUpdateTag()] [INFO] Your current version [$currentTag] has received an update."
        Return $currentTag
    }
    $null = Write-Host "[getAvailableUpdateTag()] [INFO] Could not find any available updates."
    Return "no_available_update"
}

# This function uses semantic versioning to determine if a tag is the latest.
function getLatestTag() {
    If (-not (checkInternetConnectionStatus)) {
        $null = Write-Host "[getLatestTag()] [WARNING] No active Internet connection found." -ForegroundColor "Yellow"
        Return $false
    }

    Try {
        # This converts the "normal" repository link in order to use the GitHub API.
        $apiUrl = $pGitHubRepositoryLink -Replace "github\.com", "api.github.com/repos"
        $fullApiUrl = "$apiUrl/tags"
        $tagsResponse = Invoke-RestMethod -Uri $fullApiUrl -Method Get

        $latestTag = "v0.0.0.0"
        # Iterating through the tags.
        Foreach ($tag in $tagsResponse) {
            $tmpTag = $tag.name
            # Removing unwanted characters and beta label.
            $tmpTag = $tmpTag.Replace("v", "")
            If ($tmpTag -like "*-beta" -and !$pSwitchConsiderBetaReleases) {
                $null = Write-Host "[getLatestTag()] [INFO] Skipping tag [$tmpTag] which is a beta release."
                Continue
            }
            # Checking if the version is valid.
            $tmpTag = $tmpTag.Replace("-beta", "")
            If (-not ($tmpTag -match '^\d+\.\d+\.\d+(\.\d+)?$')) {
                $null = Write-Host "[getLatestTag()] [WARNING] Found tag name which couldn't be converted to version: [$tmpTag]." -ForegroundColor "Yellow"
                Continue
            }
            # Finds the highest version.
            $latestTag = compareVersions -pVersion1 $latestTag -pVersion2 $tag.name
        }
        $null = Write-Host "[getLatestTag()] [INFO] Found highest tag: [$latestTag]."
        Return $latestTag
    }
    Catch {
        $null = Write-Host "[getLatestTag()] [ERROR] Failed to fetsh latest tag! Detailed error description below.`n" -ForegroundColor "Red"
        $null = Write-Host "***START***[`n$Error`n]***END***" -ForegroundColor "Red"
        Return $false
    }
}

function getLastUpdatedDateFromTag() {
    [CmdLetBinding()]
    Param (
        [Parameter(Mandatory = $true)]
        [String]$pTagName
    )
   
    If (-not (checkInternetConnectionStatus)) {
        $null = Write-Host "[getLastUpdatedDateFromTag()] [WARNING] No active Internet connection found." -ForegroundColor "Yellow"
        Return "not_updated_yet"
    }
    Try {
        # This converts the "normal" repository link in order to use the GitHub API.
        $apiUrl = $pGitHubRepositoryLink -Replace "github\.com", "api.github.com/repos"
        $fullApiUrl = "$apiUrl/releases/tags/$pTagName"
        $tagResponse = Invoke-RestMethod -Uri $fullApiUrl
        # The date is not a valid PowerShell datetime data type. That's why we are converting it.
        $invalidLastUpdateDate = ($tagResponse.assets | Select-Object -ExpandProperty updated_at)
        # This happens, when the release hasn't been updated yet.
        If (!$invalidLastUpdateDate) {
            $null = Write-Host "[getLastUpdatedDateFromTag()] [INFO] No update date for [$pTagName] found."
            Return "not_updated_yet"
        }
        # Forcing an internationally valid date format here should prevent issues.
        $lastUpdateDate = Get-Date -Format "yyyy-MM-ddTHH:mm:ss" $invalidLastUpdateDate
    }
    Catch {
        $null = Write-Host "[getLastUpdatedDateFromTag()] [ERROR] Failed to fetch last update date for [$pTagName]! Detailed error description below.`n" -ForegroundColor "Red"
        $null = Write-Host "***START***[`n$Error`n]***END***" -ForegroundColor "Red"
        Return "not_updated_yet"
    }
    $null = Write-Host "[getLastUpdatedDateFromTag()] [INFO] Update date [$lastUpdateDate] for [$pTagName] found."
    Return $lastUpdateDate
}

# Returns the higher version. If the versions are identical, it will return the string "identical_versions".
function compareVersions {
    [CmdletBinding()]
    Param (
        [Parameter(Mandatory = $true)]
        [String]$pVersion1,
        [Parameter(Mandatory = $true)]
        [String]$pVersion2
    )

    $ver1 = [version]$pVersion1.Replace("v", "").Replace("-beta", "")
    $ver2 = [version]$pVersion2.Replace("v", "").Replace("-beta", "")

    $isVer1Beta = $pVersion1 -match "-beta$"
    $isVer2Beta = $pVersion2 -match "-beta$"

    If ($ver1 -gt $ver2) {
        $null = Write-Host "[compareVersions()] [INFO] [$pVersion1] is higher than [$pVersion2]."
        Return $pVersion1
    }
    ElseIf ($ver1 -lt $ver2) {
        $null = Write-Host "[compareVersions()] [INFO] [$pVersion2] is higher than [$pVersion1]."
        Return $pVersion2
    }
    Else {
        # Only one of them is a beta version.
        If ($isVer1Beta -and !$isVer2Beta) {
            $null = Write-Host "[compareVersions()] [INFO] [$pVersion2] is higher than [$pVersion1]."
            Return $pVersion2
        }
        ElseIf ($isVer2Beta -and !$isVer1Beta) {
            $null = Write-Host "[compareVersions()] [INFO] [$pVersion1] is higher than [$pVersion2]."
            Return $pVersion1
        }
        $null = Write-Host "[compareVersions()] [INFO] [$pVersion1] is identical to [$pVersion2]."
        Return "identical_versions"
    }
}

# Compares two date strings. Returns the higher date. If the dates are identical, it returns the string "identical_dates".
function compareDates() {
    [CmdletBinding()]
    Param (
        [Parameter(Mandatory = $true)]
        [String]$pDateString1,
        [Parameter(Mandatory = $true)]
        [String]$pDateString2
    )

    # Convert the strings to PowerShell datetime objects.
    $date1 = Get-Date $pDateString1
    $date2 = Get-Date $pDateString2

    # Compare the two dates.
    If ($date1 -gt $date2) {
        $null = Write-Host "[compareDates()] [INFO] [$pDateString1] is later than [$pDateString2]."
        Return $pDateString1
    }
    Elseif ($date1 -lt $date2) {
        $null = Write-Host "[compareDates()] [INFO] [$pDateString2] is later than [$pDateString1]."
        Return $pDateString2
    }
    Else {
        $null = Write-Host "[compareDates()] [INFO] [$pDateString1] is identical to [$pDateString2]."
        Return "identical_dates"
    }
}

function checkInternetConnectionStatus() {
    Try {
        Test-Connection -ComputerName "www.google.com" -Count 1 -ErrorAction "Stop"
        $null = Write-Host "[checkInternetConnectionStatus()] [INFO] Computer is connected to the Internet."
        Return $true
    }
    Catch {
        $null = Write-Host "[checkInternetConnectionStatus()] [WARNING] Computer is not connected to the Internet." -ForegroundColor "Yellow"
        Return $false
    }
}

function checkIfStringIsValidDate() {
    Param(
        [Parameter(Mandatory = $true)]
        [String]$pDateTimeString
    )
    If ($pDateTimeString -as [datetime]) {
        $null = Write-Host "[checkIfStringIsValidDate()] [INFO] The string [$pDateTimeString] is a valid date."
        Return $true
    }
    $null = Write-Host "[checkIfStringIsValidDate()] [WARNING] The string [$pDateTimeString] is an invalid date." -ForegroundColor "Yellow"
    Return $false
}

function checkIfScriptWindowIsHidden() {
    # Define the necessary Windows API functions
    $null = Add-Type @"
using System;
using System.Runtime.InteropServices;

public class User32 {
    [DllImport("user32.dll")]
    [return: MarshalAs(UnmanagedType.Bool)]
    public static extern bool IsWindowVisible(IntPtr hWnd);

    [DllImport("user32.dll", SetLastError = true)]
    public static extern IntPtr GetForegroundWindow();

    [DllImport("user32.dll")]
    public static extern int GetWindowText(IntPtr hWnd, System.Text.StringBuilder text, int count);
}
"@
    $consoleHandle = [System.Diagnostics.Process]::GetCurrentProcess().MainWindowHandle
    [boolean]$isVisible = [User32]::IsWindowVisible($consoleHandle)
    Return $isVisible
}

$null = onInit

<# 
Exit Code List

Bad exit codes
Range: 1-99
1: Corrupted current version registry key or current version last update date key.
2: Provided registry path where the registry keys (CURRENT_VERSION, CURRENT_VERSION_LAST_UPDATED, AVAILABLE_UPDATE) should be, is invalid or does not exist.
3: Missing "CURRENT_VERSION" registry key.

Normal exit codes
Range: 100-199
100: No available updates.
101: Available update found.
#>