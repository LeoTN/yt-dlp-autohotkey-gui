<#
.SYNOPSIS
	This script is a template that allows you to extend the toolkit with your own custom functions.
    # LICENSE #
    PowerShell App Deployment Toolkit - Provides a set of functions to perform common application deployment tasks on Windows.
    Copyright (C) 2017 - Sean Lillis, Dan Cunningham, Muhammad Mashwani, Aman Motazedian.
    This program is free software: you can redistribute it and/or modify it under the terms of the GNU Lesser General Public License as published by the Free Software Foundation, either version 3 of the License, or any later version. This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
    You should have received a copy of the GNU Lesser General Public License along with this program. If not, see <http://www.gnu.org/licenses/>.
.DESCRIPTION
	The script is automatically dot-sourced by the AppDeployToolkitMain.ps1 script.
.NOTES
    Toolkit Exit Code Ranges:
    60000 - 68999: Reserved for built-in exit codes in Deploy-Application.ps1, Deploy-Application.exe, and AppDeployToolkitMain.ps1
    69000 - 69999: Recommended for user customized exit codes in Deploy-Application.ps1
    70000 - 79999: Recommended for user customized exit codes in AppDeployToolkitExtensions.ps1
.LINK
	http://psappdeploytoolkit.com
#>
[CmdletBinding()]
Param (
)

##*===============================================
##* VARIABLE DECLARATION
##*===============================================

# Variables: Script
[string]$appDeployToolkitExtName = 'PSAppDeployToolkitExt'
[string]$appDeployExtScriptFriendlyName = 'App Deploy Toolkit Extensions'
[version]$appDeployExtScriptVersion = [version]'3.8.4'
[string]$appDeployExtScriptDate = '26/01/2021'
[hashtable]$appDeployExtScriptParameters = $PSBoundParameters

##*===============================================
##* FUNCTION LISTINGS
##*===============================================

# <Your custom functions go here>

##*===============================================
##* SETUP FUNCTIONS SECTION
##*===============================================

#****************VideoDownloader***************#

function installVideoDownloader($pVideoDownloaderInstallationDirectory, $pBooleanQuiet = $false) {
    Write-Log "`n`n[installVideoDownloader()] [INFO] pVideoDownloaderInstallationDirectory = $pVideoDownloaderInstallationDirectory`n`n"
    Write-Log "`n`n[installVideoDownloader()] [INFO] pBooleanQuiet = $pBooleanQuiet`n`n"
    Show-InstallationProgress -StatusMessage "Installing VideoDownloader. Please wait..." -TopMost $false

    $installedVideoDownloaderObject = Get-InstalledApplication -Name "VideoDownloader" -Exact
    If ($installedVideoDownloaderObject) {
        $installedVideoDownloaderLocation = $installedVideoDownloaderObject.InstallLocation
        Write-Log "`n`n[installVideoDownloader()] [INFO] Other potentially useful information:`n[$installedVideoDownloaderObject].`n`n"
        Write-Log "`n`n[installVideoDownloader()] [INFO] Found VideoDownloader installation at:`n[$installedVideoDownloaderLocation].`n`n"
        Write-Log "`n`n[installVideoDownloader()] [INFO] Stopped because VideoDownloader is already installed.`n`n"
        Return $true
    }
    Else {
        If ($pBooleanQuiet) {
            Execute-MSI -Action "Install" -Path $videoDownloaderInstallerLocation -Parameters "/quiet /norestart REBOOT=ReallySppress APPDIR=""$pVideoDownloaderInstallationDirectory"""
        }
        Else {
            Execute-MSI -Action "Install" -Path $videoDownloaderInstallerLocation -Parameters "/passive /norestart /qb! REBOOT=ReallySppress APPDIR=""$pVideoDownloaderInstallationDirectory"""
        }
        # Copy the .MSI installer to the target directory.
        $copyInstallerTargetDirectory = "$pVideoDownloaderInstallationDirectory\yt_dlp_autohotkey_gui_files\library\setup\Files\VideoDownloaderInstaller.msi"
        If (Test-Path -Path $copyInstallerTargetDirectory) {
            # Rename the old installer file so it won't be overwritten.
            Write-Log "`n`n[installVideoDownloader()] [INFO] Found existing VideoDownloaderInstaller.msi at`n[$copyInstallerTargetDirectory]`n`n"
            [String]$tmpDate = (Get-Date).ToString("dd_MM_yyyy_HH_mm_ss")
            Write-Host $tmpDate
            [String]$tmpFileName = "VideoDownloaderInstaller[OLD] - $tmpDate.msi"
            Rename-Item -Path $copyInstallerTargetDirectory -NewName $tmpFileName -Force
            Write-Log "`n`n[installVideoDownloader()] [INFO] Renamed existing VideoDownloaderInstaller.msi to`n[$tmpFileName]`n`n"
        }
        $copyInstallerTargetDirectoryParent = Split-Path -Path $copyInstallerTargetDirectory -Parent
        # Check if the directory exists. If not, create it.
        If (-not (Test-Path -Path $copyInstallerTargetDirectoryParent)) {
            New-Item -Path $copyInstallerTargetDirectoryParent
            Write-Log "`n`n[installVideoDownloader()] [INFO] Created path at`n[$copyInstallerTargetDirectoryParent]`n`n"
        }
        Copy-File -Path "$dirFiles\VideoDownloaderInstaller.msi" -Destination $copyInstallerTargetDirectoryParent
        Write-Log "`n`n[installVideoDownloader()] [INFO] Copied VideoDownloaderInstaller.msi to`n[$copyInstallerTargetDirectoryParent]`n`n"
        Return $true
    }
}

function uninstallVideoDownloader($pBooleanQuiet = $false) {
    Write-Log "`n`n[uninstallVideoDownloader()] [INFO] pBooleanQuiet = $pBooleanQuiet`n`n"
    Show-InstallationProgress -StatusMessage "Uninstalling VideoDownloader. Please wait..." -TopMost $false

    $installedVideoDownloaderObject = Get-InstalledApplication -Name "VideoDownloader" -Exact
    If ($installedVideoDownloaderObject) {
        $installedVideoDownloaderLocation = $installedVideoDownloaderObject.InstallLocation
        Write-Log "`n`n[uninstallVideoDownloader()] [INFO] Other potentially useful information:`n[$installedVideoDownloaderObject].`n`n"
        Write-Log "`n`n[uninstallVideoDownloader()] [INFO] Found VideoDownloader installation at:`n[$installedVideoDownloaderLocation].`n`n"
        If ($pBooleanQuiet) {
            Execute-MSI -Action "Uninstall" -Path $installedVideoDownloaderObject.ProductCode -Parameters "/quiet /norestart REBOOT=ReallySppress"
        }
        Else {
            Execute-MSI -Action "Uninstall" -Path $installedVideoDownloaderObject.ProductCode -Parameters "/passive /norestart /qb! REBOOT=ReallySppress"
        }
        # Remove the .MSI installer from the target directory.
        $copiedInstallerTargetDirectory = "$pVideoDownloaderInstallationDirectory\yt_dlp_autohotkey_gui_files\library\setup\Files\VideoDownloaderInstaller.msi"
        If (Test-Path -Path $copiedInstallerTargetDirectory) {
            Remove-File -Path $copiedInstallerTargetDirectory
            Write-Log "`n`n[uninstallVideoDownloader()] [INFO] Deleted VideoDownloaderInstaller.msi at`n[$copiedInstallerTargetDirectory]`n`n"
        }
        Else {
            $copiedInstallerTargetDirectoryParent = Split-Path -Path $copiedInstallerTargetDirectory -Parent
            Write-Log "`n`n[uninstallVideoDownloader()] [INFO] Couldn't find VideoDownloaderInstaller.msi at`n[$copiedInstallerTargetDirectoryParent]`n`n"
        }
        Return $true
    }
    Else {
        Write-Log "`n`n[uninstallVideoDownloader()] [INFO] Unable to find installed VideoDownloader instance.`n`n"
        Return $false
    }
}

function repairVideoDownloader($pBooleanQuiet = $false) {
    Write-Log "`n`n[repairVideoDownloader()] [INFO] pBooleanQuiet = $pBooleanQuiet`n`n"
    Show-InstallationProgress -StatusMessage "Repairing VideoDownloader. Please wait..." -TopMost $false

    $installedVideoDownloaderObject = Get-InstalledApplication -Name "VideoDownloader" -Exact
    If ($installedVideoDownloaderObject) {
        $installedVideoDownloaderLocation = $installedVideoDownloaderObject.InstallLocation
        Write-Log "`n`n[repairVideoDownloader()] [INFO] Other potentially useful information:`n[$installedVideoDownloaderObject].`n`n"
        Write-Log "`n`n[repairVideoDownloader()] [INFO] Found VideoDownloader installation at:`n[$installedVideoDownloaderLocation].`n`n"
        If ($pBooleanQuiet) {
            Execute-MSI -Action "Repair" -Path $installedVideoDownloaderObject.ProductCode -Parameters "/quiet /norestart REBOOT=ReallySppress"
        }
        Else {
            Execute-MSI -Action "Repair" -Path $installedVideoDownloaderObject.ProductCode -Parameters "/passive /norestart /qb! REBOOT=ReallySppress"
        }
        Return $true
    }
    Else {
        Write-Log "`n`n[repairVideoDownloader()] [INFO] Unable to find installed VideoDownloader instance.`n`n"
        # Language support needed.
        $balloonText = "No installed VideoDownloader instance found. Please run the installer afterwards."
        $balloonTitle = "VideoDownloader Repair Status"
        Show-BalloonTip -BalloonTipText $balloonText -BalloonTipTitle $balloonTitle -BalloonTipIcon "Warning"
        Return $false
    }
}

#********************Python********************#

function installPython($pPythonInstallDirectory, $pBooleanQuiet = $false) {
    Write-Log "`n`n[installPython()] [INFO] pPythonInstallDirectory = $pPythonInstallDirectory`n`n"
    Write-Log "`n`n[installPython()] [INFO] pBooleanQuiet = $pBooleanQuiet`n`n"
    Show-InstallationProgress -StatusMessage "Checking system requirements for Python 3.12.0. Please wait..." -TopMost $false

    If (getBooleanReturn(getPythonInstallStatus)) {
        $installedPythonObject = Get-InstalledApplication -Name "Python 3.12"
        If ($installedPythonObject) {
            $installedPythonLocation = $installedPythonObject.InstallLocation
            Write-Log "`n`n[installPython()] [INFO] Other potentially useful information:`n[$installedPythonObject].`n`n"
            Write-Log "`n`n[installPython()] [INFO] Found Python 3.12.x installation at:`n[$installedPythonLocation].`n`n"
            Write-Log "`n`n[installPython()] [INFO] Stopped because a matching Python instance is already installed.`n`n"
            Return $true
        }
        Else {
            Write-Log "`n`n[installPython()] [WARNING] Python launcher is already installed but running a repair action is recommended due to missing Python 3.12.`n`n"
            # Language support needed.
            $balloonText = "Python installation seems corrupted. It is recommended to repair the VideoDownloader installation afterwards."
            $balloonTitle = "Python Installation Status"
            Show-BalloonTip -BalloonTipText $balloonText -BalloonTipTitle $balloonTitle -BalloonTipIcon "Warning"
            Return $true
        }
    }
    Else {
        If (getBooleanReturn(checkPythonInstallerFilesPresence)) {
            $exePath64 = Get-ChildItem -Path "$dirFiles" -Include "python-3*amd64.exe" -File -Recurse -ErrorAction SilentlyContinue
            $exePath32 = Get-ChildItem -Path "$dirFiles" -Include "python-3*.exe" -Exclude "python-3*amd64.exe" -File -Recurse -ErrorAction SilentlyContinue
            If ($pBooleanQuiet) {
                $parameterString = "/quiet TargetDir=""$pPythonInstallDirectory"" Include_launcher=1"
            }
            Else {
                $parameterString = "/passive TargetDir=""$pPythonInstallDirectory"" Include_launcher=1"
            }
            If ($ENV:PROCESSOR_ARCHITECTURE -eq "x86") {
                Write-Log "`n`n[installPython()] [INFO] Detected 32-bit OS architecture.`n`n"
                # Install Python 3.12 (32-bit).
                If ($exePath32.Exists) {
                    Write-Log "`n`n[installPython()] [INFO] Found $($exePath32.FullName), now attempting to install Python 3.12.0 (32-bit).`n`n"     
                    Show-InstallationProgress -StatusMessage "Installing Python 3.12.0 (32-bit). This might take some time. Please wait..." -TopMost $false
                    Execute-ProcessAsUser -Path "$exePath32" -Parameters $parameterString -Wait
                }     
            }
            Else {
                Write-Log "`n`n[installPython()] [INFO] Detected 64-bit OS architecture.`n`n"
                # Install Python 3.12 (64-bit).
                If ($exePath64.Exists) {
                    Write-Log "`n`n[installPython()] [INFO] Found $($exePath64.FullName), now attempting to install Python 3.12.0 (64-bit).`n`n"              
                    Show-InstallationProgress -StatusMessage "Installing Python 3.12.0 (64-bit). This might take some time. Please wait..." -TopMost $false
                    Execute-ProcessAsUser -Path "$exePath64" -Parameters $parameterString -Wait
                }
                # Install Python 3.12 (32-bit) if 64-bit installer is not available.     
                ElseIf ($exePath32.Exists) {
                    Write-Log "`n`n[installPython()] [INFO] Found $($exePath32.FullName), now attempting to install Python 3.12.0 (32-bit).`n`n"     
                    Show-InstallationProgress -StatusMessage "Installing Python 3.12.0 (32-bit). This might take some time. Please wait..." -TopMost $false
                    Execute-ProcessAsUser -Path "$exePath32" -Parameters $parameterString -Wait
                }
            }
            Return $true
        }
        Else {
            Write-Log "`n`n[installPython()] [WARNING] Stopped because the Python installer files are missing!`n`n"
            # Language support needed.
            $balloonText = "Python installation stopped due to missing installer files!"
            $balloonTitle = "Python Installation Status"
            Show-BalloonTip -BalloonTipText $balloonText -BalloonTipTitle $balloonTitle -BalloonTipIcon "Warning"
            Return $false
        }
    }
}

function uninstallPython() {
    Show-InstallationProgress -StatusMessage "Uninstalling Python 3.12.0. This might take some time. Please wait..." -TopMost $false

    $installedPythonObject = Get-InstalledApplication -Name "Python 3.12.0"    
    If ($installedPythonObject) {
        $installedPythonLocation = $installedPythonObject.InstallLocation
        Write-Log "`n`n[uninstallPython()] [INFO] Other potentially useful information:`n[$installedPythonObject].`n`n"
        Write-Log "`n`n[uninstallPython()] [INFO] Found Python 3.12.0 installation at:`n[$installedPythonLocation].`n`n"
        Write-Log "`n`n[uninstallPython()] [INFO] Starting Python 3.12 uninstallation.`n`n"
        uninstallAllPythonCompletly
        Return $true
    }
    Else {
        Write-Log "`n`n[uninstallPython()] [INFO] Unable to find installed Python 3.12.0 instance(s).`n`n"
        Return $false
    }
}

function repairPython($pPythonInstallDirectory, $pBooleanQuiet = $false) {
    Write-Log "`n`n[repairPython()] [INFO] pBooleanQuiet = $pBooleanQuiet`n`n"
    Show-InstallationProgress -StatusMessage "Repairing Python 3.12.0. This might take some time. Please wait..." -TopMost $false

    $installedPythonObject = Get-InstalledApplication -Name "Python 3.12.0"
    If ($installedPythonObject) {
        $installedPythonLocation = $installedPythonObject.InstallLocation
        Write-Log "`n`n[repairPython()] [INFO] Other potentially useful information:`n[$installedPythonObject].`n`n"
        Write-Log "`n`n[repairPython()] [INFO] Found Python 3.12.0 installation at:`n[$installedPythonLocation].`n`n"
        Write-Log "`n`n[repairPython()] [INFO] Starting Python 3.12 repair.`n`n"
        If (checkPythonInstallerFilesPresence) {
            $exePath64 = Get-ChildItem -Path "$dirFiles" -Include "python-3*amd64.exe" -File -Recurse -ErrorAction SilentlyContinue
            $exePath32 = Get-ChildItem -Path "$dirFiles" -Include "python-3*.exe" -Exclude "python-3*amd64.exe" -File -Recurse -ErrorAction SilentlyContinue
            If ($pBooleanQuiet) {
                $parameterString = "/quiet /repair"
            }
            Else {
                $parameterString = "/passive /repair"
            }
            If ($installedPythonObject.Is64BitApplication) {
                Write-Log "`n`n[repairPython()] [INFO] Found Python 3.12.0 (64-bit).`n`n"
                # Repair Python 3.12 (64-bit).
                If ($exePath64.Exists) {
                    Write-Log "`n`n[repairPython()] [INFO] Found $($exePath64.FullName), now attempting to repair Python 3.12.0 (64-bit).`n`n"              
                    Show-InstallationProgress -StatusMessage "Repairing Python 3.12.0 (64-bit). This might take some time. Please wait..." -TopMost $false
                    Execute-ProcessAsUser -Path "$exePath64" -Parameters $parameterString -Wait
                }
            }
            Else {
                Write-Log "`n`n[repairPython()] [INFO] Found Python 3.12.0 (32-bit).`n`n"
                # Repair Python 3.12 (32-bit).
                If ($exePath32.Exists) {
                    Write-Log "`n`n[repairPython()] [INFO] Found $($exePath32.FullName), now attempting to repair Python 3.12.0 (32-bit).`n`n"              
                    Show-InstallationProgress -StatusMessage "Repairing Python 3.12.0 (32-bit). This might take some time. Please wait..." -TopMost $false
                    Execute-ProcessAsUser -Path "$exePath32" -Parameters $parameterString -Wait
                }
            }
            Return $true
        }
    }
    Else {
        Write-Log "`n`n[repairPython()] [INFO] Unable to find installed Python 3.12.0 instance. Running installPython()...`n`n"
        # Language support needed.
        $balloonText = "No installed Python 3.12.0 instance found. Running installer now."
        $balloonTitle = "Python Repair Status"
        Show-BalloonTip -BalloonTipText $balloonText -BalloonTipTitle $balloonTitle -BalloonTipTime 5000
        # If the Python installation succeeds.
        If (getBooleanReturn(installPython -pPythonInstallDirectory $pythonInstallDirectory -pBooleanQuiet $pBooleanQuiet)) {
            Write-Log "`n`n[repairPython()] [INFO] Installed Python successfully.`n`n"
            Return $true
        }
        Else {
            Write-Log "`n`n[repairPython()] [INFO] Could not install Python successfully.`n`n"
            Return $false
        }
    }
}

function getPythonInstallStatus() {
    updatePATH
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
        $tmp = $tmpPSProcess.StandardOutput.ReadToEnd()
        $tmpPSProcess.WaitForExit()

        # Usually, the string contains the word "Python 3.12".
        If ($tmp -like "*Python 3.12*") {
            Return $true
        }
        Else {
            Return $false
        }
    }
    Catch {
        Write-Host "`n`n[getPythonInstallStatus()] [ERROR] Error while checking Python presence:`n[$_]`n`n"
        Return $false
    }
}

function checkPythonInstallerFilesPresence([boolean]$pBooleanNoDownload = $false) {
    $pythonInstallerFinaDirectory = "$dirFiles"
    $pythonInstaller32Name = "python-3.12.0.exe"
    $pythonInstaller64Name = "python-3.12.0-amd64.exe"
    $pythonInstaller32DownloadLink = "https://www.python.org/ftp/python/3.12.0/python-3.12.0.exe"
    $pythonInstaller64DownloadLink = "https://www.python.org/ftp/python/3.12.0/python-3.12.0-amd64.exe"
    If ($ENV:PROCESSOR_ARCHITECTURE -eq "x86") {
        Write-Log "`n`n[checkPythonInstallerFilesPresence()] [INFO] Detected 32-bit OS architecture.`n`n"
        $booleanIs64BitArchitecture = $false
                    
    }
    Else {
        Write-Log "`n`n[checkPythonInstallerFilesPresence()] [INFO] Detected 64-bit OS architecture.`n`n"
        $booleanIs64BitArchitecture = $true
    }
    Write-Log "`n`n[checkPythonInstallerFilesPresence()] [INFO] pBooleanNoDownload = $pBooleanNoDownload)`n`n"
    Write-Log "`n`n[checkPythonInstallerFilesPresence()] [INFO] pythonInstallerFinalPath = $pythonInstallerFinaDirectory)`n`n"
    Write-Log "`n`n[checkPythonInstallerFilesPresence()] [INFO] pythonInstaller32Name = $pythonInstaller32Name`n`n"
    Write-Log "`n`n[checkPythonInstallerFilesPresence()] [INFO] pythonInstaller64Name = $pythonInstaller64Name`n`n"
    Write-Log "`n`n[checkPythonInstallerFilesPresence()] [INFO] pythonInstaller32DownloadLink = $pythonInstaller32DownloadLink`n`n"
    Write-Log "`n`n[checkPythonInstallerFilesPresence()] [INFO] pythonInstaller64DownloadLink = $pythonInstaller64DownloadLink`n`n"
    If (-not (getBooleanReturn(validatePath($pythonInstallerFinaDirectory)))) {
        Write-Log "`n`n[checkPythonInstallerFilesPresence()] [ERROR] Invalid Python installer path found:`n[$pythonInstallerFinaDirectory]!`n`n"
        Return $false
    }
    # Test if both the 32 and 64 bit executables are present and starts the download if not.
    # 32 bit section.
    If (-not (Test-Path -Path "$pythonInstallerFinaDirectory\$pythonInstaller32Name")) {
        Write-Log "`n`n[checkPythonInstallerFilesPresence()] [WARNING] Missing Python 32 bit setup executable."
        If ($pBooleanNoDownload) {
            Return $false
        }
        ElseIf ($booleanIs64BitArchitecture) {
            Write-Log "`n`n[checkPythonInstallerFilesPresence()] [INFO] Skipping download because the 32 bit setup executable is irrelevant due to the wrong system architecture."
        }
        Else {
            Write-Log "`n`n[checkPythonInstallerFilesPresence()] [INFO] Starting python 32 bit setup executable download...`n`n"
            If (-not (getBooleanReturn(checkInternetConnectionStatus))) {
                Write-Log "`n`n[checkPythonInstallerFilesPresence()] [WARNING] No active Internet connection found for downloading installer.`n`n"
                # Language support needed.
                $balloonText = "No Internet connection found. Operation could not complete."
                $balloonTitle = "Python Installation Status"
                Show-BalloonTip -BalloonTipText $balloonText -BalloonTipTitle $balloonTitle -BalloonTipTime 5000 -BalloonTipIcon "Warning"
                Return $false
            }
            Try {
                Show-InstallationProgress -StatusMessage "Downloading Python installer. Please wait..." -TopMost $false
                Invoke-WebRequest -Uri $pythonInstaller32DownloadLink -OutFile "$pythonInstallerFinaDirectory\$pythonInstaller32Name"
                Write-Log "`n`n[checkPythonInstallerFilesPresence()] [INFO] Downloaded 32 bit executable to`n[$pythonInstallerFinaDirectory].`n`n"
            }
            Catch {
                Write-Log "`n`n[checkPythonInstallerFilesPresence()] [WARNING] Error while downloading 32 bit setup executable!`n`n"
                Return $false
            } 
        }
    }
    Else {
        Write-Log "`n`n[checkPythonInstallerFilesPresence()] [INFO] Found 32 bit executable at`n[$pythonInstallerFinaDirectory\$pythonInstaller32Name].`n`n"
    }
    # 64 bit section.
    If (-not (Test-Path -Path "$pythonInstallerFinaDirectory\$pythonInstaller64Name")) {
        Write-Log "`n`n[checkPythonInstallerFilesPresence()] [WARNING] Missing Python 64 bit setup executable."
        If ($pBooleanNoDownload) {
            Return $false
        }
        ElseIf ($booleanIs64BitArchitecture) {
            Write-Log "`n`n[checkPythonInstallerFilesPresence()] [INFO] Skipping download because the 64 bit setup executable is irrelevant due to the wrong system architecture."
        }
        Else {
            Write-Log "`n`n[checkPythonInstallerFilesPresence()] [INFO] Starting python 64 bit setup executable download...`n`n"
            If (-not (getBooleanReturn(checkInternetConnectionStatus))) {
                Write-Log "`n`n[checkPythonInstallerFilesPresence()] [WARNING] No active Internet connection found for downloading installer.`n`n"
                # Language support needed.
                $balloonText = "No Internet connection found. Operation could not complete."
                $balloonTitle = "Python Installation Status"
                Show-BalloonTip -BalloonTipText $balloonText -BalloonTipTitle $balloonTitle -BalloonTipTime 5000 -BalloonTipIcon "Warning"
                Return $false
            }
            Try {
                Show-InstallationProgress -StatusMessage "Downloading Python installer. Please wait..." -TopMost $false
                Invoke-WebRequest -Uri $pythonInstaller64DownloadLink -OutFile "$pythonInstallerFinaDirectory\$pythonInstaller64Name"
                Write-Log "`n`n[checkPythonInstallerFilesPresence()] [INFO] Downloaded 64 bit executable to`n[$pythonInstallerFinaDirectory].`n`n"
            }
            Catch {
                Write-Log "`n`n[checkPythonInstallerFilesPresence()] [WARNING] Error while downloading 64 bit setup executable!`n`n"
                Return $false
            } 
        }
    }
    Else {
        Write-Log "`n`n[checkPythonInstallerFilesPresence()] [INFO] Found 64 bit executable at`n[$pythonInstallerFinaDirectory\$pythonInstaller32Name].`n`n"
    }
    Return $true
}

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

function installYTDLP($pPythonInstallationDirectory, $pBooleanQuiet = $false) {
    Write-Log "`n`n[installYTDLP()] [INFO] pPythonInstallationDirectory = $pPythonInstallationDirectory`n`n"
    Write-Log "`n`n[installYTDLP()] [INFO] pBooleanQuiet = $pBooleanQuiet`n`n" 
    Show-InstallationProgress -StatusMessage "Running yt-dlp setup script (install). Please wait..." -TopMost $false # CAUSES ERROR WITH RETURN $false and $true !!!

    Write-Log "`n`n**********[yt-dlp Setup Script START]**********`n`n"
    If (-not (Test-Path -Path $ytdlpSetupScriptLocation)) {
        Write-Log "`n`n[installYTDLP()] [ERROR] Could not find yt-dlp setup script at`n[$ytdlpSetupScriptLocation]!`n`n"
        Return $false
    }
    # If yt-dlp is installed.
    ElseIf (getBooleanReturn(checkYTDLPInstallationStatus -pPythonInstallationDirectory $pPythonInstallationDirectory -pBooleanQuiet $pBooleanQuiet)) {
        Write-Log "`n`n[installYTDLP()] [INFO] Stopped because yt-dlp is already installed.`n`n"
        Return $true
    }
    Else {
        If ($pBooleanQuiet) {
            $optionalQuietWindowParameter = "Hidden"
        }
        Else {
            $optionalQuietWindowParameter = "Normal"
        }
        If (-not (getBooleanReturn(checkInternetConnectionStatus))) {
            Write-Log "`n`n[installYTDLP()] [WARNING] No active Internet connection found for downloading yt-dlp.`n`n"
            $balloonText = "No Internet connection found. Operation could not complete."
            $balloonTitle = "yt-dlp Installation Status"
            Show-BalloonTip -BalloonTipText $balloonText -BalloonTipTitle $balloonTitle -BalloonTipTime 5000 -BalloonTipIcon "Warning"
            Return $false
        }
        # Install yt-dlp START.
        Write-Log "`n`n[installYTDLP()] [INFO] Starting yt-dlp installation.`n`n"

        $setupScriptLogFilePath = "$envTemp" + "yt-dlpSetup.ps1_LOG.txt"
        $parameterString1 = "-pPythonInstallationDirectory ""$pPythonInstallationDirectory"" -pLogFileLocation ""$setupScriptLogFilePath"" -pSetupType ""/install"""
        $parameterString2 = "-executionPolicy bypass -file ""$ytdlpSetupScriptLocation"" $parameterString1"
        $process = Start-Process "powershell.exe" -ArgumentList "$parameterString2" -PassThru -Wait -WindowStyle $optionalQuietWindowParameter

        $scriptStdOut = Get-Content $setupScriptLogFilePath -Raw -ErrorAction Continue
        $exitCode = [string]$process.ExitCode

        Write-Log "----------`n`n$scriptStdOut`n`n----------"
        Write-Log "`n`n[installYTDLP()] [INFO] Setup script exit code = $exitCode`n`n"
        # Fatal error code range.
        If (($exitCode -ge 71001) -and ($exitCode -le 71100)) {
            Write-Log "`n`n[installYTDLP()] [ERROR] A fatal error occurred [Exit Code = $exitCode].`n`n"
            Return $false
        }
        # Normal error code range.
        ElseIf (($exitCode -ge 71101) -and ($exitCode -le 71200)) {
            Write-Log "`n`n[installYTDLP()] [INFO] Normal exit code received [Exit Code = $exitCode].`n`n"
            # True when yt-dlp was successfully installed.
            If ($exitCode -eq 71101) {
                If (getBooleanReturn(checkYTDLPInstallationStatus -pPythonInstallationDirectory $pPythonInstallationDirectory -pBooleanQuiet $pBooleanQuiet)) {
                    Write-Log "`n`n[installYTDLP()] [INFO] yt-dlp has been successfully installed.`n`n"
                    Return $true
                }
                Else {
                    Write-Log "`n`n[installYTDLP()] [WARNING] yt-dlp has not been successfully installed.`n`n"
                    Return $false
                }
            }
            Else {
                Write-Log "`n`n[installYTDLP()] [WARNING] yt-dlp has not been successfully installed.`n`n"
                Return $false
            }
        }
        Else {
            Write-Log "`n`n[installYTDLP()] [WARNING] Unknown exit code received [Exit Code = $exitCode]!`n`n"
            Return $false
        }
        # Install yt-dlp END.
    }
    Write-Log "`n`n**********[yt-dlp Setup Script END]**********`n`n"
}

function uninstallYTDLP($pPythonInstallationDirectory, $pBooleanQuiet = $false) {
    Write-Log "`n`n[uninstallYTDLP()] [INFO] pPythonInstallationDirectory = $pPythonInstallationDirectory`n`n"
    Write-Log "`n`n[uninstallYTDLP()] [INFO] pBooleanQuiet = $pBooleanQuiet`n`n" 
    Show-InstallationProgress -StatusMessage "Running yt-dlp setup script (uninstall). Please wait..." -TopMost $false

    Write-Log "`n`n**********[yt-dlp Setup Script START]**********`n`n"
    If (-not (Test-Path -Path $ytdlpSetupScriptLocation)) {
        Write-Log "`n`n[uninstallYTDLP()] [ERROR] Could not find yt-dlp setup script at`n[$ytdlpSetupScriptLocation]!`n`n"
        Return $false
    }
    # If yt-dlp is installed.
    ElseIf (getBooleanReturn(checkYTDLPInstallationStatus -pPythonInstallationDirectory $pPythonInstallationDirectory -pBooleanQuiet $pBooleanQuiet)) {
        If ($pBooleanQuiet) {
            $optionalQuietWindowParameter = "Hidden"
        }
        Else {
            $optionalQuietWindowParameter = "Normal"
        }
        # Uninstall yt-dlp START.
        Write-Log "`n`n[uninstallYTDLP()] [INFO] Starting yt-dlp uninstallation.`n`n"
        $setupScriptLogFilePath = "$envTemp" + "yt-dlpSetup.ps1_LOG.txt"
        $parameterString1 = "-pPythonInstallationDirectory ""$pPythonInstallationDirectory"" -pLogFileLocation ""$setupScriptLogFilePath"" -pSetupType ""/uninstall"""
        $parameterString2 = "-executionPolicy bypass -file ""$ytdlpSetupScriptLocation"" $parameterString1"
        $process = Start-Process "powershell.exe" -ArgumentList "$parameterString2" -PassThru -Wait -WindowStyle $optionalQuietWindowParameter

        $scriptStdOut = Get-Content $setupScriptLogFilePath -Raw -ErrorAction Continue
        $exitCode = [string]$process.ExitCode

        Write-Log "----------`n`n$scriptStdOut`n`n----------"
        Write-Log "`n`n[uninstallYTDLP()] [INFO] Setup script exit code = $exitCode`n`n"
        # Fatal error code range.
        If (($exitCode -ge 71001) -and ($exitCode -le 71100)) {
            Write-Log "`n`n[uninstallYTDLP()] [ERROR] A fatal error occurred [Exit Code = $exitCode].`n`n"
            Return $false
        }
        # Normal error code range.
        ElseIf (($exitCode -ge 71101) -and ($exitCode -le 71200)) {
            Write-Log "`n`n[uninstallYTDLP()] [INFO] Normal exit code received [Exit Code = $exitCode].`n`n"
            # True when yt-dlp was successfully uninstalled.
            If ($exitCode -eq 71105) {
                If (getBooleanReturn(checkYTDLPInstallationStatus -pPythonInstallationDirectory $pPythonInstallationDirectory -pBooleanQuiet $pBooleanQuiet)) {
                    Write-Log "`n`n[uninstallYTDLP()] [WARNING] yt-dlp has not been successfully uninstalled.`n`n"
                    Return $false   
                }
                Else {
                    Write-Log "`n`n[uninstallYTDLP()] [INFO] yt-dlp has been successfully uninstalled.`n`n"
                    Return $true 
                }
            }
            Else {
                Write-Log "`n`n[uninstallYTDLP()] [WARNING] yt-dlp has not been successfully uninstalled.`n`n"
                Return $false
            }
        }
        Else {
            Write-Log "`n`n[uninstallYTDLP()] [WARNING] Unknown exit code received [Exit Code = $exitCode]!`n`n"
            Return $false
        }
        # Uninstall yt-dlp END.
    }
    Else {
        Write-Log "`n`n[uninstallYTDLP()] [INFO] Stopped because yt-dlp is not installed.`n`n"
        Return $false
    }
    Write-Log "`n`n**********[yt-dlp Setup Script END]**********`n`n"
}

function repairYTDLP($pPythonInstallationDirectory, $pBooleanQuiet = $false) {
    Write-Log "`n`n[repairYTDLP()] [INFO] pPythonInstallationDirectory = $pPythonInstallationDirectory`n`n"
    Write-Log "`n`n[repairYTDLP()] [INFO] pBooleanQuiet = $pBooleanQuiet`n`n" 
    Show-InstallationProgress -StatusMessage "Running yt-dlp setup script (repair). Please wait..." -TopMost $false

    Write-Log "`n`n**********[yt-dlp Setup Script START]**********`n`n"
    If (-not (Test-Path -Path $ytdlpSetupScriptLocation)) {
        Write-Log "`n`n[repairYTDLP()] [ERROR] Could not find yt-dlp setup script at`n[$ytdlpSetupScriptLocation]!`n`n"
        Return $false
    }
    # If yt-dlp is installed.
    ElseIf (getBooleanReturn(checkYTDLPInstallationStatus -pPythonInstallationDirectory $pPythonInstallationDirectory -pBooleanQuiet $pBooleanQuiet)) {
        If ($pBooleanQuiet) {
            $optionalQuietWindowParameter = "Hidden"
        }
        Else {
            $optionalQuietWindowParameter = "Normal"
        }
        # Repair yt-dlp START.
        Write-Log "`n`n[repairYTDLP()] [INFO] Starting yt-dlp repair.`n`n"
        $setupScriptLogFilePath = "$envTemp" + "yt-dlpSetup.ps1_LOG.txt"
        $parameterString1 = "-pPythonInstallationDirectory ""$pPythonInstallationDirectory"" -pLogFileLocation ""$setupScriptLogFilePath"" -pSetupType ""/install-force"""
        $parameterString2 = "-executionPolicy bypass -file ""$ytdlpSetupScriptLocation"" $parameterString1"
        $process = Start-Process "powershell.exe" -ArgumentList "$parameterString2" -PassThru -Wait -WindowStyle $optionalQuietWindowParameter

        $scriptStdOut = Get-Content $setupScriptLogFilePath -Raw -ErrorAction Continue
        $exitCode = [string]$process.ExitCode

        Write-Log "----------`n`n$scriptStdOut`n`n----------"
        Write-Log "`n`n[repairYTDLP()] [INFO] Setup script exit code = $exitCode`n`n"
        # Fatal error code range.
        If (($exitCode -ge 71001) -and ($exitCode -le 71100)) {
            Write-Log "`n`n[repairYTDLP()] [ERROR] A fatal error occurred [Exit Code = $exitCode].`n`n"
            Return $false
        }
        # Normal error code range.
        ElseIf (($exitCode -ge 71101) -and ($exitCode -le 71200)) {
            Write-Log "`n`n[repairYTDLP()] [INFO] Normal exit code received [Exit Code = $exitCode].`n`n"
            # True when yt-dlp was successfully re-installed.
            If ($exitCode -eq 71107) {
                If (getBooleanReturn(checkYTDLPInstallationStatus -pPythonInstallationDirectory $pPythonInstallationDirectory -pBooleanQuiet $pBooleanQuiet)) {
                    Write-Log "`n`n[repairYTDLP()] [INFO] yt-dlp has been successfully re-installed.`n`n" 
                    Return $true 
                }
                Else {
                    Write-Log "`n`n[repairYTDLP()] [WARNING] yt-dlp has not been successfully re-installed.`n`n"
                    Return $false
                }
            }
            Else {
                Write-Log "`n`n[repairYTDLP()] [WARNING] yt-dlp has not been successfully re-installed.`n`n"
                Return $false
            }
        }
        Else {
            Write-Log "`n`n[repairYTDLP()] [WARNING] Unknown exit code received [Exit Code = $exitCode]!`n`n"
            Return $false
        }
        # Repair yt-dlp END.
    }
    Else {
        Write-Log "`n`n[repairYTDLP()] [INFO] Stopped because yt-dlp is not installed. Running installYTDLP()...`n`n"
        # Language support needed.
        $balloonText = "No installed yt-dlp instance found. Running installer now."
        $balloonTitle = "yt-dlp Repair Status"
        Show-BalloonTip -BalloonTipText $balloonText -BalloonTipTitle $balloonTitle -BalloonTipTime 5000
        # If the yt-dlp installation succeeds.
        If (getBooleanReturn(installYTDLP -pPythonInstallationDirectory $pPythonInstallationDirectory -pBooleanQuiet $pBooleanQuiet)) {
            Write-Log "`n`n[repairYTDLP()] [INFO] Installed yt-dlp successfully.`n`n"
            Return $true
        }
        Else {
            Write-Log "`n`n[repairYTDLP()] [INFO] Could not install yt-dlp successfully.`n`n"
            Return $false
        }
    }
    Write-Log "`n`n**********[yt-dlp Setup Script END]**********`n`n"
}

function checkYTDLPInstallationStatus($pPythonInstallationDirectory, $pBooleanQuiet = $false) {
    Write-Log "`n`n[checkYTDLPInstallationStatus()] [INFO] Checking yt-dlp installation status.`n`n"
    If ($pBooleanQuiet) {
        $optionalQuietWindowParameter = "Hidden"
    }
    Else {
        $optionalQuietWindowParameter = "Normal"
    }
    $setupScriptLogFilePath = "$envTemp" + "yt-dlpSetup.ps1_LOG.txt"
    $parameterString1 = "-pPythonInstallationDirectory ""$pPythonInstallationDirectory"" -pLogFileLocation ""$setupScriptLogFilePath"" -pSetupType ""/check-installation-status"""
    $parameterString2 = "-executionPolicy bypass -file ""$ytdlpSetupScriptLocation"" $parameterString1"
    $process = Start-Process "powershell.exe" -ArgumentList "$parameterString2" -PassThru -Wait -WindowStyle $optionalQuietWindowParameter

    $scriptStdOut = Get-Content $setupScriptLogFilePath -Raw -ErrorAction Continue
    $exitCode = [string]$process.ExitCode

    Write-Log "----------`n`n$scriptStdOut`n`n----------"
    Write-Log "`n`n[checkYTDLPInstallationStatus()] [INFO] Setup script exit code = $exitCode`n`n"
    # Fatal error code range.
    If (($exitCode -ge 71001) -and ($exitCode -le 71100)) {
        Write-Log "`n`n[checkYTDLPInstallationStatus()] [ERROR] A fatal error occurred [Exit Code = $exitCode].`n`n"
        Return $false
    }
    # Normal error code range.
    ElseIf (($exitCode -ge 71101) -and ($exitCode -le 71200)) {
        Write-Log "`n`n[checkYTDLPInstallationStatus()] [INFO] Normal exit code received [Exit Code = $exitCode].`n`n"
        # True when yt-dlp install status is true.
        If ($exitCode -eq 71103) {
            Write-Log "`n`n[checkYTDLPInstallationStatus()] [INFO] yt-dlp is currently installed.`n`n"
            Return $true
        }
        ElseIf ($exitCode -eq 71104) {
            Write-Log "`n`n[checkYTDLPInstallationStatus()] [INFO] yt-dlp is currently not installed.`n`n"
            Return $false
        }    
    }
    Else {
        Write-Log "`n`n[checkYTDLPInstallationStatus()] [WARNING] Unknown exit code received [Exit Code = $exitCode]!`n`n"
        Return $false
    }
}

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

function installFFmpeg($pVideoDownloaderInstallationDirectory, $pBooleanQuiet = $false) {
    Write-Log "`n`n[installFFmpeg()] [INFO] pVideoDownloaderInstallationDirectory = $pVideoDownloaderInstallationDirectory`n`n"
    Write-Log "`n`n[installFFmpeg()] [INFO] pBooleanQuiet = $pBooleanQuiet`n`n"
    Show-InstallationProgress -StatusMessage "Running FFmpeg setup script (install). Please wait..." -TopMost $false # CAUSES ERROR WITH RETURN $false and $true!!!
    
    Write-Log "`n`n**********[FFmpeg Setup Script START]**********`n`n"
    If (-not (Test-Path -Path $ffmpegSetupScriptLocation)) {
        Write-Log "`n`n[installFFmpeg()] [ERROR] Could not find FFmpeg setup script at`n[$ffmpegSetupScriptLocation]!`n`n"
        Return $false
    }
    # If FFmpeg is installed.
    ElseIf (getBooleanReturn(checkFFmpegInstallationStatus -pVideoDownloaderInstallationDirectory $pVideoDownloaderInstallationDirectory -pBooleanQuiet $pBooleanQuiet)) {
        Write-Log "`n`n[installFFmpeg()] [INFO] Stopped because FFmpeg is already installed.`n`n"
        Return $true
    }
    Else {
        If (-not (getBooleanReturn(checkInternetConnectionStatus))) {
            Write-Log "`n`n[installFFmpeg()] [WARNING] No active Internet connection found for downloading FFmpeg.`n`n"
            $balloonText = "No Internet connection found. Operation could not complete."
            $balloonTitle = "FFmpeg Installation Status"
            Show-BalloonTip -BalloonTipText $balloonText -BalloonTipTitle $balloonTitle -BalloonTipTime 5000 -BalloonTipIcon "Warning"
            Return $false
        }
        If ($pBooleanQuiet) {
            $optionalQuietWindowParameter = "Hidden"
        }
        Else {
            $optionalQuietWindowParameter = "Normal"
        }
        # Install FFmpeg START.
        Write-Log "`n`n[installFFmpeg()] [INFO] Starting FFmpeg installation.`n`n"

        $setupScriptLogFilePath = "$envTemp" + "FFmpegSetupScript.ps1_LOG.txt"
        $parameterString1 = "-pVideoDownloaderInstallationDirectory ""$pVideoDownloaderInstallationDirectory"" -pLogFileLocation ""$setupScriptLogFilePath"" -pSetupType ""/install"""
        $parameterString2 = "-executionPolicy bypass -file ""$ffmpegSetupScriptLocation"" $parameterString1"
        $process = Start-Process "powershell.exe" -ArgumentList "$parameterString2" -PassThru -Wait -WindowStyle $optionalQuietWindowParameter

        $scriptStdOut = Get-Content $setupScriptLogFilePath -Raw -ErrorAction Continue
        $exitCode = [string]$process.ExitCode

        Write-Log "----------`n`n$scriptStdOut`n`n----------"
        Write-Log "`n`n[installFFmpeg()] [INFO] Setup script exit code = $exitCode`n`n"
        # Fatal error code range.
        If (($exitCode -ge 71501) -and ($exitCode -le 71600)) {
            Write-Log "`n`n[installFFmpeg()] [ERROR] A fatal error occurred [Exit Code = $exitCode].`n`n"
            Return $false
        }
        # Normal error code range.
        ElseIf (($exitCode -ge 71601) -and ($exitCode -le 71700)) {
            Write-Log "`n`n[installFFmpeg()] [INFO] Normal exit code received [Exit Code = $exitCode].`n`n"
            # True when FFmpeg was successfully installed.
            If ($exitCode -eq 71603) {
                If (getBooleanReturn(checkFFmpegInstallationStatus -pVideoDownloaderInstallationDirectory $pVideoDownloaderInstallationDirectory -pBooleanQuiet $pBooleanQuiet)) {
                    Write-Log "`n`n[installFFmpeg()] [INFO] FFmpeg has been successfully installed.`n`n"
                    Return $true
                }
                Else {
                    Write-Log "`n`n[installFFmpeg()] [WARNING] FFmpeg has not been successfully installed.`n`n"
                    Return $false
                }
            }
            Else {
                Write-Log "`n`n[installFFmpeg()] [WARNING] FFmpeg has not been successfully installed.`n`n"
                Return $false
            }
        }
        Else {
            Write-Log "`n`n[installFFmpeg()] [WARNING] Unknown exit code received [Exit Code = $exitCode]!`n`n"
            Return $false
        }
        # Install FFmpeg END.
    }
    Write-Log "`n`n**********[FFmpeg Setup Script END]**********`n`n"
}

function uninstallFFmpeg($pVideoDownloaderInstallationDirectory, $pBooleanQuiet = $false) {
    Write-Log "`n`n[uninstallFFmpeg] [INFO] pVideoDownloaderInstallationDirectory = $pVideoDownloaderInstallationDirectory`n`n"
    Write-Log "`n`n[uninstallFFmpeg()] [INFO] pBooleanQuiet = $pBooleanQuiet`n`n" 
    Show-InstallationProgress -StatusMessage "Running FFmpeg setup script (uninstall). Please wait..." -TopMost $false

    Write-Log "`n`n**********[FFmpeg Setup Script START]**********`n`n"
    If (-not (Test-Path -Path $ffmpegSetupScriptLocation)) {
        Write-Log "`n`n[uninstallFFmpeg()] [ERROR] Could not find FFmpeg setup script at`n[$ffmpegSetupScriptLocation]!`n`n"
        Return $false
    }
    # If FFmpeg is installed.
    ElseIf (getBooleanReturn(checkFFmpegInstallationStatus -pVideoDownloaderInstallationDirectory $pVideoDownloaderInstallationDirectory -pBooleanQuiet $pBooleanQuiet)) {
        If ($pBooleanQuiet) {
            $optionalQuietWindowParameter = "Hidden"
        }
        Else {
            $optionalQuietWindowParameter = "Normal"
        }
        # Uninstall FFmpeg START.
        Write-Log "`n`n[uninstallFFmpeg()] [INFO] Starting FFmpeg uninstallation.`n`n"
        $setupScriptLogFilePath = "$envTemp" + "FFmpegSetup.ps1_LOG.txt"
        $parameterString1 = "-pVideoDownloaderInstallationDirectory ""$pVideoDownloaderInstallationDirectory"" -pLogFileLocation ""$setupScriptLogFilePath"" -pSetupType ""/uninstall"""
        $parameterString2 = "-executionPolicy bypass -file ""$ffmpegSetupScriptLocation"" $parameterString1"
        $process = Start-Process "powershell.exe" -ArgumentList "$parameterString2" -PassThru -Wait -WindowStyle $optionalQuietWindowParameter

        $scriptStdOut = Get-Content $setupScriptLogFilePath -Raw -ErrorAction Continue
        $exitCode = [string]$process.ExitCode

        Write-Log "----------`n`n$scriptStdOut`n`n----------"
        Write-Log "`n`n[uninstallFFmpeg()] [INFO] Setup script exit code = $exitCode`n`n"
        # Fatal error code range.
        If (($exitCode -ge 71501) -and ($exitCode -le 71600)) {
            Write-Log "`n`n[uninstallFFmpeg()] [ERROR] A fatal error occurred [Exit Code = $exitCode].`n`n"
            Return $false
        }
        # Normal error code range.
        ElseIf (($exitCode -ge 71601) -and ($exitCode -le 71700)) {
            Write-Log "`n`n[uninstallFFmpeg()] [INFO] Normal exit code received [Exit Code = $exitCode].`n`n"
            # True when FFmpeg was successfully uninstalled.
            If ($exitCode -eq 71604) {
                If (getBooleanReturn(checkFFmpegInstallationStatus -pVideoDownloaderInstallationDirectory $pVideoDownloaderInstallationDirectory -pBooleanQuiet $pBooleanQuiet)) {
                    Write-Log "`n`n[uninstallFFmpeg()] [WARNING] FFmpeg has not been successfully uninstalled.`n`n"
                    Return $false   
                }
                Else {
                    Write-Log "`n`n[uninstallFFmpeg()] [INFO] FFmpeg has been successfully uninstalled.`n`n"
                    Return $true 
                }
            }
            Else {
                Write-Log "`n`n[uninstallFFmpeg()] [WARNING] FFmpeg has not been successfully uninstalled.`n`n"
                Return $false
            }
        }
        Else {
            Write-Log "`n`n[uninstallFFmpeg()] [WARNING] Unknown exit code received [Exit Code = $exitCode]!`n`n"
            Return $false
        }
        # Uninstall FFmpeg END.
    }
    Else {
        Write-Log "`n`n[uninstallFFmpeg()] [INFO] Stopped because FFmpeg is not installed.`n`n"
        Return $false
    }
    Write-Log "`n`n**********[FFmpeg Setup Script END]**********`n`n"
}

function repairFFmpeg($pVideoDownloaderInstallationDirectory, $pBooleanQuiet = $false) {
    Write-Log "`n`n[repairFFmpeg()] [INFO] pVideoDownloaderInstallationDirectory = $pVideoDownloaderInstallationDirectory`n`n"
    Write-Log "`n`n[repairFFmpeg()] [INFO] pBooleanQuiet = $pBooleanQuiet`n`n" 
    Show-InstallationProgress -StatusMessage "Running FFmpeg setup script (repair). Please wait..." -TopMost $false

    Write-Log "`n`n**********[FFmpeg Setup Script START]**********`n`n"
    If (-not (Test-Path -Path $ffmpegSetupScriptLocation)) {
        Write-Log "`n`n[repairFFmpeg()] [ERROR] Could not find FFmpeg setup script at`n[$ffmpegSetupScriptLocation]!`n`n"
        Return $false
    }
    # If FFmpeg is installed.
    ElseIf (getBooleanReturn(checkFFmpegInstallationStatus -pVideoDownloaderInstallationDirectory $pVideoDownloaderInstallationDirectory -pBooleanQuiet $pBooleanQuiet)) {
        If (-not (getBooleanReturn(checkInternetConnectionStatus))) {
            Write-Log "`n`n[repairFFmpeg()] [WARNING] No active Internet connection found for downloading FFmpeg.`n`n"
            $balloonText = "No Internet connection found. Operation could not complete."
            $balloonTitle = "FFmpeg Installation Status"
            Show-BalloonTip -BalloonTipText $balloonText -BalloonTipTitle $balloonTitle -BalloonTipTime 5000 -BalloonTipIcon "Warning"
            Return $false
        }
        If ($pBooleanQuiet) {
            $optionalQuietWindowParameter = "Hidden"
        }
        Else {
            $optionalQuietWindowParameter = "Normal"
        }
        # Repair FFmpeg START.
        Write-Log "`n`n[repairFFmpeg()] [INFO] Starting FFmpeg repair.`n`n"
        $setupScriptLogFilePath = "$envTemp" + "FFmpegSetup.ps1_LOG.txt"
        $parameterString1 = "-pVideoDownloaderInstallationDirectory ""$pVideoDownloaderInstallationDirectory"" -pLogFileLocation ""$setupScriptLogFilePath"" -pSetupType ""/install-force"""
        $parameterString2 = "-executionPolicy bypass -file ""$ffmpegSetupScriptLocation"" $parameterString1"
        $process = Start-Process "powershell.exe" -ArgumentList "$parameterString2" -PassThru -Wait -WindowStyle $optionalQuietWindowParameter

        $scriptStdOut = Get-Content $setupScriptLogFilePath -Raw -ErrorAction Continue
        $exitCode = [string]$process.ExitCode

        Write-Log "----------`n`n$scriptStdOut`n`n----------"
        Write-Log "`n`n[repairFFmpeg()] [INFO] Setup script exit code = $exitCode`n`n"
        # Fatal error code range.
        If (($exitCode -ge 71501) -and ($exitCode -le 71600)) {
            Write-Log "`n`n[repairFFmpeg()] [ERROR] A fatal error occurred [Exit Code = $exitCode].`n`n"
            Return $false
        }
        # Normal error code range.
        ElseIf (($exitCode -ge 71601) -and ($exitCode -le 71700)) {
            Write-Log "`n`n[repairFFmpeg()] [INFO] Normal exit code received [Exit Code = $exitCode].`n`n"
            # True when FFmpeg was successfully uninstalled and installed afterwards.
            If ($exitCode -eq 71603) {
                If (getBooleanReturn(checkFFmpegInstallationStatus -pVideoDownloaderInstallationDirectory $pVideoDownloaderInstallationDirectory -pBooleanQuiet $pBooleanQuiet)) {
                    Write-Log "`n`n[repairFFmpeg()] [INFO] FFmpeg has been successfully re-installed.`n`n"
                    Return $true
                }
                Else {
                    Write-Log "`n`n[repairFFmpeg()] [WARNING] FFmpeg has not been successfully re-installed.`n`n"
                    Return $false 
                }
            }
            Else {
                Write-Log "`n`n[repairFFmpeg()] [WARNING] FFmpeg has not been successfully re-installed.`n`n" 
                Return $false
            }
        }
        Else {
            Write-Log "`n`n[repairFFmpeg()] [WARNING] Unknown exit code received [Exit Code = $exitCode]!`n`n"
            Return $false
        }
        # Repair FFmpeg END.
    }
    Else {
        Write-Log "`n`n[repairFFmpeg()] [INFO] FFmpeg is not installed. Trying to find VideoDownloader instance for FFmpeg installation.`n`n"

        $installedVideoDownloaderObject = Get-InstalledApplication -Name "VideoDownloader" -Exact
        If ($installedVideoDownloaderObject) {
            $tmpLocation = $installedVideoDownloaderObject.InstallLocation
            $installedVideoDownloaderLocation = $tmpLocation.TrimEnd("\")
            Write-Log "`n`n[repairFFmpeg()] [INFO] Other potentially useful information:`n[$installedVideoDownloaderObject].`n`n"
            Write-Log "`n`n[repairFFmpeg()] [INFO] Found VideoDownloader installation at:`n[$installedVideoDownloaderLocation].`n`n"
            If (getBooleanReturn(validatePath($installedVideoDownloaderLocation))) {
                # Language support needed.
                $balloonText = "No installed FFmpeg instance found. Running installer now."
                $balloonTitle = "FFmpeg Repair Status"
                Show-BalloonTip -BalloonTipText $balloonText -BalloonTipTitle $balloonTitle -BalloonTipTime 5000
                # If the FFmpeg installation succeeds.
                If (getBooleanReturn(getBooleanReturn(installFFmpeg -pVideoDownloaderInstallationDirectory $installedVideoDownloaderLocation -pBooleanQuiet $pBooleanQuiet))) {
                    Write-Log "`n`n[repairFFmpeg()] [INFO] Installed FFmpeg successfully.`n`n"
                    Return $true
                }
                Else {
                    Write-Log "`n`n[repairFFmpeg()] [INFO] Could not install FFmpeg successfully.`n`n"
                    Return $false
                }
            }
            Else {
                Write-Log "`n`n[repairFFmpeg()] [INFO] Stopped because VideoDownloader is not installed.`n`n"
                # Language support needed.
                $balloonText = "No installed VideoDownloader instance for FFmpeg found. Please run the installer afterwards."
                $balloonTitle = "FFmpeg Repair Status"
                Show-BalloonTip -BalloonTipText $balloonText -BalloonTipTitle $balloonTitle -BalloonTipIcon "Warning"
                Return $false
            }
        }
        Else {
            Write-Log "`n`n[repairFFmpeg()] [INFO] Stopped because VideoDownloader is not installed.`n`n"
            # Language support needed.
            $balloonText = "No installed VideoDownloader instance for FFmpeg found. Please run the installer afterwards."
            $balloonTitle = "FFmpeg Repair Status"
            Show-BalloonTip -BalloonTipText $balloonText -BalloonTipTitle $balloonTitle -BalloonTipTime 5000 -BalloonTipIcon "Warning"
            Return $false
        }
    }
    Write-Log "`n`n**********[FFmpeg Setup Script END]**********`n`n"
}

function checkFFmpegInstallationStatus($pVideoDownloaderInstallationDirectory, $pBooleanQuiet = $false) {
    Write-Log "`n`n[checkFFmpegInstallationStatus()] [INFO] Checking FFmpeg installation status.`n`n"
    If ($pBooleanQuiet) {
        $optionalQuietWindowParameter = "Hidden"
    }
    Else {
        $optionalQuietWindowParameter = "Normal"
    }
    $setupScriptLogFilePath = "$envTemp" + "FFmpegSetup.ps1_LOG.txt"
    $parameterString1 = "-pVideoDownloaderInstallationDirectory ""$pVideoDownloaderInstallationDirectory"" -pLogFileLocation ""$setupScriptLogFilePath"" -pSetupType ""/check-installation-status"""
    $parameterString2 = "-executionPolicy bypass -file ""$ffmpegSetupScriptLocation"" $parameterString1"
    $process = Start-Process "powershell.exe" -ArgumentList "$parameterString2" -PassThru -Wait -WindowStyle $optionalQuietWindowParameter

    $scriptStdOut = Get-Content $setupScriptLogFilePath -Raw -ErrorAction Continue
    $exitCode = [string]$process.ExitCode

    Write-Log "----------`n`n$scriptStdOut`n`n----------"
    Write-Log "`n`n[checkFFmpegInstallationStatus()] [INFO] Setup script exit code = $exitCode`n`n"
    # Fatal error code range.
    If (($exitCode -ge 71501) -and ($exitCode -le 71600)) {
        Write-Log "`n`n[checkFFmpegInstallationStatus()] [ERROR] A fatal error occurred [Exit Code = $exitCode].`n`n"
        Return $false
    }
    # Normal error code range.
    ElseIf (($exitCode -ge 71601) -and ($exitCode -le 71700)) {
        Write-Log "`n`n[checkFFmpegInstallationStatus()] [INFO] Normal exit code received [Exit Code = $exitCode].`n`n"
        # True when FFmpeg install status is true.
        If ($exitCode -eq 71601) {
            Write-Log "`n`n[checkFFmpegInstallationStatus()] [INFO] FFmpeg is currently installed.`n`n"
            Return $true
        }
        ElseIf ($exitCode -eq 71602) {
            Write-Log "`n`n[checkFFmpegInstallationStatus()] [INFO] FFmpeg is currently not installed.`n`n"
            Return $false
        }    
    }
    Else {
        Write-Log "`n`n[checkFFmpegInstallationStatus()] [WARNING] Unknown exit code received [Exit Code = $exitCode]!`n`n"
    }
}

##*===============================================
##* SETUP FUNCTIONS SECTION END
##*===============================================

Add-Type -AssemblyName System.Windows.Forms

function showFolderBrowserDialog() {
    $folderBrowser = New-Object System.Windows.Forms.FolderBrowserDialog
    $folderBrowser.Description = 'Select a folder.'

    $result = $folderBrowser.ShowDialog()
    If ($result -eq 'OK') {
        Return $folderBrowser.SelectedPath
    }
    Else {
        Return 'exitScript'
    }
}

function chooseInstallDirectory() {
    $tmp = showFolderBrowserDialog
    If ($tmp -eq 'exitScript') {
        $balloonText = "$deploymentTypeName $configBalloonTextAbort"
        Show-BalloonTip -BalloonTipText $balloonText
        Exit-Script
    }
    ElseIf ($tmp -ne '') {
        Return $tmp
    }
    Else {
        Return chooseInstallDirectory
    }
}

function getMSIFileVersion([IO.FileInfo]$pMSIFileLocation) {
    Try {
        $windowsInstaller = New-Object -com WindowsInstaller.Installer

        $database = $windowsInstaller.GetType().InvokeMember("OpenDatabase", "InvokeMethod", $Null, $windowsInstaller, @($pMSIFileLocation.FullName, 0))

        $q = "SELECT `Value` FROM `Property` WHERE `Property` = 'ProductVersion'"
        $View = $database.GetType().InvokeMember("OpenView", "InvokeMethod", $Null, $database, ($q))

        $View.GetType().InvokeMember("Execute", "InvokeMethod", $Null, $View, $Null)

        $record = $View.GetType().InvokeMember("Fetch", "InvokeMethod", $Null, $View, $Null)

        $productVersion = $record.GetType().InvokeMember("StringData", "GetProperty", $Null, $record, 1)

        Return $productVersion
    }
    Catch {
        Throw "Failed to get MSI file version the error was: { 0 }." -f $_
    }   
}

function updatePATH() {
    Write-Log "[updatePATH()] [INFO] Updating PATH environment variables..."
    Try {
        $currentPathSystem = [System.Environment]::GetEnvironmentVariable('PATH', [System.EnvironmentVariableTarget]::Machine)
        [System.Environment]::SetEnvironmentVariable('PATH', $currentPathSystem, [System.EnvironmentVariableTarget]::Machine)
    }
    Catch {
        Write-Log "[updatePATH()] [WARNING] Unable to update system environment variable 'PATH'."
    }
    $currentPathUser = [System.Environment]::GetEnvironmentVariable('PATH', [System.EnvironmentVariableTarget]::User)
    [System.Environment]::SetEnvironmentVariable('PATH', $currentPathUser, [System.EnvironmentVariableTarget]::User)
    $env:Path = [System.Environment]::GetEnvironmentVariable('PATH', [System.EnvironmentVariableTarget]::User)
}

function checkInternetConnectionStatus() {
    Try {
        $pingResult = Test-Connection -ComputerName "www.google.com" -Count 1 -ErrorAction Stop
        Write-Log "`n`n[checkInternetConnectionStatus()] [INFO] Computer is connected to the Internet.`n`n"
        Return $true
    }
    Catch {
        Write-Log "`n`n[checkInternetConnectionStatus()] [WARNING] Computer is not connected to the Internet.`n`n"
        Return $false
    }
}

function getBooleanReturn($pData) {
    # This function corrects other function's return values. When a function contains the 'Show-InstallationProgess' command,
    # some returned values have emtpy space infront of them.
    # For example 'Return $true' will actually return ' True' instead of 'True' as a string.
    If ($pData -eq $true) {
        Return $true
    }
    ElseIf ($pData -eq $false) {
        Return $false
    }
    If ($pData -like "*True'") {
        Return $true
    }
    ElseIf ($pData -like "*False*") {
        Return $false
    }
    Else {
        Write-Log "`n`n[getBooleanReturn()] [ERROR] Could not figure out boolean value!`n`n"
        $balloonText = "Could not figure out boolean value from [$pData]!"
        $balloonTitle = "getBooleanReturn()"
        Show-BalloonTip -BalloonTipText $balloonText -BalloonTipTitle $balloonTitle -BalloonTipIcon "Error"
        Exit-Script
    }
}

function validatePath([string]$pPath) {
    Try {
        $tmpPath = [System.IO.Path]::GetFullPath($pPath)
        # Write-Host "[PATH DEBUG] Normal: $pPath"
        # Write-Host "[PATH DEBUG] _Full_: $tmpPath"
        If ($tmpPath -ne $pPath) {
            Write-Log "`n`n[validatePath()] [WARNING] Path: [$pPath] is invalid.`n`n"
            Return $false
        }
        Else {
            Write-Log "`n`n[validatePath()] [INFO] Path: [$pPath] is valid.`n`n"
            Return $true
        }
    }
    Catch {
        Write-Log "`n`n[validatePath()] [WARNING] Path: [$pPath] is invalid.`n`n"
        Return $false
    }
}

function uninstallAllPythonCompletly() {
    $appList = Get-InstalledApplication -Name 'Python 3.12.0*Add to Path*' -WildCard    
    ForEach ($app in $appList) {
        If ($app.UninstallString) {
            $guid = $($app.UninstallString).Replace('MsiExec.exe /I', '').Replace('MsiExec.exe /X', '')
            Write-Log "`n`n[uninstallPython()] [INFO] Found $($app.DisplayName) $($app.DisplayVersion) and a valid uninstall string, now attempting to uninstall.`n`n"       
            Execute-ProcessAsUser -Path "$exeMsiexec" -Parameters "/x $guid REBOOT=ReallySuppress /qn /L*v C:\Windows\Logs\Software\Python_Add_to_Path-Uninstall.log" -Wait
            Start-Sleep -Seconds 5
        }
    }

    ## Uninstall Any Existing Versions of Python 3.12.0 pip Bootstrap
    Remove-MSIApplications -Name 'Python 3.12.0' -FilterApplication (, ('DisplayName', 'pip Bootstrap', 'Contains'))

    $appList = Get-InstalledApplication -Name 'Python 3.12.0*pip Bootstrap*' -WildCard    
    ForEach ($app in $appList) {
        If ($app.UninstallString) {
            $guid = $($app.UninstallString).Replace('MsiExec.exe /I', '').Replace('MsiExec.exe /X', '')
            Write-Log "`n`n[uninstallPython()] [INFO] Found $($app.DisplayName) $($app.DisplayVersion) and a valid uninstall string, now attempting to uninstall.`n`n"       
            Execute-ProcessAsUser -Path "$exeMsiexec" -Parameters "/x $guid REBOOT=ReallySuppress /qn /L*v C:\Windows\Logs\Software\Python_pip_Bootstrap-Uninstall.log" -Wait
            Start-Sleep -Seconds 5
        }
    }

    ## Uninstall Any Existing Versions of Python 3.12.0 Tcl/Tk Support (32-bit debug)
    Remove-MSIApplications -Name 'Python 3.12.0' -FilterApplication (, ('DisplayName', 'Tcl/Tk Support (32-bit debug)', 'Contains'))

    $appList = Get-InstalledApplication -Name 'Python 3.12.0*Tcl/Tk Support (32-bit debug)' -WildCard    
    ForEach ($app in $appList) {
        If ($app.UninstallString) {
            $guid = $($app.UninstallString).Replace('MsiExec.exe /I', '').Replace('MsiExec.exe /X', '')
            Write-Log "`n`n[uninstallPython()] [INFO] Found $($app.DisplayName) $($app.DisplayVersion) and a valid uninstall string, now attempting to uninstall.`n`n"       
            Execute-ProcessAsUser -Path "$exeMsiexec" -Parameters "/x $guid REBOOT=ReallySuppress /qn /L*v C:\Windows\Logs\Software\Python_Tcl_Tk_Support_32bit_debug-Uninstall.log" -Wait
            Start-Sleep -Seconds 5
        }
    }

    ## Uninstall Any Existing Versions of Python 3.12.0 Tcl/Tk Support (64-bit debug)
    Remove-MSIApplications -Name 'Python 3.12.0' -FilterApplication (, ('DisplayName', 'Tcl/Tk Support (64-bit debug)', 'Contains'))

    $appList = Get-InstalledApplication -Name 'Python 3.12.0*Tcl/Tk Support (64-bit debug)' -WildCard    
    ForEach ($app in $appList) {
        If ($app.UninstallString) {
            $guid = $($app.UninstallString).Replace('MsiExec.exe /I', '').Replace('MsiExec.exe /X', '')
            Write-Log "`n`n[uninstallPython()] [INFO] Found $($app.DisplayName) $($app.DisplayVersion) and a valid uninstall string, now attempting to uninstall.`n`n"       
            Execute-ProcessAsUser -Path "$exeMsiexec" -Parameters "/x $guid REBOOT=ReallySuppress /qn /L*v C:\Windows\Logs\Software\Python_Tcl_Tk_Support_64bit_debug-Uninstall.log" -Wait
            Start-Sleep -Seconds 5
        }
    }

    ## Uninstall Any Existing Versions of Python 3.12.0 Tcl/Tk Support (32-bit symbols)
    Remove-MSIApplications -Name 'Python 3.12.0' -FilterApplication (, ('DisplayName', 'Tcl/Tk Support (32-bit symbols)', 'Contains'))

    $appList = Get-InstalledApplication -Name 'Python 3.12.0*Tcl/Tk Support (32-bit symbols)' -WildCard    
    ForEach ($app in $appList) {
        If ($app.UninstallString) {
            $guid = $($app.UninstallString).Replace('MsiExec.exe /I', '').Replace('MsiExec.exe /X', '')
            Write-Log "`n`n[uninstallPython()] [INFO] Found $($app.DisplayName) $($app.DisplayVersion) and a valid uninstall string, now attempting to uninstall.`n`n"       
            Execute-ProcessAsUser -Path "$exeMsiexec" -Parameters "/x $guid REBOOT=ReallySuppress /qn /L*v C:\Windows\Logs\Software\Python_Tcl_Tk_Support_32bit_symbols-Uninstall.log" -Wait
            Start-Sleep -Seconds 5
        }
    }

    ## Uninstall Any Existing Versions of Python 3.12.0 Tcl/Tk Support (64-bit symbols)
    Remove-MSIApplications -Name 'Python 3.12.0' -FilterApplication (, ('DisplayName', 'Tcl/Tk Support (64-bit symbols)', 'Contains'))

    $appList = Get-InstalledApplication -Name 'Python 3.12.0*Tcl/Tk Support (64-bit symbols)' -WildCard    
    ForEach ($app in $appList) {
        If ($app.UninstallString) {
            $guid = $($app.UninstallString).Replace('MsiExec.exe /I', '').Replace('MsiExec.exe /X', '')
            Write-Log "`n`n[uninstallPython()] [INFO] Found $($app.DisplayName) $($app.DisplayVersion) and a valid uninstall string, now attempting to uninstall.`n`n"       
            Execute-ProcessAsUser -Path "$exeMsiexec" -Parameters "/x $guid REBOOT=ReallySuppress /qn /L*v C:\Windows\Logs\Software\Python_Tcl_Tk_Support_64bit_symbols-Uninstall.log" -Wait
            Start-Sleep -Seconds 5
        }
    }

    ## Uninstall Any Existing Versions of Python 3.12.0 Tcl/Tk Support (32-bit)
    Remove-MSIApplications -Name 'Python 3.12.0' -FilterApplication (, ('DisplayName', 'Tcl/Tk Support (32-bit)', 'Contains'))

    $appList = Get-InstalledApplication -Name 'Python 3.12.0*Tcl/Tk Support (32-bit)' -WildCard    
    ForEach ($app in $appList) {
        If ($app.UninstallString) {
            $guid = $($app.UninstallString).Replace('MsiExec.exe /I', '').Replace('MsiExec.exe /X', '')
            Write-Log "`n`n[uninstallPython()] [INFO] Found $($app.DisplayName) $($app.DisplayVersion) and a valid uninstall string, now attempting to uninstall.`n`n"       
            Execute-ProcessAsUser -Path "$exeMsiexec" -Parameters "/x $guid REBOOT=ReallySuppress /qn /L*v C:\Windows\Logs\Software\Python_Tcl_Tk_Support_32bit-Uninstall.log" -Wait
            Start-Sleep -Seconds 5
        }
    }

    ## Uninstall Any Existing Versions of Python 3.12.0 Tcl/Tk Support (64-bit)
    Remove-MSIApplications -Name 'Python 3.12.0' -FilterApplication (, ('DisplayName', 'Tcl/Tk Support (64-bit)', 'Contains'))

    $appList = Get-InstalledApplication -Name 'Python 3.12.0*Tcl/Tk Support (64-bit)' -WildCard    
    ForEach ($app in $appList) {
        If ($app.UninstallString) {
            $guid = $($app.UninstallString).Replace('MsiExec.exe /I', '').Replace('MsiExec.exe /X', '')
            Write-Log "`n`n[uninstallPython()] [INFO] Found $($app.DisplayName) $($app.DisplayVersion) and a valid uninstall string, now attempting to uninstall.`n`n"       
            Execute-ProcessAsUser -Path "$exeMsiexec" -Parameters "/x $guid REBOOT=ReallySuppress /qn /L*v C:\Windows\Logs\Software\Python_Tcl_Tk_Support_64bit-Uninstall.log" -Wait
            Start-Sleep -Seconds 5
        }
    }

    ## Uninstall Any Existing Versions of Python 3.12.0 Utility Scripts
    Remove-MSIApplications -Name 'Python 3.12.0' -FilterApplication (, ('DisplayName', 'Utility Scripts', 'Contains'))

    $appList = Get-InstalledApplication -Name 'Python 3.12.0*Utility Scripts*' -WildCard    
    ForEach ($app in $appList) {
        If ($app.UninstallString) {
            $guid = $($app.UninstallString).Replace('MsiExec.exe /I', '').Replace('MsiExec.exe /X', '')
            Write-Log "`n`n[uninstallPython()] [INFO] Found $($app.DisplayName) $($app.DisplayVersion) and a valid uninstall string, now attempting to uninstall.`n`n"       
            Execute-ProcessAsUser -Path "$exeMsiexec" -Parameters "/x $guid REBOOT=ReallySuppress /qn /L*v C:\Windows\Logs\Software\Python_Utility_Scripts-Uninstall.log" -Wait
            Start-Sleep -Seconds 5
        }
    }

    ## Uninstall Any Existing Versions of Python 3.12.0 Documentation
    Remove-MSIApplications -Name 'Python 3.12.0' -FilterApplication (, ('DisplayName', 'Documentation', 'Contains'))

    $appList = Get-InstalledApplication -Name 'Python 3.12.0*Documentation*' -WildCard    
    ForEach ($app in $appList) {
        If ($app.UninstallString) {
            $guid = $($app.UninstallString).Replace('MsiExec.exe /I', '').Replace('MsiExec.exe /X', '')
            Write-Log "`n`n[uninstallPython()] [INFO] Found $($app.DisplayName) $($app.DisplayVersion) and a valid uninstall string, now attempting to uninstall.`n`n"       
            Execute-ProcessAsUser -Path "$exeMsiexec" -Parameters "/x $guid REBOOT=ReallySuppress /qn /L*v C:\Windows\Logs\Software\Python_Documentation-Uninstall.log" -Wait
            Start-Sleep -Seconds 5
        }
    }

    ## Uninstall Any Existing Versions of Python 3.12.0 Test Suite (32-bit debug)
    Remove-MSIApplications -Name 'Python 3.12.0' -FilterApplication (, ('DisplayName', 'Test Suite (32-bit debug)', 'Contains'))

    $appList = Get-InstalledApplication -Name 'Python 3.12.0*Test Suite (32-bit debug)' -WildCard    
    ForEach ($app in $appList) {
        If ($app.UninstallString) {
            $guid = $($app.UninstallString).Replace('MsiExec.exe /I', '').Replace('MsiExec.exe /X', '')
            Write-Log "`n`n[uninstallPython()] [INFO] Found $($app.DisplayName) $($app.DisplayVersion) and a valid uninstall string, now attempting to uninstall.`n`n"       
            Execute-ProcessAsUser -Path "$exeMsiexec" -Parameters "/x $guid REBOOT=ReallySuppress /qn /L*v C:\Windows\Logs\Software\Python_Test_Suite_32bit_debug-Uninstall.log" -Wait
            Start-Sleep -Seconds 5
        }
    }

    ## Uninstall Any Existing Versions of Python 3.12.0 Test Suite (64-bit debug)
    Remove-MSIApplications -Name 'Python 3.12.0' -FilterApplication (, ('DisplayName', 'Test Suite (64-bit debug)', 'Contains'))

    $appList = Get-InstalledApplication -Name 'Python 3.12.0*Test Suite (64-bit debug)' -WildCard    
    ForEach ($app in $appList) {
        If ($app.UninstallString) {
            $guid = $($app.UninstallString).Replace('MsiExec.exe /I', '').Replace('MsiExec.exe /X', '')
            Write-Log "`n`n[uninstallPython()] [INFO] Found $($app.DisplayName) $($app.DisplayVersion) and a valid uninstall string, now attempting to uninstall.`n`n"       
            Execute-ProcessAsUser -Path "$exeMsiexec" -Parameters "/x $guid REBOOT=ReallySuppress /qn /L*v C:\Windows\Logs\Software\Python_Test_Suite_64bit_debug-Uninstall.log" -Wait
            Start-Sleep -Seconds 5
        }
    }

    ## Uninstall Any Existing Versions of Python 3.12.0 Test Suite (32-bit symbols)
    Remove-MSIApplications -Name 'Python 3.12.0' -FilterApplication (, ('DisplayName', 'Test Suite (32-bit symbols)', 'Contains'))

    $appList = Get-InstalledApplication -Name 'Python 3.12.0*Test Suite (32-bit symbols)' -WildCard    
    ForEach ($app in $appList) {
        If ($app.UninstallString) {
            $guid = $($app.UninstallString).Replace('MsiExec.exe /I', '').Replace('MsiExec.exe /X', '')
            Write-Log "`n`n[uninstallPython()] [INFO] Found $($app.DisplayName) $($app.DisplayVersion) and a valid uninstall string, now attempting to uninstall.`n`n"       
            Execute-ProcessAsUser -Path "$exeMsiexec" -Parameters "/x $guid REBOOT=ReallySuppress /qn /L*v C:\Windows\Logs\Software\Python_Test_Suite_32bit_symbols-Uninstall.log" -Wait
            Start-Sleep -Seconds 5
        }
    }

    ## Uninstall Any Existing Versions of Python 3.12.0 Test Suite (64-bit symbols)
    Remove-MSIApplications -Name 'Python 3.12.0' -FilterApplication (, ('DisplayName', 'Test Suite (64-bit symbols)', 'Contains'))

    $appList = Get-InstalledApplication -Name 'Python 3.12.0*Test Suite (64-bit symbols)' -WildCard    
    ForEach ($app in $appList) {
        If ($app.UninstallString) {
            $guid = $($app.UninstallString).Replace('MsiExec.exe /I', '').Replace('MsiExec.exe /X', '')
            Write-Log "`n`n[uninstallPython()] [INFO] Found $($app.DisplayName) $($app.DisplayVersion) and a valid uninstall string, now attempting to uninstall.`n`n"       
            Execute-ProcessAsUser -Path "$exeMsiexec" -Parameters "/x $guid REBOOT=ReallySuppress /qn /L*v C:\Windows\Logs\Software\Python_Test_Suite_64bit_symbols-Uninstall.log" -Wait
            Start-Sleep -Seconds 5
        }
    }

    ## Uninstall Any Existing Versions of Python 3.12.0 Test Suite (32-bit)
    Remove-MSIApplications -Name 'Python 3.12.0' -FilterApplication (, ('DisplayName', 'Test Suite (32-bit)', 'Contains'))

    $appList = Get-InstalledApplication -Name 'Python 3.12.0*Test Suite (32-bit)' -WildCard    
    ForEach ($app in $appList) {
        If ($app.UninstallString) {
            $guid = $($app.UninstallString).Replace('MsiExec.exe /I', '').Replace('MsiExec.exe /X', '')
            Write-Log "`n`n[uninstallPython()] [INFO] Found $($app.DisplayName) $($app.DisplayVersion) and a valid uninstall string, now attempting to uninstall.`n`n"       
            Execute-ProcessAsUser -Path "$exeMsiexec" -Parameters "/x $guid REBOOT=ReallySuppress /qn /L*v C:\Windows\Logs\Software\Python_Test_Suite_32bit-Uninstall.log" -Wait
            Start-Sleep -Seconds 5
        }
    }

    ## Uninstall Any Existing Versions of Python 3.12.0 Test Suite (64-bit)
    Remove-MSIApplications -Name 'Python 3.12.0' -FilterApplication (, ('DisplayName', 'Test Suite (64-bit)', 'Contains'))

    $appList = Get-InstalledApplication -Name 'Python 3.12.0*Test Suite (64-bit)' -WildCard    
    ForEach ($app in $appList) {
        If ($app.UninstallString) {
            $guid = $($app.UninstallString).Replace('MsiExec.exe /I', '').Replace('MsiExec.exe /X', '')
            Write-Log "`n`n[uninstallPython()] [INFO] Found $($app.DisplayName) $($app.DisplayVersion) and a valid uninstall string, now attempting to uninstall.`n`n"       
            Execute-ProcessAsUser -Path "$exeMsiexec" -Parameters "/x $guid REBOOT=ReallySuppress /qn /L*v C:\Windows\Logs\Software\Python_Test_Suite_64bit-Uninstall.log" -Wait
            Start-Sleep -Seconds 5
        }
    }

    ## Uninstall Any Existing Versions of Python 3.12.0 Standard Library (32-bit debug)
    Remove-MSIApplications -Name 'Python 3.12.0' -FilterApplication (, ('DisplayName', 'Standard Library (32-bit debug)', 'Contains'))

    $appList = Get-InstalledApplication -Name 'Python 3.12.0*Standard Library (32-bit debug)' -WildCard    
    ForEach ($app in $appList) {
        If ($app.UninstallString) {
            $guid = $($app.UninstallString).Replace('MsiExec.exe /I', '').Replace('MsiExec.exe /X', '')
            Write-Log "`n`n[uninstallPython()] [INFO] Found $($app.DisplayName) $($app.DisplayVersion) and a valid uninstall string, now attempting to uninstall.`n`n"       
            Execute-ProcessAsUser -Path "$exeMsiexec" -Parameters "/x $guid REBOOT=ReallySuppress /qn /L*v C:\Windows\Logs\Software\Python_Standard_Library_32bit_debug-Uninstall.log" -Wait
            Start-Sleep -Seconds 5
        }
    }

    ## Uninstall Any Existing Versions of Python 3.12.0 Standard Library (64-bit debug)
    Remove-MSIApplications -Name 'Python 3.12.0' -FilterApplication (, ('DisplayName', 'Standard Library (64-bit debug)', 'Contains'))

    $appList = Get-InstalledApplication -Name 'Python 3.12.0*Standard Library (64-bit debug)' -WildCard    
    ForEach ($app in $appList) {
        If ($app.UninstallString) {
            $guid = $($app.UninstallString).Replace('MsiExec.exe /I', '').Replace('MsiExec.exe /X', '')
            Write-Log "`n`n[uninstallPython()] [INFO] Found $($app.DisplayName) $($app.DisplayVersion) and a valid uninstall string, now attempting to uninstall.`n`n"       
            Execute-ProcessAsUser -Path "$exeMsiexec" -Parameters "/x $guid REBOOT=ReallySuppress /qn /L*v C:\Windows\Logs\Software\Python_Standard_Library_64bit_debug-Uninstall.log" -Wait
            Start-Sleep -Seconds 5
        }
    }

    ## Uninstall Any Existing Versions of Python 3.12.0 Standard Library (32-bit symbols)
    Remove-MSIApplications -Name 'Python 3.12.0' -FilterApplication (, ('DisplayName', 'Standard Library (32-bit symbols)', 'Contains'))

    $appList = Get-InstalledApplication -Name 'Python 3.12.0*Standard Library (32-bit symbols)' -WildCard    
    ForEach ($app in $appList) {
        If ($app.UninstallString) {
            $guid = $($app.UninstallString).Replace('MsiExec.exe /I', '').Replace('MsiExec.exe /X', '')
            Write-Log "`n`n[uninstallPython()] [INFO] Found $($app.DisplayName) $($app.DisplayVersion) and a valid uninstall string, now attempting to uninstall.`n`n"       
            Execute-ProcessAsUser -Path "$exeMsiexec" -Parameters "/x $guid REBOOT=ReallySuppress /qn /L*v C:\Windows\Logs\Software\Python_Standard_Library_32bit_symbols-Uninstall.log" -Wait
            Start-Sleep -Seconds 5
        }
    }

    ## Uninstall Any Existing Versions of Python 3.12.0 Standard Library (64-bit symbols)
    Remove-MSIApplications -Name 'Python 3.12.0' -FilterApplication (, ('DisplayName', 'Standard Library (64-bit symbols)', 'Contains'))

    $appList = Get-InstalledApplication -Name 'Python 3.12.0*Standard Library (64-bit symbols)' -WildCard    
    ForEach ($app in $appList) {
        If ($app.UninstallString) {
            $guid = $($app.UninstallString).Replace('MsiExec.exe /I', '').Replace('MsiExec.exe /X', '')
            Write-Log "`n`n[uninstallPython()] [INFO] Found $($app.DisplayName) $($app.DisplayVersion) and a valid uninstall string, now attempting to uninstall.`n`n"       
            Execute-ProcessAsUser -Path "$exeMsiexec" -Parameters "/x $guid REBOOT=ReallySuppress /qn /L*v C:\Windows\Logs\Software\Python_Standard_Library_64bit_symbols-Uninstall.log" -Wait
            Start-Sleep -Seconds 5
        }
    }

    ## Uninstall Any Existing Versions of Python 3.12.0 Standard Library (32-bit)
    Remove-MSIApplications -Name 'Python 3.12.0' -FilterApplication (, ('DisplayName', 'Standard Library (32-bit)', 'Contains'))

    $appList = Get-InstalledApplication -Name 'Python 3.12.0*Standard Library (32-bit)' -WildCard    
    ForEach ($app in $appList) {
        If ($app.UninstallString) {
            $guid = $($app.UninstallString).Replace('MsiExec.exe /I', '').Replace('MsiExec.exe /X', '')
            Write-Log "`n`n[uninstallPython()] [INFO] Found $($app.DisplayName) $($app.DisplayVersion) and a valid uninstall string, now attempting to uninstall.`n`n"       
            Execute-ProcessAsUser -Path "$exeMsiexec" -Parameters "/x $guid REBOOT=ReallySuppress /qn /L*v C:\Windows\Logs\Software\Python_Standard_Library_32bit-Uninstall.log" -Wait
            Start-Sleep -Seconds 5
        }
    }

    ## Uninstall Any Existing Versions of Python 3.12.0 Standard Library (64-bit)
    Remove-MSIApplications -Name 'Python 3.12.0' -FilterApplication (, ('DisplayName', 'Standard Library (64-bit)', 'Contains'))

    $appList = Get-InstalledApplication -Name 'Python 3.12.0*Standard Library (64-bit)' -WildCard    
    ForEach ($app in $appList) {
        If ($app.UninstallString) {
            $guid = $($app.UninstallString).Replace('MsiExec.exe /I', '').Replace('MsiExec.exe /X', '')
            Write-Log "`n`n[uninstallPython()] [INFO] Found $($app.DisplayName) $($app.DisplayVersion) and a valid uninstall string, now attempting to uninstall.`n`n"       
            Execute-ProcessAsUser -Path "$exeMsiexec" -Parameters "/x $guid REBOOT=ReallySuppress /qn /L*v C:\Windows\Logs\Software\Python_Standard_Library_64bit-Uninstall.log" -Wait
            Start-Sleep -Seconds 5
        }
    }

    ## Uninstall Any Existing Versions of Python 3.12.0 Development Libraries (32-bit debug)
    Remove-MSIApplications -Name 'Python 3.12.0' -FilterApplication (, ('DisplayName', 'Development Libraries (32-bit debug)', 'Contains'))

    $appList = Get-InstalledApplication -Name 'Python 3.12.0*Development Libraries (32-bit debug)' -WildCard    
    ForEach ($app in $appList) {
        If ($app.UninstallString) {
            $guid = $($app.UninstallString).Replace('MsiExec.exe /I', '').Replace('MsiExec.exe /X', '')
            Write-Log "`n`n[uninstallPython()] [INFO] Found $($app.DisplayName) $($app.DisplayVersion) and a valid uninstall string, now attempting to uninstall.`n`n"       
            Execute-ProcessAsUser -Path "$exeMsiexec" -Parameters "/x $guid REBOOT=ReallySuppress /qn /L*v C:\Windows\Logs\Software\Python_Development_Libraries_32bit_debug-Uninstall.log" -Wait
            Start-Sleep -Seconds 5
        }
    }

    ## Uninstall Any Existing Versions of Python 3.12.0 Development Libraries (64-bit debug)
    Remove-MSIApplications -Name 'Python 3.12.0' -FilterApplication (, ('DisplayName', 'Development Libraries (64-bit debug)', 'Contains'))

    $appList = Get-InstalledApplication -Name 'Python 3.12.0*Development Libraries (64-bit debug)' -WildCard    
    ForEach ($app in $appList) {
        If ($app.UninstallString) {
            $guid = $($app.UninstallString).Replace('MsiExec.exe /I', '').Replace('MsiExec.exe /X', '')
            Write-Log "`n`n[uninstallPython()] [INFO] Found $($app.DisplayName) $($app.DisplayVersion) and a valid uninstall string, now attempting to uninstall.`n`n"       
            Execute-ProcessAsUser -Path "$exeMsiexec" -Parameters "/x $guid REBOOT=ReallySuppress /qn /L*v C:\Windows\Logs\Software\Python_Development_Libraries_64bit_debug-Uninstall.log" -Wait
            Start-Sleep -Seconds 5
        }
    }

    ## Uninstall Any Existing Versions of Python 3.12.0 Development Libraries (32-bit)
    Remove-MSIApplications -Name 'Python 3.12.0' -FilterApplication (, ('DisplayName', 'Development Libraries (32-bit)', 'Contains'))

    $appList = Get-InstalledApplication -Name 'Python 3.12.0*Development Libraries (32-bit)' -WildCard    
    ForEach ($app in $appList) {
        If ($app.UninstallString) {
            $guid = $($app.UninstallString).Replace('MsiExec.exe /I', '').Replace('MsiExec.exe /X', '')
            Write-Log "`n`n[uninstallPython()] [INFO] Found $($app.DisplayName) $($app.DisplayVersion) and a valid uninstall string, now attempting to uninstall.`n`n"       
            Execute-ProcessAsUser -Path "$exeMsiexec" -Parameters "/x $guid REBOOT=ReallySuppress /qn /L*v C:\Windows\Logs\Software\Python_Development_Libraries_32bit-Uninstall.log" -Wait
            Start-Sleep -Seconds 5
        }
    }

    ## Uninstall Any Existing Versions of Python 3.12.0 Development Libraries (64-bit)
    Remove-MSIApplications -Name 'Python 3.12.0' -FilterApplication (, ('DisplayName', 'Development Libraries (64-bit)', 'Contains'))

    $appList = Get-InstalledApplication -Name 'Python 3.12.0*Development Libraries (64-bit)' -WildCard    
    ForEach ($app in $appList) {
        If ($app.UninstallString) {
            $guid = $($app.UninstallString).Replace('MsiExec.exe /I', '').Replace('MsiExec.exe /X', '')
            Write-Log "`n`n[uninstallPython()] [INFO] Found $($app.DisplayName) $($app.DisplayVersion) and a valid uninstall string, now attempting to uninstall.`n`n"       
            Execute-ProcessAsUser -Path "$exeMsiexec" -Parameters "/x $guid REBOOT=ReallySuppress /qn /L*v C:\Windows\Logs\Software\Python_Development_Libraries_64bit-Uninstall.log" -Wait
            Start-Sleep -Seconds 5
        }
    }

    ## Uninstall Any Existing Versions of Python 3.12.0 Executables (32-bit debug)
    Remove-MSIApplications -Name 'Python 3.12.0' -FilterApplication (, ('DisplayName', 'Executables (32-bit debug)', 'Contains'))

    $appList = Get-InstalledApplication -Name 'Python 3.12.0*Executables (32-bit debug)' -WildCard    
    ForEach ($app in $appList) {
        If ($app.UninstallString) {
            $guid = $($app.UninstallString).Replace('MsiExec.exe /I', '').Replace('MsiExec.exe /X', '')
            Write-Log "`n`n[uninstallPython()] [INFO] Found $($app.DisplayName) $($app.DisplayVersion) and a valid uninstall string, now attempting to uninstall.`n`n"       
            Execute-ProcessAsUser -Path "$exeMsiexec" -Parameters "/x $guid REBOOT=ReallySuppress /qn /L*v C:\Windows\Logs\Software\Python_Executables_32bit_debug-Uninstall.log" -Wait
            Start-Sleep -Seconds 5
        }
    }

    ## Uninstall Any Existing Versions of Python 3.12.0 Executables (64-bit debug)
    Remove-MSIApplications -Name 'Python 3.12.0' -FilterApplication (, ('DisplayName', 'Executables (64-bit debug)', 'Contains'))

    $appList = Get-InstalledApplication -Name 'Python 3.12.0*Executables (64-bit debug)' -WildCard    
    ForEach ($app in $appList) {
        If ($app.UninstallString) {
            $guid = $($app.UninstallString).Replace('MsiExec.exe /I', '').Replace('MsiExec.exe /X', '')
            Write-Log "`n`n[uninstallPython()] [INFO] Found $($app.DisplayName) $($app.DisplayVersion) and a valid uninstall string, now attempting to uninstall.`n`n"       
            Execute-ProcessAsUser -Path "$exeMsiexec" -Parameters "/x $guid REBOOT=ReallySuppress /qn /L*v C:\Windows\Logs\Software\Python_Executables_64bit_debug-Uninstall.log" -Wait
            Start-Sleep -Seconds 5
        }
    }

    ## Uninstall Any Existing Versions of Python 3.12.0 Executables (32-bit symbols)
    Remove-MSIApplications -Name 'Python 3.12.0' -FilterApplication (, ('DisplayName', 'Executables (32-bit symbols)', 'Contains'))

    $appList = Get-InstalledApplication -Name 'Python 3.12.0*Executables (32-bit symbols)' -WildCard    
    ForEach ($app in $appList) {
        If ($app.UninstallString) {
            $guid = $($app.UninstallString).Replace('MsiExec.exe /I', '').Replace('MsiExec.exe /X', '')
            Write-Log "`n`n[uninstallPython()] [INFO] Found $($app.DisplayName) $($app.DisplayVersion) and a valid uninstall string, now attempting to uninstall.`n`n"       
            Execute-ProcessAsUser -Path "$exeMsiexec" -Parameters "/x $guid REBOOT=ReallySuppress /qn /L*v C:\Windows\Logs\Software\Python_Executables_32bit_symbols-Uninstall.log" -Wait
            Start-Sleep -Seconds 5
        }
    }

    ## Uninstall Any Existing Versions of Python 3.12.0 Executables (64-bit symbols)
    Remove-MSIApplications -Name 'Python 3.12.0' -FilterApplication (, ('DisplayName', 'Executables (64-bit symbols)', 'Contains'))

    $appList = Get-InstalledApplication -Name 'Python 3.12.0*Executables (64-bit symbols)' -WildCard    
    ForEach ($app in $appList) {
        If ($app.UninstallString) {
            $guid = $($app.UninstallString).Replace('MsiExec.exe /I', '').Replace('MsiExec.exe /X', '')
            Write-Log "`n`n[uninstallPython()] [INFO] Found $($app.DisplayName) $($app.DisplayVersion) and a valid uninstall string, now attempting to uninstall.`n`n"       
            Execute-ProcessAsUser -Path "$exeMsiexec" -Parameters "/x $guid REBOOT=ReallySuppress /qn /L*v C:\Windows\Logs\Software\Python_Executables_64bit_symbols-Uninstall.log" -Wait
            Start-Sleep -Seconds 5
        }
    }

    ## Uninstall Any Existing Versions of Python 3.12.0 Executables (32-bit)
    Remove-MSIApplications -Name 'Python 3.12.0' -FilterApplication (, ('DisplayName', 'Executables (32-bit)', 'Contains'))

    $appList = Get-InstalledApplication -Name 'Python 3.12.0*Executables (32-bit)' -WildCard    
    ForEach ($app in $appList) {
        If ($app.UninstallString) {
            $guid = $($app.UninstallString).Replace('MsiExec.exe /I', '').Replace('MsiExec.exe /X', '')
            Write-Log "`n`n[uninstallPython()] [INFO] Found $($app.DisplayName) $($app.DisplayVersion) and a valid uninstall string, now attempting to uninstall.`n`n"       
            Execute-ProcessAsUser -Path "$exeMsiexec" -Parameters "/x $guid REBOOT=ReallySuppress /qn /L*v C:\Windows\Logs\Software\Python_Executables_32bit-Uninstall.log" -Wait
            Start-Sleep -Seconds 5
        }
    }

    ## Uninstall Any Existing Versions of Python 3.12.0 Executables (64-bit)
    Remove-MSIApplications -Name 'Python 3.12.0' -FilterApplication (, ('DisplayName', 'Executables (64-bit)', 'Contains'))

    $appList = Get-InstalledApplication -Name 'Python 3.12.0*Executables (64-bit)' -WildCard    
    ForEach ($app in $appList) {
        If ($app.UninstallString) {
            $guid = $($app.UninstallString).Replace('MsiExec.exe /I', '').Replace('MsiExec.exe /X', '')
            Write-Log "`n`n[uninstallPython()] [INFO] Found $($app.DisplayName) $($app.DisplayVersion) and a valid uninstall string, now attempting to uninstall.`n`n"       
            Execute-ProcessAsUser -Path "$exeMsiexec" -Parameters "/x $guid REBOOT=ReallySuppress /qn /L*v C:\Windows\Logs\Software\Python_Executables_64bit-Uninstall.log" -Wait
            Start-Sleep -Seconds 5
        }
    }

    ## Uninstall Any Existing Versions of Python 3.12.0 Core Interpreter (32-bit debug)
    Remove-MSIApplications -Name 'Python 3.12.0' -FilterApplication (, ('DisplayName', 'Core Interpreter (32-bit debug)', 'Contains'))

    $appList = Get-InstalledApplication -Name 'Python 3.12.0*Core Interpreter (32-bit debug)' -WildCard    
    ForEach ($app in $appList) {
        If ($app.UninstallString) {
            $guid = $($app.UninstallString).Replace('MsiExec.exe /I', '').Replace('MsiExec.exe /X', '')
            Write-Log "`n`n[uninstallPython()] [INFO] Found $($app.DisplayName) $($app.DisplayVersion) and a valid uninstall string, now attempting to uninstall.`n`n"       
            Execute-ProcessAsUser -Path "$exeMsiexec" -Parameters "/x $guid REBOOT=ReallySuppress /qn /L*v C:\Windows\Logs\Software\Python_Executables_32bit_debug-Uninstall.log" -Wait
            Start-Sleep -Seconds 5
        }
    }

    ## Uninstall Any Existing Versions of Python 3.12.0 Core Interpreter (64-bit debug)
    Remove-MSIApplications -Name 'Python 3.12.0' -FilterApplication (, ('DisplayName', 'Core Interpreter (64-bit debug)', 'Contains'))

    $appList = Get-InstalledApplication -Name 'Python 3.12.0*Core Interpreter (64-bit debug)' -WildCard    
    ForEach ($app in $appList) {
        If ($app.UninstallString) {
            $guid = $($app.UninstallString).Replace('MsiExec.exe /I', '').Replace('MsiExec.exe /X', '')
            Write-Log "`n`n[uninstallPython()] [INFO] Found $($app.DisplayName) $($app.DisplayVersion) and a valid uninstall string, now attempting to uninstall.`n`n"       
            Execute-ProcessAsUser -Path "$exeMsiexec" -Parameters "/x $guid REBOOT=ReallySuppress /qn /L*v C:\Windows\Logs\Software\Python_Executables_64bit_debug-Uninstall.log" -Wait
            Start-Sleep -Seconds 5
        }
    }

    ## Uninstall Any Existing Versions of Python 3.12.0 Core Interpreter (32-bit symbols)
    Remove-MSIApplications -Name 'Python 3.12.0' -FilterApplication (, ('DisplayName', 'Core Interpreter (32-bit symbols)', 'Contains'))

    $appList = Get-InstalledApplication -Name 'Python 3.12.0*Core Interpreter (32-bit symbols)' -WildCard    
    ForEach ($app in $appList) {
        If ($app.UninstallString) {
            $guid = $($app.UninstallString).Replace('MsiExec.exe /I', '').Replace('MsiExec.exe /X', '')
            Write-Log "`n`n[uninstallPython()] [INFO] Found $($app.DisplayName) $($app.DisplayVersion) and a valid uninstall string, now attempting to uninstall.`n`n"       
            Execute-ProcessAsUser -Path "$exeMsiexec" -Parameters "/x $guid REBOOT=ReallySuppress /qn /L*v C:\Windows\Logs\Software\Python_Executables_32bit_symbols-Uninstall.log" -Wait
            Start-Sleep -Seconds 5
        }
    }

    ## Uninstall Any Existing Versions of Python 3.12.0 Core Interpreter (64-bit symbols)
    Remove-MSIApplications -Name 'Python 3.12.0' -FilterApplication (, ('DisplayName', 'Core Interpreter (64-bit symbols)', 'Contains'))

    $appList = Get-InstalledApplication -Name 'Python 3.12.0*Core Interpreter (64-bit symbols)' -WildCard    
    ForEach ($app in $appList) {
        If ($app.UninstallString) {
            $guid = $($app.UninstallString).Replace('MsiExec.exe /I', '').Replace('MsiExec.exe /X', '')
            Write-Log "`n`n[uninstallPython()] [INFO] Found $($app.DisplayName) $($app.DisplayVersion) and a valid uninstall string, now attempting to uninstall.`n`n"       
            Execute-ProcessAsUser -Path "$exeMsiexec" -Parameters "/x $guid REBOOT=ReallySuppress /qn /L*v C:\Windows\Logs\Software\Python_Executables_64bit_symbols-Uninstall.log" -Wait
            Start-Sleep -Seconds 5
        }
    }

    ## Uninstall Any Existing Versions of Python 3.12.0 Core Interpreter (32-bit)
    Remove-MSIApplications -Name 'Python 3.12.0' -FilterApplication (, ('DisplayName', 'Core Interpreter (32-bit)', 'Contains'))

    $appList = Get-InstalledApplication -Name 'Python 3.12.0*Core Interpreter (32-bit)' -WildCard    
    ForEach ($app in $appList) {
        If ($app.UninstallString) {
            $guid = $($app.UninstallString).Replace('MsiExec.exe /I', '').Replace('MsiExec.exe /X', '')
            Write-Log "`n`n[uninstallPython()] [INFO] Found $($app.DisplayName) $($app.DisplayVersion) and a valid uninstall string, now attempting to uninstall.`n`n"       
            Execute-ProcessAsUser -Path "$exeMsiexec" -Parameters "/x $guid REBOOT=ReallySuppress /qn /L*v C:\Windows\Logs\Software\Python_Executables_32bit-Uninstall.log" -Wait
            Start-Sleep -Seconds 5
        }
    }

    ## Uninstall Any Existing Versions of Python 3.12.0 Core Interpreter (64-bit)
    Remove-MSIApplications -Name 'Python 3.12.0' -FilterApplication (, ('DisplayName', 'Core Interpreter (64-bit)', 'Contains'))

    $appList = Get-InstalledApplication -Name 'Python 3.12.0*Core Interpreter (64-bit)' -WildCard    
    ForEach ($app in $appList) {
        If ($app.UninstallString) {
            $guid = $($app.UninstallString).Replace('MsiExec.exe /I', '').Replace('MsiExec.exe /X', '')
            Write-Log "`n`n[uninstallPython()] [INFO] Found $($app.DisplayName) $($app.DisplayVersion) and a valid uninstall string, now attempting to uninstall.`n`n"       
            Execute-ProcessAsUser -Path "$exeMsiexec" -Parameters "/x $guid REBOOT=ReallySuppress /qn /L*v C:\Windows\Logs\Software\Python_Executables_64bit-Uninstall.log" -Wait
            Start-Sleep -Seconds 5
        }
    }

    ## Uninstall Any Existing Versions of Python Launcher
    Remove-MSIApplications -Name 'Python Launcher'

    $appList = Get-InstalledApplication -Name 'Python Launcher'    
    ForEach ($app in $appList) {
        If ($app.UninstallString) {
            $guid = $($app.UninstallString).Replace('MsiExec.exe /I', '').Replace('MsiExec.exe /X', '')
            Write-Log "`n`n[uninstallPython()] [INFO] Found $($app.DisplayName) $($app.DisplayVersion) and a valid uninstall string, now attempting to uninstall.`n`n"       
            Execute-ProcessAsUser -Path "$exeMsiexec" -Parameters "/x $guid REBOOT=ReallySuppress /qn /L*v C:\Windows\Logs\Software\Python_Launcher-Uninstall.log" -Wait
            Start-Sleep -Seconds 5
        }
    }

    <# ## Remove Any Existing Versions of Python 3.12.0 (User Profile)
    $Users = Get-ChildItem -Path "C:\Users"
    ForEach ($user in $Users) {
        $PackageCache = "$($user.fullname)\AppData\Local\Package Cache"
        If (Test-Path $PackageCache) {

            $PythonPath = Get-ChildItem -Path "$PackageCache\*" -Include "python-3.12.0*.exe" -Recurse -ErrorAction SilentlyContinue
            ForEach ($Python in $PythonPath) {
                Write-Log -Message "Found $($Python.FullName), now attempting to uninstall existing versions of Python Launcher."
                Execute-ProcessAsUser -Path "$Python" -Parameters "/uninstall /quiet /norestart /log C:\Windows\Logs\Software\Python_3.12-Uninstall.log" -Wait
                Start-Sleep -Seconds 5
            }
        }
    } #>
}

##*===============================================
##* END FUNCTION LISTINGS
##*===============================================

##*===============================================
##* SCRIPT BODY
##*===============================================

If ($scriptParentPath) {
    Write-Log -Message "Script [$($MyInvocation.MyCommand.Definition)] dot-source invoked by [$(((Get-Variable -Name MyInvocation).Value).ScriptName)]" -Source $appDeployToolkitExtName
}
Else {
    Write-Log -Message "Script [$($MyInvocation.MyCommand.Definition)] invoked directly" -Source $appDeployToolkitExtName
}

##*===============================================
##* END SCRIPT BODY
##*===============================================
