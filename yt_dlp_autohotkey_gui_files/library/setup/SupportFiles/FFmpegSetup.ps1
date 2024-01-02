Param (
    [string]$pVideoDownloaderInstallationDirectory,    
    [string]$pLogFileLocation,
    [string]$pSetupType
)

$Host.UI.RawUI.BackgroundColor = "Black"
$Host.UI.RawUI.ForegroundColor = "Green"
$host.UI.RawUI.WindowTitle = "FFmpeg setup script running..."
Clear-Host
Write-Host "Terminal ready..."

function onInit() {
    validateLogFileParameters
    # Default exit code.
    $global:mainExitCode = 71500
    $global:applicationRegistryPath = "HKCU:\SOFTWARE\LeoTN\VideoDownloader"
    $global:ffmpegRegistryVariableName = "ffmpegLocation"
    $global:ffmpegFinalPath = "$pVideoDownloaderInstallationDirectory\yt_dlp_autohotkey_gui_files\library\FFmpeg"
    # This variable is used to store information about the current FFmpeg location.
    $global:ffmpegPath = ""
    $global:logCounter = 0
    # Calling this function will give a value to ffmpegPath.
    getFFmpegInstallStatus | Out-Null
    validateParameters
    Exit $global:mainExitCode
}

function validateLogFileParameters() {
    # Checks if value is given.
    If ($pLogFileLocation) {
        If (-not (validatePath($pLogFileLocation))) {
            $tmpLog = "[validateLogFileParameters()] [ERROR] Invalid log file path found:`n[$pLogFileLocation]."
            log($tmpLog)
            Start-Sleep -Seconds 5
            Exit 715001
        }
        Else {
            # Deletes the old log file if neccessary.
            If (Test-Path -Path $pLogFileLocation) {
                Remove-Item -Path $pLogFileLocation -Force -ErrorAction Continue
            }
            $tmpDate = Get-Date
            $tmpString = "LOG DATE: $tmpDate`n"
            $tmpString | Out-File -Append -FilePath $pLogFileLocation
        }
    }
    Else {
        $tmpLog = "[validateLogFileParameters()] [INFO] No log file location given."
        log($tmpLog)
    }
}

function validateParameters() {
    $host.UI.RawUI.WindowTitle = "Validating parameters..."
    Try {
        If (validatePath($pVideoDownloaderInstallationDirectory)) {
            $tmpLog = "[validateParameters()] [INFO] Application installation path exists."
            log($tmpLog)
        }
        Else {
            $tmpLog = "[validateParameters()] [ERROR] Application installation path doesn't exist. Please check if the given path`n[$pVideoDownloaderInstallationDirectory] is correct."
            log($tmpLog)
            Start-Sleep -Seconds 5
            Exit 71502
        }
    }
    Catch {
        $tmpLog = "[validateParameters()] [ERROR] Application installation path doesn't exist. Please check if the given path [$pVideoDownloaderInstallationDirectory] is correct."
        log($tmpLog)
        Start-Sleep -Seconds 5
        Exit 71502
    }

    Switch ($pSetupType) {
        '/install' { 
            $tmpLog = "[validateParameters()] [INFO] Starting FFmpeg installation..."
            log($tmpLog)
            installFFmpeg
        }
        '/install-force' { 
            $tmpLog = "[validateParameters()] [INFO] Starting forced FFmpeg installation..."
            log($tmpLog)
            installFFmpeg($true)
        }
        '/uninstall' {
            $tmpLog = "[validateParameters()] [INFO] Starting FFmpeg removal process..."
            log($tmpLog)
            uninstallFFmpeg
        }
        '/check-installation-status' { 
            $tmpLog = "[validateParameters()] [INFO] Checking FFmpeg installation status..."
            log($tmpLog)
            $tmpValue = getFFmpegInstallStatus
            $tmpLog = "[validateParameters()] [INFO] FFmpeg installation status is: $tmpValue"
            log($tmpLog)
            If ($tmpValue) {
                # FFmpeg installed.
                $global:mainExitCode = 71601
            }
            Else {
                # FFmpeg not installed.
                $global:mainExitCode = 71602
            }
        }
        Default {
            $tmpLog = "[validateParameters()] [ERROR] Invalid parameter found: [$pSetupType]. '/install', '/install-force' or '/check-installation-status' are allowed only."
            log($tmpLog)
            Start-Sleep -Seconds 5
            Exit 71503
        }
    }
}

function installFFmpeg([string]$pBooleanForceInstall = $false) {
    $host.UI.RawUI.WindowTitle = "Installing FFmpeg files..."
    If (getFFmpegInstallStatus) {
        If ($pBooleanForceInstall -eq $false) {
            $tmpLog = "[installFFmpeg()] [INFO] FFmpeg is already installed in`n[$ffmpegPath].`nUse '/install-force' to overwrite existing files."
            log($tmpLog)
            Start-Sleep -Seconds 5
            Exit 71504
        }
        ElseIf ($pBooleanForceInstall -eq $true) {
            uninstallFFmpeg
        }
    }
    $host.UI.RawUI.WindowTitle = "Downloading FFmpeg files..."
    $ffmpegDownloadURL = "https://www.gyan.dev/ffmpeg/builds/ffmpeg-release-essentials.zip"
    $ffmpegDownloadPath = Join-Path -Path $PSScriptRoot -ChildPath "ffmpeg-release-essentials.zip"
    $ffmpegExtractedDirectory = Join-Path -Path $PSScriptRoot -ChildPath "ffmpeg-release-essentials"
    # Downloads the .ZIP folder from the Internet.         
    Invoke-WebRequest -Uri $ffmpegDownloadURL -OutFile $ffmpegDownloadPath
            
    If ((Test-Path -Path $ffmpegDownloadPath)) {
        $host.UI.RawUI.WindowTitle = "Postprocessing FFmpeg files..."
        $tmpLog = "[installFFmpeg()] [INFO] FFmpeg was downloaded successfully. Starting further processing...."
        log($tmpLog)
        # Removes any remains to ensure a clean un-zip process.
        Remove-Item -Path $ffmpegExtractedDirectory -Recurse -Force -ErrorAction SilentlyContinue
        Expand-Archive -Path $ffmpegDownloadPath -DestinationPath $ffmpegExtractedDirectory -Force
        # Creates the target folder after the original one has been deleted to ensure a clean installation.
        Remove-Item -Path $ffmpegFinalPath -Recurse -Force -ErrorAction SilentlyContinue | Out-Null
        New-Item -Path $ffmpegFinalPath -ItemType Directory -ErrorAction SilentlyContinue | Out-Null
        # Extracts the three executables from the downloaded and unpacked folder.
        $exeFiles = Get-ChildItem -Path $ffmpegExtractedDirectory -Recurse -File | Where-Object { $_.Extension -eq ".exe" }
        $exeFiles | ForEach-Object {
            Copy-Item -Path $_.FullName -Destination $ffmpegFinalPath -Force -Recurse
        }
        # Cleaning up.
        Remove-Item -Path $ffmpegDownloadPath -Force -Recurse
        Remove-Item -Path $ffmpegExtractedDirectory -Force -Recurse

        $tmpLog = "[installFFmpeg()] [INFO] Extracted executables to $ffmpegFinalPath."
        log($tmpLog)
        Set-ItemProperty -Path $applicationRegistryPath -Name $ffmpegRegistryVariableName -Value "$ffmpegFinalPath\ffmpeg.exe"
        $tmpLog = "[installFFmpeg()] [INFO] Added FFmpeg executable path to registry at $applicationRegistryPath."
        log($tmpLog)
        $global:mainExitCode = 71603
    }
    else {
        $tmpLog = "[installFFmpeg()] [ERROR] There was an error while downloading FFmpeg. If this error persists please try to download it manually.`n`n$_`n`n"
        log($tmpLog)
        Start-Sleep -Seconds 5
        Exit 71505
    }
}

function uninstallFFmpeg() {
    $host.UI.RawUI.WindowTitle = "Removing FFmpeg files..."
    If (getFFmpegInstallStatus) {
        Try {
            # Removes the ffmpeg.exe from the path.
            $tmpPath = Split-Path $ffmpegPath -Parent
            Remove-Item -Path $tmpPath -Recurse -Confirm:$false
            $tmpLog = "[uninstallFFmpeg()] [INFO] Removed FFmpeg files from`n[$ffmpegPath]."
            log($tmpLog)
            $global:mainExitCode = 71604
            Try {
                Set-ItemProperty -Path $applicationRegistryPath -Name $ffmpegRegistryVariableName -Value ""
                $tmpLog = "[uninstallFFmpeg()] [INFO] Cleared FFmpeg location registry value."
                log($tmpLog)
            }
            Catch {
                $tmpLog = "[uninstallFFmpeg()] [WARNING] Could not wipe FFmpeg location registry value."
                log($tmpLog)
            }
        }
        Catch {
            $tmpLog = "[uninstallFFmpeg()] [ERROR] Failed to delete FFmpeg files in`n[$ffmpegPath]!`n`n$_`n`n"
            log($tmpLog)
            Start-Sleep -Seconds 5
            Exit 71506
        }
    }
    Else {
        $tmpLog = "[WARNING] FFmpeg is not installed!"
        log($tmpLog)
    }
}

# Returns true if FFmpeg has been found.
function getFFmpegInstallStatus() {
    Try {
        # This method looks up the possible FFmpeg path in the registry editor and checks if that path leads to a valid ffmpeg.exe file.
        $global:ffmpegPath = Get-ItemProperty -Path $applicationRegistryPath -Name $ffmpegRegistryVariableName -ErrorAction SilentlyContinue | Select-Object -ExpandProperty $ffmpegRegistryVariableName
        If ((validatePath($ffmpegPath)) -and (Test-Path -Path $ffmpegPath)) {
            Return $true   
        }
        # This is meant to be a fallback option for the method above. It only checks the hard-coded path in the current installation directory.
        ElseIf ((validatePath($ffmpegFinalPath)) -and (Test-Path -Path "$ffmpegFinalPath\ffmpeg.exe")) {
            # Fills the registry entry again because a valid FFmpeg file has been found.
            Set-ItemProperty -Path $applicationRegistryPath -Name $ffmpegRegistryVariableName -Value "$ffmpegFinalPath\ffmpeg.exe"
            $tmpLog = "[getFFmpegInstallStatus()] [INFO] Added FFmpeg executable path to registry at $applicationRegistryPath."
            log($tmpLog)
            Return $true
        }
        Else {
            Return $false
        }
    }
    Catch {
        $tmpLog = "[getFFmpegInstallStatus()] [ERROR] Error while checking FFmpeg path:`n`n$_`n`n"
        log($tmpLog)
        Return $false
    }
}

function log($pNewLogEntry, $pBooleanConsoleOutput = $true) {
    $global:logCounter++
    $logLine = "$global:logCounter. $pNewLogEntry"
    # Only if a log file location exists.
    If ($pLogFileLocation) {
        $logLine | Out-File -Append -FilePath $pLogFileLocation -ErrorAction Continue
    }
    If ($pBooleanConsoleOutput) {
        Write-Host $logLine
    }  
}

function validatePath([string]$pPath) {
    Try {
        $tmpPath = [System.IO.Path]::GetFullPath($pPath)
        # Write-Host "[PATH DEBUG] Normal: $pPath"
        # Write-Host "[PATH DEBUG] _Full_: $tmpPath"
        If ($tmpPath -ne $pPath) {
            Return $false
        }
        Else {
            Return $true
        }
    }
    Catch {
        Return $false
    }
}

onInit

#********************FFmpeg********************#
# Error code range: 71500 - 71999
<# Fatal errors:
71501 Invalid log file parameters.
71502 Invalid application path.
71503 Invalid setup parameters.
71504 FFmpeg already installed, no /install-force.
71505 FFmpeg download error.
71506 FFmpeg file delete error.

General:
71601 FFmpeg is installed.
71602 FFmpeg is not installed.
71603 FFmpeg successfully installed.
71604 FFmpeg successfully uninstalled. #>