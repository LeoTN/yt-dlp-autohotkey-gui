Param (
    [string]$pPythonInstallationDirectory,
    [string]$pLogFileLocation,    
    [string]$pSetupType
)
$Host.UI.RawUI.BackgroundColor = "Black"
$Host.UI.RawUI.ForegroundColor = "Green"
$host.UI.RawUI.WindowTitle = "yt-dlp setup script running..."
Clear-Host
Write-Host "Terminal ready..."

function onInit() {
    validateLogFileParameters
    updatePATH
    If (-not (getPythonInstallStatus)) {
        $tmpLog = "[onInit()] [WARNING] Python seems to be not installed. Please install it first before running this script."
        log($tmpLog)
        Start-Sleep -Seconds 5
        Exit 71001
    }
    # Default exit code.
    $global:mainExitCode = 71000
    $global:applicationRegistryPath = "HKCU:\SOFTWARE\LeoTN\VideoDownloader"
    $global:ytdlpDownloadLink = "https://github.com/yt-dlp/yt-dlp/archive/master.tar.gz"
    # This variable is used to store information about the current yt-dlp executable location.
    $global:ytdlpPath = ""
    # Calling this function will give a value to ytdlpPath.
    getYTDLPInstallStatus($true) | Out-Null
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
            Exit 71002
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
        If (validatePath($pPythonInstallationDirectory)) {
            $tmpLog = "[validateParameters()] [INFO] Python installation path exists."
            log($tmpLog)
        }
        Else {
            $tmpLog = "[validateParameters()] [ERROR] Python installation path doesn't exist. Please check if the given path`n[$pPythonInstallationDirectory] is correct."
            log($tmpLog)
            Start-Sleep -Seconds 5
            Exit 71003
        }
    }
    Catch {
        $tmpLog = "[validateParameters()] [ERROR] Python installation path doesn't exist. Please check if the given path [$pPythonInstallationDirectory] is correct."
        log($tmpLog)
        Start-Sleep -Seconds 5
        Exit 71003
    }
    
    Switch ($pSetupType) {
        '/install' { 
            $tmpLog = "[validateParameters()] [INFO] Starting yt-dlp installation..."
            log($tmpLog)
            installYTDLP
        }
        '/install-force' { 
            $tmpLog = "[validateParameters()] [INFO] Starting forced yt-dlp installation..."
            log($tmpLog)
            installYTDLP($true)
        }
        '/uninstall' {
            $tmpLog = "[validateParameters()] [INFO] Starting yt-dlp removal process..."
            log($tmpLog)
            uninstallYTDLP
        }
        '/check-installation-status' { 
            $tmpLog = "[validateParameters()] [INFO] Checking yt-dlp installation status..."
            log($tmpLog)
            $tmpValue = getYTDLPInstallStatus
            $tmpLog = "[validateParameters()] [INFO] yt-dlp installation status is: $tmpValue"
            log($tmpLog)
            If ($tmpValue) {
                # yt-dlp installed.
                $global:mainExitCode = 71103
            }
            Else {
                # yt-dlp not installed.
                $global:mainExitCode = 71104
            }
        }
        Default {
            $tmpLog = "[validateParameters()] [ERROR] Invalid parameter found: [$pSetupType]. '/install', '/install-force' or '/check-installation-status' are allowed only."
            log($tmpLog)
            Start-Sleep -Seconds 5
            Exit 71004
        }
    }
}

function installYTDLP([string]$pBooleanForceInstall = $false) {
    $host.UI.RawUI.WindowTitle = "Installing yt-dlp..."
    If (getYTDLPInstallStatus) {
        If ($pBooleanForceInstall -eq $false) {
            $tmpLog = "[installYTDLP()] [INFO] yt-dlp is already installed.`nUse '/install-force' to overwrite existing files."
            log($tmpLog)
            Start-Sleep -Seconds 5
            Exit 71005
        }
        ElseIf ($pBooleanForceInstall) {
            uninstallYTDLP
        }
    }
    py -m pip install $global:ytdlpDownloadLink
    If (getYTDLPInstallStatus) {
        addYTDLPToPath($pPythonInstallationDirectory)
        If ($pBooleanForceInstall -eq $false) {
            $tmpLog = "[installYTDLP()] [INFO] Successfully installed yt-dlp."
            log($tmpLog)
            $global:mainExitCode = 71101
        }
        ElseIf ($pBooleanForceInstall) {
            $tmpLog = "[installYTDLP()] [INFO] Successfully re-installed yt-dlp."
            log($tmpLog)
            $global:mainExitCode = 71107
        }  
    }
    Else {
        If ($pBooleanForceInstall -eq $false) {
            $tmpLog = "[installYTDLP()] [WARNING] There was an error while installing yt-dlp."
            log($tmpLog)
            $global:mainExitCode = 71102
        }
        ElseIf ($pBooleanForceInstall) {
            $tmpLog = "[installYTDLP()] [WARNING] There was an error while re-installing yt-dlp."
            log($tmpLog)
            $global:mainExitCode = 71108
        } 
    }
}

function uninstallYTDLP() {
    $host.UI.RawUI.WindowTitle = "Uninstalling yt-dlp..."
    If ((getYTDLPInstallStatus)) {
        py -m pip uninstall -y "yt-dlp"
        If (getYTDLPInstallStatus($true)) {
            If (validatePath($ytdlpPath)) {
                If (Test-Path -Path $ytdlpPath) {
                    Remove-Item -Path $ytdlpPath -Force
                }
            }
            $tmpLog = "[uninstallYTDLP()] [WARNING] There was an error while uninstalling yt-dlp."
            log($tmpLog)
            $global:mainExitCode = 71106
        }
        Else {
            $tmpLog = "[uninstallYTDLP()] [INFO] Successfully uninstalled yt-dlp."
            log($tmpLog)
            $global:mainExitCode = 71105
        }
    }
    Else {
        $tmpLog = "[uninstallYTDLP()] [WARNING] yt-dlp is not installed!"
        log($tmpLog)
        $global:mainExitCode = 71104
    }
}

# Adds the location of the yt-dlp.exe to the system environment variable PATH.
function addYTDLPToPath([string]$pPythonFolder) {
    If (-not (validatePath($pPythonFolder))) {
        $tmpLog = "[addYTDLPToPath()] [WARNING] The Python folder path`n[$pPythonFolder] does not exist!"
        log($tmpLog)
        Return $false
    }
    $ytdlpExecutable = Get-ChildItem -Path $pPythonFolder -Filter "yt-dlp.exe" -Recurse
    If ($ytdlpExecutable -eq $null) {
        $tmpLog = "[addYTDLPToPath()] [WARNING] Unable to locate 'yt-dlp.exe in`n[$pPythonFolder]!"
        log($tmpLog)
        Return $false
    }
    $ytdlpDirectoryParent = Split-Path -Path $ytdlpExecutable.FullName -Parent

    $currentPathSystem = [System.Environment]::GetEnvironmentVariable("PATH", [System.EnvironmentVariableTarget]::Machine)
    $currentPathUser = [System.Environment]::GetEnvironmentVariable('PATH', [System.EnvironmentVariableTarget]::User)
    # Checks if the path exists in the system environment variable 'PATH'.
    If ($currentPathSystem -notlike "*$ytdlpDirectoryParent*") {
        $newPath = "$currentPathSystem;$ytdlpDirectoryParent"
        Try {
            [System.Environment]::SetEnvironmentVariable("PATH", $newPath, [System.EnvironmentVariableTarget]::Machine)
            $tmpLog = "[addYTDLPToPath()] [INFO] System and environment variable 'PATH' has been modified successfully."
            log($tmpLog)
        }
        Catch {
            $tmpLog = "[addYTDLPToPath()] [WARNING] Unable to access system environment variables!"
            log($tmpLog)
        }
    }
    Else {
        $tmpLog = "[addYTDLPToPath()] [INFO] 'yt-dlp' seems to be already in the system environment variable 'PATH'."
        log($tmpLog)
    }
    # Checks if the path exists in the current user environment variable 'PATH'.
    If ($currentPathUser -notlike "*$ytdlpDirectoryParent*") {
        $newPath = "$currentPathUser;$ytdlpDirectoryParent"
        Try {
            [System.Environment]::SetEnvironmentVariable('PATH', $newPath, [System.EnvironmentVariableTarget]::User)
            # Updates the Path variable for the current PowerShell session.
            $env:Path = [System.Environment]::GetEnvironmentVariable('PATH', [System.EnvironmentVariableTarget]::User)
            $tmpLog = "[addYTDLPToPath()] [INFO] User environment variable 'PATH' has been modified successfully."
            log($tmpLog)
        }
        Catch {
            $tmpLog = "[addYTDLPToPath()] [WARNING] Unable to access user environment variables!"
            log($tmpLog)
        }
    }
    Else {
        $tmpLog = "[addYTDLPToPath()] [INFO] 'yt-dlp' seems to already be in the user environment variable 'PATH'."
        log($tmpLog)
    }
    updatePATH
}

# Returns true if yt-dlp has been found.
function getYTDLPInstallStatus($pBooleanNoRepair = $false) {   
    Try {
        Try {
            # Tries to find the location of the yt-dlp executable file.
            $exeObject = Get-Command 'yt-dlp.exe' -ErrorAction SilentlyContinue
            $ytdlpPathFound = $exeObject.Source
        }
        Catch {
            $ytdlpPathFound = "" 
        }
        If (($ytdlpPathFound -ne "") -and (validatePath($ytdlpPathFound))) {
            $global:ytdlpPath = $ytdlpPathFound
            Return $true
        }
        ElseIf ($pBooleanNoRepair -eq $false) {
            If (-not ($global:STATIC_r)) {
                # Recursion limit.
                $global:STATIC_r = 1
            }
            If ($STATIC_r -cgt 0) {
                $STATIC_r--
                $tmpLog = "[getYTDLPInstallStatus()] [WARNING] Unable to locate 'yt-dlp.exe'. Checking for missing 'PATH' entry..." 
                log($tmpLog)
                If ((addYTDLPToPath($pPythonInstallationDirectory)) -eq $false) {
                    Return $false
                }
                Else {
                    Return getYTDLPInstallStatus($pBooleanNoRepair)
                }
            }
            Else {
                $global:STATIC_r = 1
                Return $false
            } 
        }
        Else {
            Return $false
        }
    }
    Catch {
        $tmpLog = "[getYTDLPInstallStatus()] [ERROR] Error while checking yt-dlp presence:`n`n$_`n`n"
        log($tmpLog)
        Return $false
    }
}

function getPythonInstallStatus() {
    Try {
        # Type the py --version command and see if it responds a version or nothing.
        # I use a separate PowerShell window because it has access to the latest version of the PATH variable.
        $tmpWindow = New-Object System.Diagnostics.ProcessStartInfo
        $tmpWindow.FileName = "powershell"
        $tmpWindow.Arguments = "-Command py --version"

        $tmpPSProcess = New-Object System.Diagnostics.Process
        $tmpPSProcess.StartInfo = $tmpWindow
        $tmpPSProcess.StartInfo.RedirectStandardOutput = $true
        $tmpPSProcess.StartInfo.UseShellExecute = $false
        $tmpPSProcess.StartInfo.CreateNoWindow = $true

        $tmpPSProcess.Start() | Out-Null
        $tmpLog = $tmpPSProcess.StandardOutput.ReadToEnd()
        $tmpPSProcess.WaitForExit()

        # Usually, the string contains the word "Python 3.12".
        If ($tmpLog -like "*Python 3.12*") {
            Return $true
        }
        Else {
            Return $false
        }
    }
    Catch {
        $tmpLog = "[getPythonInstallStatus()] [ERROR] Error while checking Python presence:`n`n$_`n`n"
        log($tmpLog)
        Return $false
    }
}

# Updates the Path variables for the current PowerShell session.
function updatePATH() {
    $tmpLog = "[updatePATH()] [INFO] Updating PATH environment variables..."
    log($tmpLog)
    Try {
        $currentPathSystem = [System.Environment]::GetEnvironmentVariable('PATH', [System.EnvironmentVariableTarget]::Machine)
        [System.Environment]::SetEnvironmentVariable('PATH', $currentPathSystem, [System.EnvironmentVariableTarget]::Machine)
    }
    Catch {
        $tmpLog = "[updatePATH()] [WARNING] Unable to update system environment variable 'PATH'."
        log($tmpLog)
    }
    $currentPathUser = [System.Environment]::GetEnvironmentVariable('PATH', [System.EnvironmentVariableTarget]::User)
    [System.Environment]::SetEnvironmentVariable('PATH', $currentPathUser, [System.EnvironmentVariableTarget]::User)
    $env:Path = [System.Environment]::GetEnvironmentVariable('PATH', [System.EnvironmentVariableTarget]::User)
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
        # $tmp = "[PATH DEBUG] Normal: $pPath"
        # $tmp = "[PATH DEBUG] _Full_: $tmpPath"
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

#********************yt-dlp********************#
# Error code range: 71000 - 71499
<# Fatal errors:
71001 Python not installed.
71002 Invalid log file parameters.
71003 Invalid Python path.
71004 Invalid setup type parameters.
71005 yt-dlp already installed, no /install-force.

General:
71101 yt-dlp successfully installed.
71102 yt-dlp not successfully installed.
71103 yt-dlp installed.
71104 yt-dlp not installed.
71105 yt-dlp successfully uninstalled.
71106 yt-dlp not successfully uninstalled.
71107 yt-dlp successfully re-installed.
71108 yt-dlp not successfully re-installed. #>