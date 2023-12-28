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
    Show-InstallationProgress -StatusMessage "Installing VideoDownloader. Please wait..."

    $installedVideoDownloaderObject = Get-InstalledApplication -Name "VideoDownloader" -Exact $true
    If ($installedVideoDownloaderObject) {
        $installedVideoDownloaderLocation = $installedVideoDownloaderObject.InstallLocation
        Write-Log "`n`n[installVideoDownloader()] [INFO] Other potentially useful information:`n[$installedVideoDownloaderObject].`n`n"
        Write-Log "`n`n[installVideoDownloader()] [INFO] Found VideoDownloader installation at:`n[$installedVideoDownloaderLocation].`n`n"
    }
    Else {
        If ($pBooleanQuiet) {
            Execute-MSI -Action "Install" -Path $videoDownloaderInstallerLocation -Parameters "/quiet APPDIR=""$pVideoDownloaderInstallationDirectory"""
        }
        Else {
            Execute-MSI -Action "Install" -Path $videoDownloaderInstallerLocation -Parameters "/passive APPDIR=""$pVideoDownloaderInstallationDirectory"""
        }
    }
}

function uninstallVideoDownloader($pBooleanQuiet = $false) {
    Write-Log "`n`n[uninstallVideoDownloader()] [INFO] pBooleanQuiet = $pBooleanQuiet`n`n"
    Show-InstallationProgress -StatusMessage "Uninstalling VideoDownloader. Please wait..."

    $installedVideoDownloaderObject = Get-InstalledApplication -Name "VideoDownloader" -Exact $true
    If ($installedVideoDownloaderObject) {
        $installedVideoDownloaderLocation = $installedVideoDownloaderObject.InstallLocation
        Write-Log "`n`n[uninstallVideoDownloader()] [INFO] Other potentially useful information:`n[$installedVideoDownloaderObject].`n`n"
        Write-Log "`n`n[uninstallVideoDownloader()] [INFO] Found VideoDownloader installation at:`n[$installedVideoDownloaderLocation].`n`n"
        If ($pBooleanQuiet) {
            Execute-MSI -Action "Uninstall" -Path $installedVideoDownloaderObject.ProductCode -Parameters "/quiet"
        }
        Else {
            Execute-MSI -Action "Uninstall" -Path $installedVideoDownloaderObject.ProductCode -Parameters "/passive"
        }
    }
    Else {
        Write-Log "`n`n[uninstallVideoDownloader()] [INFO] Unable to find installed VideoDownloader instance.`n`n"
    }
}

function repairVideoDownloader($pBooleanQuiet = $false) {
    Write-Log "`n`n[repairVideoDownloader()] [INFO] pBooleanQuiet = $pBooleanQuiet`n`n"
    Show-InstallationProgress -StatusMessage "Repairing VideoDownloader. Please wait..."

    $installedVideoDownloaderObject = Get-InstalledApplication -Name "VideoDownloader" -Exact $true
    If ($installedVideoDownloaderObject) {
        $installedVideoDownloaderLocation = $installedVideoDownloaderObject.InstallLocation
        Write-Log "`n`n[repairVideoDownloader()] [INFO] Other potentially useful information:`n[$installedVideoDownloaderObject].`n`n"
        Write-Log "`n`n[repairVideoDownloader()] [INFO] Found VideoDownloader installation at:`n[$installedVideoDownloaderLocation].`n`n"
        If ($pBooleanQuiet) {
            Execute-MSI -Action "Repair" -Path $installedVideoDownloaderObject.ProductCode -Parameters "/quiet"
        }
        Else {
            Execute-MSI -Action "Repair" -Path $installedVideoDownloaderObject.ProductCode -Parameters "/passive"
        }
    }
    Else {
        Write-Log "`n`n[repairVideoDownloader()] [INFO] Unable to find installed VideoDownloader instance.`n`n"
        # Language support needed.
        $balloonText = "No installed VideoDownloader instance found. Please run the installer afterwards."
        Show-BalloonTip -BalloonTipText $balloonText -BalloonTipIcon "Warning"
    }
}

#********************Python********************#

function installPython($pPythonInstallDirectory, $pBooleanQuiet = $false) {
    Write-Log "`n`n[installPython()] [INFO] pPythonInstallDirectory = $pPythonInstallDirectory`n`n"
    Write-Log "`n`n[installPython()] [INFO] pBooleanQuiet = $pBooleanQuiet`n`n"
    Show-InstallationProgress -StatusMessage "Checking system requirements for Python 3.12.0. Please wait..."

    If (getPythonInstallStatus) {
        $installedPythonObject = Get-InstalledApplication -Name "Python 3.12"
        If ($installedPythonObject) {
            $installedPythonLocation = $installedPythonObject.InstallLocation
            Write-Log "`n`n[installPython()] [INFO] Other potentially useful information:`n[$installedPythonObject].`n`n"
            Write-Log "`n`n[installPython()] [INFO] Found Python 3.12.x installation at:`n[$installedPythonLocation].`n`n"
        }
        Else {
            Write-Log "`n`n[installPython()] [WARNING] Python launcher is already installed but running a repair action is recommended due to missing Python 3.12.`n`n"
            # Language support needed.
            $balloonText = "Python installation seems corrupted. It is recommended to repair the VideoDownloader installation afterwards."
            Show-BalloonTip -BalloonTipText $balloonText -BalloonTipIcon "Warning"
        }
    }
    Else {
        If (checkPythonInstallerFilesPresence) {
            $exePath64 = Get-ChildItem -Path "$dirFiles" -Include "python-3*amd64.exe" -File -Recurse -ErrorAction SilentlyContinue
            $exePath32 = Get-ChildItem -Path "$dirFiles" -Include "python-3*.exe" -Exclude "python-3*amd64.exe" -File -Recurse -ErrorAction SilentlyContinue
            If ($pBooleanQuiet) {
                $parameterString = "/quiet TargetDir=""$pPythonInstallDirectory"""
            }
            Else {
                $parameterString = "/passive TargetDir=""$pPythonInstallDirectory"""
            }
            If ($ENV:PROCESSOR_ARCHITECTURE -eq "x86") {
                Write-Log "`n`n[installPython()] [INFO] Detected 32-bit OS architecture.`n`n"
                # Install Python 3.12 (32-bit).
                If ($exePath32.Exists) {
                    Write-Log "`n`n[installPython()] [INFO] Found $($exePath32.FullName), now attempting to install Python 3.12.0 (32-bit).`n`n"     
                    Show-InstallationProgress -StatusMessage "Installing Python 3.12.0 (32-bit). This might take some time. Please wait..."
                    Execute-ProcessAsUser -Path "$exePath32" -Parameters $parameterString -Wait
                }     
            }
            Else {
                Write-Log "`n`n[installPython()] [INFO] Detected 64-bit OS architecture.`n`n"
                # Install Python 3.12 (64-bit).
                If ($exePath64.Exists) {
                    Write-Log "`n`n[installPython()] [INFO] Found $($exePath64.FullName), now attempting to install Python 3.12.0 (64-bit).`n`n"              
                    Show-InstallationProgress -StatusMessage "Installing Python 3.12.0 (64-bit). This might take some time. Please wait..."
                    Execute-ProcessAsUser -Path "$exePath64" -Parameters $parameterString -Wait
                }
                # Install Python 3.12 (32-bit) if 64-bit installer is not available.     
                ElseIf ($exePath32.Exists) {
                    Write-Log "`n`n[installPython()] [INFO] Found $($exePath32.FullName), now attempting to install Python 3.12.0 (32-bit).`n`n"     
                    Show-InstallationProgress -StatusMessage "Installing Python 3.12.0 (32-bit). This might take some time. Please wait..."
                    Execute-ProcessAsUser -Path "$exePath32" -Parameters $parameterString -Wait
                }
            }
        }
        Else {
            Write-Log "`n`n[installPython()] [WARNING] Stopped because the Python installer files are missing!`n`n"
            # Language support needed.
            $balloonText = "Python installation stopped due to missing installer files!"
            Show-BalloonTip -BalloonTipText $balloonText -BalloonTipIcon "Warning"
        }
    }
}

function uninstallPython() {
    Show-InstallationProgress -StatusMessage "Uninstalling Python 3.12.0. This might take some time. Please wait..."

    $installedPythonObject = Get-InstalledApplication -Name "Python 3.12.0"
    If ($installedPythonObject) {
        $installedPythonLocation = $installedPythonObject.InstallLocation
        Write-Log "`n`n[uninstallPython()] [INFO] Other potentially useful information:`n[$installedPythonObject].`n`n"
        Write-Log "`n`n[uninstallPython()] [INFO] Found Python 3.12.0 installation at:`n[$installedPythonLocation].`n`n"
        Write-Log "`n`n[uninstallPython()] [INFO] Starting Python 3.12 uninstallation.`n`n"
        uninstallAllPythonCompletly
    }
    Else {
        Write-Log "`n`n[uninstallPython()] [INFO] Unable to find installed Python 3.12.0 instance.`n`n"
    }
}

function repairPython($pBooleanQuiet = $false) {
    Write-Log "`n`n[repairPython()] [INFO] pBooleanQuiet = $pBooleanQuiet`n`n"
    Show-InstallationProgress -StatusMessage "Repairing Python 3.12.0. This might take some time. Please wait..."

    $installedPythonObject = Get-InstalledApplication -Name "Python 3.12.0"
    If ($installedPythonObject) {
        $installedPythonLocation = $installedPythonObject.InstallLocation
        Write-Log "`n`n[repairPython()] [INFO] Other potentially useful information:`n[$installedPythonObject].`n`n"
        Write-Log "`n`n[repairPython()] [INFO] Found Python 3.12.0 installation at:`n[$installedPythonLocation].`n`n"
        Write-Log "`n`n[repairPython()] [INFO] Starting Python 3.12 repair.`n`n"

        $exePath64 = Get-ChildItem -Path "$dirFiles" -Include "python-3*amd64.exe" -File -Recurse -ErrorAction SilentlyContinue
        $exePath32 = Get-ChildItem -Path "$dirFiles" -Include "python-3*.exe" -Exclude "python-3*amd64.exe" -File -Recurse -ErrorAction SilentlyContinue
        If ($pBooleanQuiet) {
            $parameterString = "/quiet /repair"
        }
        Else {
            $parameterString = "/passive /repair"
        }
        If ($installedPythonObject.Is64BitApplication) {
            Write-Log "`n`n[installPython()] [INFO] Found Python 3.12.0 (64-bit).`n`n"
            # Repair Python 3.12 (64-bit).
            If ($exePath64.Exists) {
                Write-Log "`n`n[installPython()] [INFO] Found $($exePath64.FullName), now attempting to repair Python 3.12.0 (64-bit).`n`n"              
                Show-InstallationProgress -StatusMessage "Repairing Python 3.12.0 (64-bit). This might take some time. Please wait..."
                Execute-ProcessAsUser -Path "$exePath64" -Parameters $parameterString -Wait
            }
        }
        Else {
            Write-Log "`n`n[installPython()] [INFO] Found Python 3.12.0 (32-bit).`n`n"
            # Repair Python 3.12 (32-bit).
            If ($exePath32.Exists) {
                Write-Log "`n`n[installPython()] [INFO] Found $($exePath32.FullName), now attempting to repair Python 3.12.0 (32-bit).`n`n"              
                Show-InstallationProgress -StatusMessage "Repairing Python 3.12.0 (32-bit). This might take some time. Please wait..."
                Execute-ProcessAsUser -Path "$exePath32" -Parameters $parameterString -Wait
            }
        }
    }
    Else {
        Write-Log "`n`n[repairPython()] [INFO] Unable to find installed Python 3.12.0 instance.`n`n"
        # Language support needed.
        $balloonText = "No installed Python 3.12.0 instance found. Please run the installer afterwards."
        Show-BalloonTip -BalloonTipText $balloonText -BalloonTipIcon "Warning"
    }
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
    Show-InstallationProgress -StatusMessage "Running yt-dlp setup script (install). Please wait..."

    Write-Log "`n`n**********[yt-dlp Setup Script START]**********`n`n"
    If (-not (Test-Path -Path $ytdlpSetupScriptLocation)) {
        Write-Log "`n`n[installYTDLP()] [ERROR] Could not find yt-dlp setup script at`n[$ytdlpSetupScriptLocation]!`n`n"
    }
    # If yt-dlp is installed.
    ElseIf (checkYTDLPInstallationStatus -pPythonInstallationDirectory $pPythonInstallationDirectory -pBooleanQuiet $pBooleanQuiet) {
        Write-Log "`n`n[installYTDLP()] [INFO] Stopped because yt-dlp is already installed.`n`n"
    }
    Else {
        If ($pBooleanQuiet) {
            $optionalQuietWindowParameter = "Hidden"
        }
        Else {
            $optionalQuietWindowParameter = "Normal"
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
            # REWORK NEEDED
        }
        # Normal error code range.
        ElseIf (($exitCode -ge 71101) -and ($exitCode -le 71200)) {
            Write-Log "`n`n[installYTDLP()] [INFO] Normal exit code received [Exit Code = $exitCode].`n`n"
            # True when yt-dlp was successfully installed.
            If ($exitCode -eq 71101) {
                If (checkYTDLPInstallationStatus -pPythonInstallationDirectory $pPythonInstallationDirectory -pBooleanQuiet $pBooleanQuiet) {
                    Write-Log "`n`n[installYTDLP()] [INFO] yt-dlp has been successfully installed.`n`n"
                }
                Else {
                    Write-Log "`n`n[installYTDLP()] [WARNING] yt-dlp has not been successfully installed.`n`n"
                }
            }
            Else {
                Write-Log "`n`n[installYTDLP()] [WARNING] yt-dlp has not been successfully installed.`n`n"
            }
        }
        Else {
            Write-Log "`n`n[installYTDLP()] [WARNING] Unknown exit code received [Exit Code = $exitCode]!`n`n"
        }
        # Install yt-dlp END.
    }
    Write-Log "`n`n**********[yt-dlp Setup Script END]**********`n`n"
}

function uninstallYTDLP($pPythonInstallationDirectory, $pBooleanQuiet = $false) {
    Write-Log "`n`n[uninstallYTDLP()] [INFO] pPythonInstallationDirectory = $pPythonInstallationDirectory`n`n"
    Write-Log "`n`n[uninstallYTDLP()] [INFO] pBooleanQuiet = $pBooleanQuiet`n`n" 
    Show-InstallationProgress -StatusMessage "Running yt-dlp setup script (uninstall). Please wait..."

    Write-Log "`n`n**********[yt-dlp Setup Script START]**********`n`n"
    If (-not (Test-Path -Path $ytdlpSetupScriptLocation)) {
        Write-Log "`n`n[uninstallYTDLP()] [ERROR] Could not find yt-dlp setup script at`n[$ytdlpSetupScriptLocation]!`n`n"
    }
    # If yt-dlp is installed.
    ElseIf (checkYTDLPInstallationStatus -pPythonInstallationDirectory $pPythonInstallationDirectory -pBooleanQuiet $pBooleanQuiet) {
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
            # REWORK NEEDED
        }
        # Normal error code range.
        ElseIf (($exitCode -ge 71101) -and ($exitCode -le 71200)) {
            Write-Log "`n`n[uninstallYTDLP()] [INFO] Normal exit code received [Exit Code = $exitCode].`n`n"
            # True when yt-dlp was successfully uninstalled.
            If ($exitCode -eq 71105) {
                If (checkYTDLPInstallationStatus -pPythonInstallationDirectory $pPythonInstallationDirectory -pBooleanQuiet $pBooleanQuiet) {
                    Write-Log "`n`n[uninstallYTDLP()] [WARNING] yt-dlp has not been successfully uninstalled.`n`n"   
                }
                Else {
                    Write-Log "`n`n[uninstallYTDLP()] [INFO] yt-dlp has been successfully uninstalled.`n`n" 
                }
            }
            Else {
                Write-Log "`n`n[uninstallYTDLP()] [WARNING] yt-dlp has not been successfully uninstalled.`n`n"
            }
        }
        Else {
            Write-Log "`n`n[uninstallYTDLP()] [WARNING] Unknown exit code received [Exit Code = $exitCode]!`n`n"
        }
        # Uninstall yt-dlp END.
    }
    Else {
        Write-Log "`n`n[uninstallYTDLP()] [INFO] Stopped because yt-dlp is not installed.`n`n"
    }
    Write-Log "`n`n**********[yt-dlp Setup Script END]**********`n`n"
}

function repairYTDLP($pPythonInstallationDirectory, $pBooleanQuiet = $false) {
    Write-Log "`n`n[repairYTDLP()] [INFO] pPythonInstallationDirectory = $pPythonInstallationDirectory`n`n"
    Write-Log "`n`n[repairYTDLP()] [INFO] pBooleanQuiet = $pBooleanQuiet`n`n" 
    Show-InstallationProgress -StatusMessage "Running yt-dlp setup script (repair). Please wait..."

    Write-Log "`n`n**********[yt-dlp Setup Script START]**********`n`n"
    If (-not (Test-Path -Path $ytdlpSetupScriptLocation)) {
        Write-Log "`n`n[repairYTDLP()] [ERROR] Could not find yt-dlp setup script at`n[$ytdlpSetupScriptLocation]!`n`n"
    }
    # If yt-dlp is installed.
    ElseIf (checkYTDLPInstallationStatus -pPythonInstallationDirectory $pPythonInstallationDirectory -pBooleanQuiet $pBooleanQuiet) {
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
            # REWORK NEEDED
        }
        # Normal error code range.
        ElseIf (($exitCode -ge 71101) -and ($exitCode -le 71200)) {
            Write-Log "`n`n[repairYTDLP()] [INFO] Normal exit code received [Exit Code = $exitCode].`n`n"
            # True when yt-dlp was successfully re-installed.
            If ($exitCode -eq 71107) {
                If (checkYTDLPInstallationStatus -pPythonInstallationDirectory $pPythonInstallationDirectory -pBooleanQuiet $pBooleanQuiet) {
                    Write-Log "`n`n[repairYTDLP()] [INFO] yt-dlp has been successfully re-installed.`n`n"  
                }
                Else {
                    Write-Log "`n`n[repairYTDLP()] [WARNING] yt-dlp has not been successfully re-installed.`n`n"
                }
            }
            Else {
                Write-Log "`n`n[repairYTDLP()] [WARNING] yt-dlp has not been successfully re-installed.`n`n"
            }
        }
        Else {
            Write-Log "`n`n[repairYTDLP()] [WARNING] Unknown exit code received [Exit Code = $exitCode]!`n`n"
        }
        # Repair yt-dlp END.
    }
    Else {
        Write-Log "`n`n[repairYTDLP()] [INFO] Stopped because yt-dlp is not installed.`n`n"
        # Language support needed.
        $balloonText = "No installed yt-dlp instance found. Please run the installer afterwards."
        Show-BalloonTip -BalloonTipText $balloonText -BalloonTipIcon "Warning"
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
        # REWORK NEEDED
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
    Show-InstallationProgress -StatusMessage "Running FFmpeg setup script (install). Please wait..."

    Write-Log "`n`n**********[FFmpeg Setup Script START]**********`n`n"
    If (-not (Test-Path -Path $ffmpegSetupScriptLocation)) {
        Write-Log "`n`n[installFFmpeg()] [ERROR] Could not find FFmpeg setup script at`n[$ffmpegSetupScriptLocation]!`n`n"
    }
    # If FFmpeg is installed.
    ElseIf (checkFFmpegInstallationStatus -pVideoDownloaderInstallationDirectory $pVideoDownloaderInstallationDirectory -pBooleanQuiet $pBooleanQuiet) {
        Write-Log "`n`n[installFFmpeg()] [INFO] Stopped because FFmpeg is already installed.`n`n"
    }
    Else {
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
            # REWORK NEEDED
        }
        # Normal error code range.
        ElseIf (($exitCode -ge 71601) -and ($exitCode -le 71700)) {
            Write-Log "`n`n[installFFmpeg()] [INFO] Normal exit code received [Exit Code = $exitCode].`n`n"
            # True when FFmpeg was successfully installed.
            If ($exitCode -eq 71603) {
                If (checkFFmpegInstallationStatus -pVideoDownloaderInstallationDirectory $pVideoDownloaderInstallationDirectory -pBooleanQuiet $pBooleanQuiet) {
                    Write-Log "`n`n[installFFmpeg()] [INFO] FFmpeg has been successfully installed.`n`n"
                }
                Else {
                    Write-Log "`n`n[installFFmpeg()] [WARNING] FFmpeg has not been successfully installed.`n`n"
                }
            }
            Else {
                Write-Log "`n`n[installFFmpeg()] [WARNING] FFmpeg has not been successfully installed.`n`n"
            }
        }
        Else {
            Write-Log "`n`n[installFFmpeg()] [WARNING] Unknown exit code received [Exit Code = $exitCode]!`n`n"
        }
        # Install FFmpeg END.
    }
    Write-Log "`n`n**********[FFmpeg Setup Script END]**********`n`n"
}

function uninstallFFmpeg($pVideoDownloaderInstallationDirectory, $pBooleanQuiet = $false) {
    Write-Log "`n`n[uninstallFFmpeg] [INFO] pVideoDownloaderInstallationDirectory = $pVideoDownloaderInstallationDirectory`n`n"
    Write-Log "`n`n[uninstallFFmpeg()] [INFO] pBooleanQuiet = $pBooleanQuiet`n`n" 
    Show-InstallationProgress -StatusMessage "Running FFmpeg setup script (uninstall). Please wait..."

    Write-Log "`n`n**********[FFmpeg Setup Script START]**********`n`n"
    If (-not (Test-Path -Path $ffmpegSetupScriptLocation)) {
        Write-Log "`n`n[uninstallFFmpeg()] [ERROR] Could not find FFmpeg setup script at`n[$ffmpegSetupScriptLocation]!`n`n"
    }
    # If FFmpeg is installed.
    ElseIf (checkFFmpegInstallationStatus -pVideoDownloaderInstallationDirectory $pVideoDownloaderInstallationDirectory -pBooleanQuiet $pBooleanQuiet) {
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
            # REWORK NEEDED
        }
        # Normal error code range.
        ElseIf (($exitCode -ge 71601) -and ($exitCode -le 71700)) {
            Write-Log "`n`n[uninstallFFmpeg()] [INFO] Normal exit code received [Exit Code = $exitCode].`n`n"
            # True when FFmpeg was successfully uninstalled.
            If ($exitCode -eq 71604) {
                If (checkFFmpegInstallationStatus -pVideoDownloaderInstallationDirectory $pVideoDownloaderInstallationDirectory -pBooleanQuiet $pBooleanQuiet) {
                    Write-Log "`n`n[uninstallFFmpeg()] [WARNING] FFmpeg has not been successfully uninstalled.`n`n"   
                }
                Else {
                    Write-Log "`n`n[uninstallFFmpeg()] [INFO] FFmpeg has been successfully uninstalled.`n`n" 
                }
            }
            Else {
                Write-Log "`n`n[uninstallFFmpeg()] [WARNING] FFmpeg has not been successfully uninstalled.`n`n"
            }
        }
        Else {
            Write-Log "`n`n[uninstallFFmpeg()] [WARNING] Unknown exit code received [Exit Code = $exitCode]!`n`n"
        }
        # Uninstall FFmpeg END.
    }
    Else {
        Write-Log "`n`n[uninstallFFmpeg()] [INFO] Stopped because FFmpeg is not installed.`n`n"
    }
    Write-Log "`n`n**********[FFmpeg Setup Script END]**********`n`n"
}

function repairFFmpeg($pVideoDownloaderInstallationDirectory, $pBooleanQuiet = $false) {
    Write-Log "`n`n[repairFFmpeg()] [INFO] pVideoDownloaderInstallationDirectory = $pVideoDownloaderInstallationDirectory`n`n"
    Write-Log "`n`n[repairFFmpeg()] [INFO] pBooleanQuiet = $pBooleanQuiet`n`n" 
    Show-InstallationProgress -StatusMessage "Running FFmpeg setup script (repair). Please wait..."

    Write-Log "`n`n**********[FFmpeg Setup Script START]**********`n`n"
    If (-not (Test-Path -Path $ffmpegSetupScriptLocation)) {
        Write-Log "`n`n[repairFFmpeg()] [ERROR] Could not find FFmpeg setup script at`n[$ffmpegSetupScriptLocation]!`n`n"
    }
    # If FFmpeg is installed.
    ElseIf (checkFFmpegInstallationStatus -pVideoDownloaderInstallationDirectory $pVideoDownloaderInstallationDirectory -pBooleanQuiet $pBooleanQuiet) {
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
            # REWORK NEEDED
        }
        # Normal error code range.
        ElseIf (($exitCode -ge 71601) -and ($exitCode -le 71700)) {
            Write-Log "`n`n[repairFFmpeg()] [INFO] Normal exit code received [Exit Code = $exitCode].`n`n"
            # True when FFmpeg was successfully uninstalled and installed afterwards.
            If ($exitCode -eq 71603) {
                If (checkFFmpegInstallationStatus -pVideoDownloaderInstallationDirectory $pVideoDownloaderInstallationDirectory -pBooleanQuiet $pBooleanQuiet) {
                    Write-Log "`n`n[repairFFmpeg()] [INFO] FFmpeg has been successfully re-installed.`n`n"
                }
                Else {
                    Write-Log "`n`n[repairFFmpeg()] [WARNING] FFmpeg has not been successfully re-installed.`n`n" 
                }
            }
            Else {
                Write-Log "`n`n[repairFFmpeg()] [WARNING] FFmpeg has not been successfully re-installed.`n`n" 
            }
        }
        Else {
            Write-Log "`n`n[repairFFmpeg()] [WARNING] Unknown exit code received [Exit Code = $exitCode]!`n`n"
        }
        # Repair FFmpeg END.
    }
    Else {
        Write-Log "`n`n[repairFFmpeg()] [INFO] Stopped because FFmpeg is not installed.`n`n"
        # Language support needed.
        $balloonText = "No installed FFmpeg instance found. Please run the installer afterwards."
        Show-BalloonTip -BalloonTipText $balloonText -BalloonTipIcon "Warning"
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
        # REWORK NEEDED
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
        Write-Host "[getPythonInstallStatus()] [ERROR] Error while checking Python presence:`n`n$_`n`n"
        Return $false
    }
}

function checkPythonInstallerFilesPresence([bool]$pBooleanNoDownload = $false) {
    $scriptRootPathParent = Split-Path -Path $PSScriptRoot -Parent
    $pythonInstallerFinalPath = "$scriptRootPathParent\Files"
    $pythonInstaller32Name = "python-3.12.0.exe"
    $pythonInstaller64Name = "python-3.12.0-amd64.exe"
    $pythonInstaller32DownloadLink = "https://www.python.org/ftp/python/3.12.0/python-3.12.0.exe"
    $pythonInstaller64DownloadLink = "https://www.python.org/ftp/python/3.12.0/python-3.12.0-amd64.exe"
    Write-Log "[checkPythonInstallerFilesPresence()] [INFO] pBooleanNoDownload = $pBooleanNoDownload)"
    Write-Log "[checkPythonInstallerFilesPresence()] [INFO] pythonInstallerFinalPath = $pythonInstallerFinalPath)"
    Write-Log "[checkPythonInstallerFilesPresence()] [INFO] pythonInstaller32Name = $pythonInstaller32Name"
    Write-Log "[checkPythonInstallerFilesPresence()] [INFO] pythonInstaller64Name = $pythonInstaller64Name"
    Write-Log "[checkPythonInstallerFilesPresence()] [INFO] pythonInstaller32DownloadLink = $pythonInstaller32DownloadLink"
    Write-Log "[checkPythonInstallerFilesPresence()] [INFO] pythonInstaller64DownloadLink = $pythonInstaller64DownloadLink"
    If (-not (validatePath($pythonInstallerFinalPath))) {
        Write-Log "[checkPythonInstallerFilesPresence()] [ERROR] Invalid Python installer path found:`n[$pythonInstallerFinalPath]!"
        Start-Sleep -Seconds 5
        Exit # REWORK
    }
    # Test if both the 32 and 64 bit executables are present and starts the download if not.
    If (-not (Test-Path -Path "$pythonInstallerFinalPath\$pythonInstaller32Name")) {
        If ($pBooleanNoDownload -eq $true) {
            Write-Log "[checkPythonInstallerFilesPresence()] [WARNING] Missing Python 32 bit setup executable."
            Return $false
        }
        Else {
            Write-Log "[checkPythonInstallerFilesPresence()] [INFO] Missing Python 32 bit setup executable. Starting download..."
            Try {
                Invoke-WebRequest -Uri $pythonInstaller32DownloadLink -OutFile "$pythonInstallerFinalPath\$pythonInstaller32Name"
                Write-Log "[checkPythonInstallerFilesPresence()] [INFO] Downloaded 32 bit executable to`n[$pythonInstallerFinalPath]."
            }
            Catch {
                Write-Log "[checkPythonInstallerFilesPresence()] [WARNING] Error while downloading 32 bit setup executable!"
                Return $false
            }
        }
    }
    Else {
        Write-Log "[checkPythonInstallerFilesPresence()] [INFO] Found 32 bit executable at`n[$pythonInstallerFinalPath\$pythonInstaller32Name]."
    }
    If (-not (Test-Path -Path "$pythonInstallerFinalPath\$pythonInstaller64Name")) {
        If ($pBooleanNoDownload -eq $true) {
            Write-Log "[checkPythonInstallerFilesPresence()] [WARNING] Missing Python 64 bit setup executable."
            Return $false
        }
        Else {
            Write-Log "[checkPythonInstallerFilesPresence()] [INFO] Missing Python 64 bit setup executable. Starting download..."
            Try {
                Invoke-WebRequest -Uri $pythonInstaller64DownloadLink -OutFile "$pythonInstallerFinalPath\$pythonInstaller64Name"
                Write-Log "[checkPythonInstallerFilesPresence()] [INFO] Downloaded 64 bit executable to`n[$pythonInstallerFinalPath]."
            }
            Catch {
                Write-Log "[checkPythonInstallerFilesPresence()] [WARNING] Error while downloading 64 bit setup executable!"
                Return $false
            }  
        }
    }
    Else {
        Write-Log "[checkPythonInstallerFilesPresence()] [INFO] Found 64 bit executable at`n[$pythonInstallerFinalPath\$pythonInstaller64Name]."
    }
    Return $true
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

function uninstallAllPythonCompletly() {
    $AppList = Get-InstalledApplication -Name 'Python 3.12*Add to Path*' -WildCard    
    ForEach ($App in $AppList) {
        If ($App.UninstallString) {
            $GUID = $($App.UninstallString).Replace('MsiExec.exe /I', '').Replace('MsiExec.exe /X', '')
            Write-Log -Message "Found $($App.DisplayName) $($App.DisplayVersion) and a valid uninstall string, now attempting to uninstall."       
            Execute-ProcessAsUser -Path "$exeMsiexec" -Parameters "/x $GUID REBOOT=ReallySuppress /qn /L*v C:\Windows\Logs\Software\Python_Add_to_Path-Uninstall.log" -Wait
            Start-Sleep -Seconds 5
        }
    }

    ## Uninstall Any Existing Versions of Python 3.12 pip Bootstrap
    Remove-MSIApplications -Name 'Python 3.12' -FilterApplication (, ('DisplayName', 'pip Bootstrap', 'Contains'))

    $AppList = Get-InstalledApplication -Name 'Python 3.12*pip Bootstrap*' -WildCard    
    ForEach ($App in $AppList) {
        If ($App.UninstallString) {
            $GUID = $($App.UninstallString).Replace('MsiExec.exe /I', '').Replace('MsiExec.exe /X', '')
            Write-Log -Message "Found $($App.DisplayName) $($App.DisplayVersion) and a valid uninstall string, now attempting to uninstall."       
            Execute-ProcessAsUser -Path "$exeMsiexec" -Parameters "/x $GUID REBOOT=ReallySuppress /qn /L*v C:\Windows\Logs\Software\Python_pip_Bootstrap-Uninstall.log" -Wait
            Start-Sleep -Seconds 5
        }
    }

    ## Uninstall Any Existing Versions of Python 3.12 Tcl/Tk Support (32-bit debug)
    Remove-MSIApplications -Name 'Python 3.12' -FilterApplication (, ('DisplayName', 'Tcl/Tk Support (32-bit debug)', 'Contains'))

    $AppList = Get-InstalledApplication -Name 'Python 3.12*Tcl/Tk Support (32-bit debug)' -WildCard    
    ForEach ($App in $AppList) {
        If ($App.UninstallString) {
            $GUID = $($App.UninstallString).Replace('MsiExec.exe /I', '').Replace('MsiExec.exe /X', '')
            Write-Log -Message "Found $($App.DisplayName) $($App.DisplayVersion) and a valid uninstall string, now attempting to uninstall."       
            Execute-ProcessAsUser -Path "$exeMsiexec" -Parameters "/x $GUID REBOOT=ReallySuppress /qn /L*v C:\Windows\Logs\Software\Python_Tcl_Tk_Support_32bit_debug-Uninstall.log" -Wait
            Start-Sleep -Seconds 5
        }
    }

    ## Uninstall Any Existing Versions of Python 3.12 Tcl/Tk Support (64-bit debug)
    Remove-MSIApplications -Name 'Python 3.12' -FilterApplication (, ('DisplayName', 'Tcl/Tk Support (64-bit debug)', 'Contains'))

    $AppList = Get-InstalledApplication -Name 'Python 3.12*Tcl/Tk Support (64-bit debug)' -WildCard    
    ForEach ($App in $AppList) {
        If ($App.UninstallString) {
            $GUID = $($App.UninstallString).Replace('MsiExec.exe /I', '').Replace('MsiExec.exe /X', '')
            Write-Log -Message "Found $($App.DisplayName) $($App.DisplayVersion) and a valid uninstall string, now attempting to uninstall."       
            Execute-ProcessAsUser -Path "$exeMsiexec" -Parameters "/x $GUID REBOOT=ReallySuppress /qn /L*v C:\Windows\Logs\Software\Python_Tcl_Tk_Support_64bit_debug-Uninstall.log" -Wait
            Start-Sleep -Seconds 5
        }
    }

    ## Uninstall Any Existing Versions of Python 3.12 Tcl/Tk Support (32-bit symbols)
    Remove-MSIApplications -Name 'Python 3.12' -FilterApplication (, ('DisplayName', 'Tcl/Tk Support (32-bit symbols)', 'Contains'))

    $AppList = Get-InstalledApplication -Name 'Python 3.12*Tcl/Tk Support (32-bit symbols)' -WildCard    
    ForEach ($App in $AppList) {
        If ($App.UninstallString) {
            $GUID = $($App.UninstallString).Replace('MsiExec.exe /I', '').Replace('MsiExec.exe /X', '')
            Write-Log -Message "Found $($App.DisplayName) $($App.DisplayVersion) and a valid uninstall string, now attempting to uninstall."       
            Execute-ProcessAsUser -Path "$exeMsiexec" -Parameters "/x $GUID REBOOT=ReallySuppress /qn /L*v C:\Windows\Logs\Software\Python_Tcl_Tk_Support_32bit_symbols-Uninstall.log" -Wait
            Start-Sleep -Seconds 5
        }
    }

    ## Uninstall Any Existing Versions of Python 3.12 Tcl/Tk Support (64-bit symbols)
    Remove-MSIApplications -Name 'Python 3.12' -FilterApplication (, ('DisplayName', 'Tcl/Tk Support (64-bit symbols)', 'Contains'))

    $AppList = Get-InstalledApplication -Name 'Python 3.12*Tcl/Tk Support (64-bit symbols)' -WildCard    
    ForEach ($App in $AppList) {
        If ($App.UninstallString) {
            $GUID = $($App.UninstallString).Replace('MsiExec.exe /I', '').Replace('MsiExec.exe /X', '')
            Write-Log -Message "Found $($App.DisplayName) $($App.DisplayVersion) and a valid uninstall string, now attempting to uninstall."       
            Execute-ProcessAsUser -Path "$exeMsiexec" -Parameters "/x $GUID REBOOT=ReallySuppress /qn /L*v C:\Windows\Logs\Software\Python_Tcl_Tk_Support_64bit_symbols-Uninstall.log" -Wait
            Start-Sleep -Seconds 5
        }
    }

    ## Uninstall Any Existing Versions of Python 3.12 Tcl/Tk Support (32-bit)
    Remove-MSIApplications -Name 'Python 3.12' -FilterApplication (, ('DisplayName', 'Tcl/Tk Support (32-bit)', 'Contains'))

    $AppList = Get-InstalledApplication -Name 'Python 3.12*Tcl/Tk Support (32-bit)' -WildCard    
    ForEach ($App in $AppList) {
        If ($App.UninstallString) {
            $GUID = $($App.UninstallString).Replace('MsiExec.exe /I', '').Replace('MsiExec.exe /X', '')
            Write-Log -Message "Found $($App.DisplayName) $($App.DisplayVersion) and a valid uninstall string, now attempting to uninstall."       
            Execute-ProcessAsUser -Path "$exeMsiexec" -Parameters "/x $GUID REBOOT=ReallySuppress /qn /L*v C:\Windows\Logs\Software\Python_Tcl_Tk_Support_32bit-Uninstall.log" -Wait
            Start-Sleep -Seconds 5
        }
    }

    ## Uninstall Any Existing Versions of Python 3.12 Tcl/Tk Support (64-bit)
    Remove-MSIApplications -Name 'Python 3.12' -FilterApplication (, ('DisplayName', 'Tcl/Tk Support (64-bit)', 'Contains'))

    $AppList = Get-InstalledApplication -Name 'Python 3.12*Tcl/Tk Support (64-bit)' -WildCard    
    ForEach ($App in $AppList) {
        If ($App.UninstallString) {
            $GUID = $($App.UninstallString).Replace('MsiExec.exe /I', '').Replace('MsiExec.exe /X', '')
            Write-Log -Message "Found $($App.DisplayName) $($App.DisplayVersion) and a valid uninstall string, now attempting to uninstall."       
            Execute-ProcessAsUser -Path "$exeMsiexec" -Parameters "/x $GUID REBOOT=ReallySuppress /qn /L*v C:\Windows\Logs\Software\Python_Tcl_Tk_Support_64bit-Uninstall.log" -Wait
            Start-Sleep -Seconds 5
        }
    }

    ## Uninstall Any Existing Versions of Python 3.12 Utility Scripts
    Remove-MSIApplications -Name 'Python 3.12' -FilterApplication (, ('DisplayName', 'Utility Scripts', 'Contains'))

    $AppList = Get-InstalledApplication -Name 'Python 3.12*Utility Scripts*' -WildCard    
    ForEach ($App in $AppList) {
        If ($App.UninstallString) {
            $GUID = $($App.UninstallString).Replace('MsiExec.exe /I', '').Replace('MsiExec.exe /X', '')
            Write-Log -Message "Found $($App.DisplayName) $($App.DisplayVersion) and a valid uninstall string, now attempting to uninstall."       
            Execute-ProcessAsUser -Path "$exeMsiexec" -Parameters "/x $GUID REBOOT=ReallySuppress /qn /L*v C:\Windows\Logs\Software\Python_Utility_Scripts-Uninstall.log" -Wait
            Start-Sleep -Seconds 5
        }
    }

    ## Uninstall Any Existing Versions of Python 3.12 Documentation
    Remove-MSIApplications -Name 'Python 3.12' -FilterApplication (, ('DisplayName', 'Documentation', 'Contains'))

    $AppList = Get-InstalledApplication -Name 'Python 3.12*Documentation*' -WildCard    
    ForEach ($App in $AppList) {
        If ($App.UninstallString) {
            $GUID = $($App.UninstallString).Replace('MsiExec.exe /I', '').Replace('MsiExec.exe /X', '')
            Write-Log -Message "Found $($App.DisplayName) $($App.DisplayVersion) and a valid uninstall string, now attempting to uninstall."       
            Execute-ProcessAsUser -Path "$exeMsiexec" -Parameters "/x $GUID REBOOT=ReallySuppress /qn /L*v C:\Windows\Logs\Software\Python_Documentation-Uninstall.log" -Wait
            Start-Sleep -Seconds 5
        }
    }

    ## Uninstall Any Existing Versions of Python 3.12 Test Suite (32-bit debug)
    Remove-MSIApplications -Name 'Python 3.12' -FilterApplication (, ('DisplayName', 'Test Suite (32-bit debug)', 'Contains'))

    $AppList = Get-InstalledApplication -Name 'Python 3.12*Test Suite (32-bit debug)' -WildCard    
    ForEach ($App in $AppList) {
        If ($App.UninstallString) {
            $GUID = $($App.UninstallString).Replace('MsiExec.exe /I', '').Replace('MsiExec.exe /X', '')
            Write-Log -Message "Found $($App.DisplayName) $($App.DisplayVersion) and a valid uninstall string, now attempting to uninstall."       
            Execute-ProcessAsUser -Path "$exeMsiexec" -Parameters "/x $GUID REBOOT=ReallySuppress /qn /L*v C:\Windows\Logs\Software\Python_Test_Suite_32bit_debug-Uninstall.log" -Wait
            Start-Sleep -Seconds 5
        }
    }

    ## Uninstall Any Existing Versions of Python 3.12 Test Suite (64-bit debug)
    Remove-MSIApplications -Name 'Python 3.12' -FilterApplication (, ('DisplayName', 'Test Suite (64-bit debug)', 'Contains'))

    $AppList = Get-InstalledApplication -Name 'Python 3.12*Test Suite (64-bit debug)' -WildCard    
    ForEach ($App in $AppList) {
        If ($App.UninstallString) {
            $GUID = $($App.UninstallString).Replace('MsiExec.exe /I', '').Replace('MsiExec.exe /X', '')
            Write-Log -Message "Found $($App.DisplayName) $($App.DisplayVersion) and a valid uninstall string, now attempting to uninstall."       
            Execute-ProcessAsUser -Path "$exeMsiexec" -Parameters "/x $GUID REBOOT=ReallySuppress /qn /L*v C:\Windows\Logs\Software\Python_Test_Suite_64bit_debug-Uninstall.log" -Wait
            Start-Sleep -Seconds 5
        }
    }

    ## Uninstall Any Existing Versions of Python 3.12 Test Suite (32-bit symbols)
    Remove-MSIApplications -Name 'Python 3.12' -FilterApplication (, ('DisplayName', 'Test Suite (32-bit symbols)', 'Contains'))

    $AppList = Get-InstalledApplication -Name 'Python 3.12*Test Suite (32-bit symbols)' -WildCard    
    ForEach ($App in $AppList) {
        If ($App.UninstallString) {
            $GUID = $($App.UninstallString).Replace('MsiExec.exe /I', '').Replace('MsiExec.exe /X', '')
            Write-Log -Message "Found $($App.DisplayName) $($App.DisplayVersion) and a valid uninstall string, now attempting to uninstall."       
            Execute-ProcessAsUser -Path "$exeMsiexec" -Parameters "/x $GUID REBOOT=ReallySuppress /qn /L*v C:\Windows\Logs\Software\Python_Test_Suite_32bit_symbols-Uninstall.log" -Wait
            Start-Sleep -Seconds 5
        }
    }

    ## Uninstall Any Existing Versions of Python 3.12 Test Suite (64-bit symbols)
    Remove-MSIApplications -Name 'Python 3.12' -FilterApplication (, ('DisplayName', 'Test Suite (64-bit symbols)', 'Contains'))

    $AppList = Get-InstalledApplication -Name 'Python 3.12*Test Suite (64-bit symbols)' -WildCard    
    ForEach ($App in $AppList) {
        If ($App.UninstallString) {
            $GUID = $($App.UninstallString).Replace('MsiExec.exe /I', '').Replace('MsiExec.exe /X', '')
            Write-Log -Message "Found $($App.DisplayName) $($App.DisplayVersion) and a valid uninstall string, now attempting to uninstall."       
            Execute-ProcessAsUser -Path "$exeMsiexec" -Parameters "/x $GUID REBOOT=ReallySuppress /qn /L*v C:\Windows\Logs\Software\Python_Test_Suite_64bit_symbols-Uninstall.log" -Wait
            Start-Sleep -Seconds 5
        }
    }

    ## Uninstall Any Existing Versions of Python 3.12 Test Suite (32-bit)
    Remove-MSIApplications -Name 'Python 3.12' -FilterApplication (, ('DisplayName', 'Test Suite (32-bit)', 'Contains'))

    $AppList = Get-InstalledApplication -Name 'Python 3.12*Test Suite (32-bit)' -WildCard    
    ForEach ($App in $AppList) {
        If ($App.UninstallString) {
            $GUID = $($App.UninstallString).Replace('MsiExec.exe /I', '').Replace('MsiExec.exe /X', '')
            Write-Log -Message "Found $($App.DisplayName) $($App.DisplayVersion) and a valid uninstall string, now attempting to uninstall."       
            Execute-ProcessAsUser -Path "$exeMsiexec" -Parameters "/x $GUID REBOOT=ReallySuppress /qn /L*v C:\Windows\Logs\Software\Python_Test_Suite_32bit-Uninstall.log" -Wait
            Start-Sleep -Seconds 5
        }
    }

    ## Uninstall Any Existing Versions of Python 3.12 Test Suite (64-bit)
    Remove-MSIApplications -Name 'Python 3.12' -FilterApplication (, ('DisplayName', 'Test Suite (64-bit)', 'Contains'))

    $AppList = Get-InstalledApplication -Name 'Python 3.12*Test Suite (64-bit)' -WildCard    
    ForEach ($App in $AppList) {
        If ($App.UninstallString) {
            $GUID = $($App.UninstallString).Replace('MsiExec.exe /I', '').Replace('MsiExec.exe /X', '')
            Write-Log -Message "Found $($App.DisplayName) $($App.DisplayVersion) and a valid uninstall string, now attempting to uninstall."       
            Execute-ProcessAsUser -Path "$exeMsiexec" -Parameters "/x $GUID REBOOT=ReallySuppress /qn /L*v C:\Windows\Logs\Software\Python_Test_Suite_64bit-Uninstall.log" -Wait
            Start-Sleep -Seconds 5
        }
    }

    ## Uninstall Any Existing Versions of Python 3.12 Standard Library (32-bit debug)
    Remove-MSIApplications -Name 'Python 3.12' -FilterApplication (, ('DisplayName', 'Standard Library (32-bit debug)', 'Contains'))

    $AppList = Get-InstalledApplication -Name 'Python 3.12*Standard Library (32-bit debug)' -WildCard    
    ForEach ($App in $AppList) {
        If ($App.UninstallString) {
            $GUID = $($App.UninstallString).Replace('MsiExec.exe /I', '').Replace('MsiExec.exe /X', '')
            Write-Log -Message "Found $($App.DisplayName) $($App.DisplayVersion) and a valid uninstall string, now attempting to uninstall."       
            Execute-ProcessAsUser -Path "$exeMsiexec" -Parameters "/x $GUID REBOOT=ReallySuppress /qn /L*v C:\Windows\Logs\Software\Python_Standard_Library_32bit_debug-Uninstall.log" -Wait
            Start-Sleep -Seconds 5
        }
    }

    ## Uninstall Any Existing Versions of Python 3.12 Standard Library (64-bit debug)
    Remove-MSIApplications -Name 'Python 3.12' -FilterApplication (, ('DisplayName', 'Standard Library (64-bit debug)', 'Contains'))

    $AppList = Get-InstalledApplication -Name 'Python 3.12*Standard Library (64-bit debug)' -WildCard    
    ForEach ($App in $AppList) {
        If ($App.UninstallString) {
            $GUID = $($App.UninstallString).Replace('MsiExec.exe /I', '').Replace('MsiExec.exe /X', '')
            Write-Log -Message "Found $($App.DisplayName) $($App.DisplayVersion) and a valid uninstall string, now attempting to uninstall."       
            Execute-ProcessAsUser -Path "$exeMsiexec" -Parameters "/x $GUID REBOOT=ReallySuppress /qn /L*v C:\Windows\Logs\Software\Python_Standard_Library_64bit_debug-Uninstall.log" -Wait
            Start-Sleep -Seconds 5
        }
    }

    ## Uninstall Any Existing Versions of Python 3.12 Standard Library (32-bit symbols)
    Remove-MSIApplications -Name 'Python 3.12' -FilterApplication (, ('DisplayName', 'Standard Library (32-bit symbols)', 'Contains'))

    $AppList = Get-InstalledApplication -Name 'Python 3.12*Standard Library (32-bit symbols)' -WildCard    
    ForEach ($App in $AppList) {
        If ($App.UninstallString) {
            $GUID = $($App.UninstallString).Replace('MsiExec.exe /I', '').Replace('MsiExec.exe /X', '')
            Write-Log -Message "Found $($App.DisplayName) $($App.DisplayVersion) and a valid uninstall string, now attempting to uninstall."       
            Execute-ProcessAsUser -Path "$exeMsiexec" -Parameters "/x $GUID REBOOT=ReallySuppress /qn /L*v C:\Windows\Logs\Software\Python_Standard_Library_32bit_symbols-Uninstall.log" -Wait
            Start-Sleep -Seconds 5
        }
    }

    ## Uninstall Any Existing Versions of Python 3.12 Standard Library (64-bit symbols)
    Remove-MSIApplications -Name 'Python 3.12' -FilterApplication (, ('DisplayName', 'Standard Library (64-bit symbols)', 'Contains'))

    $AppList = Get-InstalledApplication -Name 'Python 3.12*Standard Library (64-bit symbols)' -WildCard    
    ForEach ($App in $AppList) {
        If ($App.UninstallString) {
            $GUID = $($App.UninstallString).Replace('MsiExec.exe /I', '').Replace('MsiExec.exe /X', '')
            Write-Log -Message "Found $($App.DisplayName) $($App.DisplayVersion) and a valid uninstall string, now attempting to uninstall."       
            Execute-ProcessAsUser -Path "$exeMsiexec" -Parameters "/x $GUID REBOOT=ReallySuppress /qn /L*v C:\Windows\Logs\Software\Python_Standard_Library_64bit_symbols-Uninstall.log" -Wait
            Start-Sleep -Seconds 5
        }
    }

    ## Uninstall Any Existing Versions of Python 3.12 Standard Library (32-bit)
    Remove-MSIApplications -Name 'Python 3.12' -FilterApplication (, ('DisplayName', 'Standard Library (32-bit)', 'Contains'))

    $AppList = Get-InstalledApplication -Name 'Python 3.12*Standard Library (32-bit)' -WildCard    
    ForEach ($App in $AppList) {
        If ($App.UninstallString) {
            $GUID = $($App.UninstallString).Replace('MsiExec.exe /I', '').Replace('MsiExec.exe /X', '')
            Write-Log -Message "Found $($App.DisplayName) $($App.DisplayVersion) and a valid uninstall string, now attempting to uninstall."       
            Execute-ProcessAsUser -Path "$exeMsiexec" -Parameters "/x $GUID REBOOT=ReallySuppress /qn /L*v C:\Windows\Logs\Software\Python_Standard_Library_32bit-Uninstall.log" -Wait
            Start-Sleep -Seconds 5
        }
    }

    ## Uninstall Any Existing Versions of Python 3.12 Standard Library (64-bit)
    Remove-MSIApplications -Name 'Python 3.12' -FilterApplication (, ('DisplayName', 'Standard Library (64-bit)', 'Contains'))

    $AppList = Get-InstalledApplication -Name 'Python 3.12*Standard Library (64-bit)' -WildCard    
    ForEach ($App in $AppList) {
        If ($App.UninstallString) {
            $GUID = $($App.UninstallString).Replace('MsiExec.exe /I', '').Replace('MsiExec.exe /X', '')
            Write-Log -Message "Found $($App.DisplayName) $($App.DisplayVersion) and a valid uninstall string, now attempting to uninstall."       
            Execute-ProcessAsUser -Path "$exeMsiexec" -Parameters "/x $GUID REBOOT=ReallySuppress /qn /L*v C:\Windows\Logs\Software\Python_Standard_Library_64bit-Uninstall.log" -Wait
            Start-Sleep -Seconds 5
        }
    }

    ## Uninstall Any Existing Versions of Python 3.12 Development Libraries (32-bit debug)
    Remove-MSIApplications -Name 'Python 3.12' -FilterApplication (, ('DisplayName', 'Development Libraries (32-bit debug)', 'Contains'))

    $AppList = Get-InstalledApplication -Name 'Python 3.12*Development Libraries (32-bit debug)' -WildCard    
    ForEach ($App in $AppList) {
        If ($App.UninstallString) {
            $GUID = $($App.UninstallString).Replace('MsiExec.exe /I', '').Replace('MsiExec.exe /X', '')
            Write-Log -Message "Found $($App.DisplayName) $($App.DisplayVersion) and a valid uninstall string, now attempting to uninstall."       
            Execute-ProcessAsUser -Path "$exeMsiexec" -Parameters "/x $GUID REBOOT=ReallySuppress /qn /L*v C:\Windows\Logs\Software\Python_Development_Libraries_32bit_debug-Uninstall.log" -Wait
            Start-Sleep -Seconds 5
        }
    }

    ## Uninstall Any Existing Versions of Python 3.12 Development Libraries (64-bit debug)
    Remove-MSIApplications -Name 'Python 3.12' -FilterApplication (, ('DisplayName', 'Development Libraries (64-bit debug)', 'Contains'))

    $AppList = Get-InstalledApplication -Name 'Python 3.12*Development Libraries (64-bit debug)' -WildCard    
    ForEach ($App in $AppList) {
        If ($App.UninstallString) {
            $GUID = $($App.UninstallString).Replace('MsiExec.exe /I', '').Replace('MsiExec.exe /X', '')
            Write-Log -Message "Found $($App.DisplayName) $($App.DisplayVersion) and a valid uninstall string, now attempting to uninstall."       
            Execute-ProcessAsUser -Path "$exeMsiexec" -Parameters "/x $GUID REBOOT=ReallySuppress /qn /L*v C:\Windows\Logs\Software\Python_Development_Libraries_64bit_debug-Uninstall.log" -Wait
            Start-Sleep -Seconds 5
        }
    }

    ## Uninstall Any Existing Versions of Python 3.12 Development Libraries (32-bit)
    Remove-MSIApplications -Name 'Python 3.12' -FilterApplication (, ('DisplayName', 'Development Libraries (32-bit)', 'Contains'))

    $AppList = Get-InstalledApplication -Name 'Python 3.12*Development Libraries (32-bit)' -WildCard    
    ForEach ($App in $AppList) {
        If ($App.UninstallString) {
            $GUID = $($App.UninstallString).Replace('MsiExec.exe /I', '').Replace('MsiExec.exe /X', '')
            Write-Log -Message "Found $($App.DisplayName) $($App.DisplayVersion) and a valid uninstall string, now attempting to uninstall."       
            Execute-ProcessAsUser -Path "$exeMsiexec" -Parameters "/x $GUID REBOOT=ReallySuppress /qn /L*v C:\Windows\Logs\Software\Python_Development_Libraries_32bit-Uninstall.log" -Wait
            Start-Sleep -Seconds 5
        }
    }

    ## Uninstall Any Existing Versions of Python 3.12 Development Libraries (64-bit)
    Remove-MSIApplications -Name 'Python 3.12' -FilterApplication (, ('DisplayName', 'Development Libraries (64-bit)', 'Contains'))

    $AppList = Get-InstalledApplication -Name 'Python 3.12*Development Libraries (64-bit)' -WildCard    
    ForEach ($App in $AppList) {
        If ($App.UninstallString) {
            $GUID = $($App.UninstallString).Replace('MsiExec.exe /I', '').Replace('MsiExec.exe /X', '')
            Write-Log -Message "Found $($App.DisplayName) $($App.DisplayVersion) and a valid uninstall string, now attempting to uninstall."       
            Execute-ProcessAsUser -Path "$exeMsiexec" -Parameters "/x $GUID REBOOT=ReallySuppress /qn /L*v C:\Windows\Logs\Software\Python_Development_Libraries_64bit-Uninstall.log" -Wait
            Start-Sleep -Seconds 5
        }
    }

    ## Uninstall Any Existing Versions of Python 3.12 Executables (32-bit debug)
    Remove-MSIApplications -Name 'Python 3.12' -FilterApplication (, ('DisplayName', 'Executables (32-bit debug)', 'Contains'))

    $AppList = Get-InstalledApplication -Name 'Python 3.12*Executables (32-bit debug)' -WildCard    
    ForEach ($App in $AppList) {
        If ($App.UninstallString) {
            $GUID = $($App.UninstallString).Replace('MsiExec.exe /I', '').Replace('MsiExec.exe /X', '')
            Write-Log -Message "Found $($App.DisplayName) $($App.DisplayVersion) and a valid uninstall string, now attempting to uninstall."       
            Execute-ProcessAsUser -Path "$exeMsiexec" -Parameters "/x $GUID REBOOT=ReallySuppress /qn /L*v C:\Windows\Logs\Software\Python_Executables_32bit_debug-Uninstall.log" -Wait
            Start-Sleep -Seconds 5
        }
    }

    ## Uninstall Any Existing Versions of Python 3.12 Executables (64-bit debug)
    Remove-MSIApplications -Name 'Python 3.12' -FilterApplication (, ('DisplayName', 'Executables (64-bit debug)', 'Contains'))

    $AppList = Get-InstalledApplication -Name 'Python 3.12*Executables (64-bit debug)' -WildCard    
    ForEach ($App in $AppList) {
        If ($App.UninstallString) {
            $GUID = $($App.UninstallString).Replace('MsiExec.exe /I', '').Replace('MsiExec.exe /X', '')
            Write-Log -Message "Found $($App.DisplayName) $($App.DisplayVersion) and a valid uninstall string, now attempting to uninstall."       
            Execute-ProcessAsUser -Path "$exeMsiexec" -Parameters "/x $GUID REBOOT=ReallySuppress /qn /L*v C:\Windows\Logs\Software\Python_Executables_64bit_debug-Uninstall.log" -Wait
            Start-Sleep -Seconds 5
        }
    }

    ## Uninstall Any Existing Versions of Python 3.12 Executables (32-bit symbols)
    Remove-MSIApplications -Name 'Python 3.12' -FilterApplication (, ('DisplayName', 'Executables (32-bit symbols)', 'Contains'))

    $AppList = Get-InstalledApplication -Name 'Python 3.12*Executables (32-bit symbols)' -WildCard    
    ForEach ($App in $AppList) {
        If ($App.UninstallString) {
            $GUID = $($App.UninstallString).Replace('MsiExec.exe /I', '').Replace('MsiExec.exe /X', '')
            Write-Log -Message "Found $($App.DisplayName) $($App.DisplayVersion) and a valid uninstall string, now attempting to uninstall."       
            Execute-ProcessAsUser -Path "$exeMsiexec" -Parameters "/x $GUID REBOOT=ReallySuppress /qn /L*v C:\Windows\Logs\Software\Python_Executables_32bit_symbols-Uninstall.log" -Wait
            Start-Sleep -Seconds 5
        }
    }

    ## Uninstall Any Existing Versions of Python 3.12 Executables (64-bit symbols)
    Remove-MSIApplications -Name 'Python 3.12' -FilterApplication (, ('DisplayName', 'Executables (64-bit symbols)', 'Contains'))

    $AppList = Get-InstalledApplication -Name 'Python 3.12*Executables (64-bit symbols)' -WildCard    
    ForEach ($App in $AppList) {
        If ($App.UninstallString) {
            $GUID = $($App.UninstallString).Replace('MsiExec.exe /I', '').Replace('MsiExec.exe /X', '')
            Write-Log -Message "Found $($App.DisplayName) $($App.DisplayVersion) and a valid uninstall string, now attempting to uninstall."       
            Execute-ProcessAsUser -Path "$exeMsiexec" -Parameters "/x $GUID REBOOT=ReallySuppress /qn /L*v C:\Windows\Logs\Software\Python_Executables_64bit_symbols-Uninstall.log" -Wait
            Start-Sleep -Seconds 5
        }
    }

    ## Uninstall Any Existing Versions of Python 3.12 Executables (32-bit)
    Remove-MSIApplications -Name 'Python 3.12' -FilterApplication (, ('DisplayName', 'Executables (32-bit)', 'Contains'))

    $AppList = Get-InstalledApplication -Name 'Python 3.12*Executables (32-bit)' -WildCard    
    ForEach ($App in $AppList) {
        If ($App.UninstallString) {
            $GUID = $($App.UninstallString).Replace('MsiExec.exe /I', '').Replace('MsiExec.exe /X', '')
            Write-Log -Message "Found $($App.DisplayName) $($App.DisplayVersion) and a valid uninstall string, now attempting to uninstall."       
            Execute-ProcessAsUser -Path "$exeMsiexec" -Parameters "/x $GUID REBOOT=ReallySuppress /qn /L*v C:\Windows\Logs\Software\Python_Executables_32bit-Uninstall.log" -Wait
            Start-Sleep -Seconds 5
        }
    }

    ## Uninstall Any Existing Versions of Python 3.12 Executables (64-bit)
    Remove-MSIApplications -Name 'Python 3.12' -FilterApplication (, ('DisplayName', 'Executables (64-bit)', 'Contains'))

    $AppList = Get-InstalledApplication -Name 'Python 3.12*Executables (64-bit)' -WildCard    
    ForEach ($App in $AppList) {
        If ($App.UninstallString) {
            $GUID = $($App.UninstallString).Replace('MsiExec.exe /I', '').Replace('MsiExec.exe /X', '')
            Write-Log -Message "Found $($App.DisplayName) $($App.DisplayVersion) and a valid uninstall string, now attempting to uninstall."       
            Execute-ProcessAsUser -Path "$exeMsiexec" -Parameters "/x $GUID REBOOT=ReallySuppress /qn /L*v C:\Windows\Logs\Software\Python_Executables_64bit-Uninstall.log" -Wait
            Start-Sleep -Seconds 5
        }
    }

    ## Uninstall Any Existing Versions of Python 3.12 Core Interpreter (32-bit debug)
    Remove-MSIApplications -Name 'Python 3.12' -FilterApplication (, ('DisplayName', 'Core Interpreter (32-bit debug)', 'Contains'))

    $AppList = Get-InstalledApplication -Name 'Python 3.12*Core Interpreter (32-bit debug)' -WildCard    
    ForEach ($App in $AppList) {
        If ($App.UninstallString) {
            $GUID = $($App.UninstallString).Replace('MsiExec.exe /I', '').Replace('MsiExec.exe /X', '')
            Write-Log -Message "Found $($App.DisplayName) $($App.DisplayVersion) and a valid uninstall string, now attempting to uninstall."       
            Execute-ProcessAsUser -Path "$exeMsiexec" -Parameters "/x $GUID REBOOT=ReallySuppress /qn /L*v C:\Windows\Logs\Software\Python_Executables_32bit_debug-Uninstall.log" -Wait
            Start-Sleep -Seconds 5
        }
    }

    ## Uninstall Any Existing Versions of Python 3.12 Core Interpreter (64-bit debug)
    Remove-MSIApplications -Name 'Python 3.12' -FilterApplication (, ('DisplayName', 'Core Interpreter (64-bit debug)', 'Contains'))

    $AppList = Get-InstalledApplication -Name 'Python 3.12*Core Interpreter (64-bit debug)' -WildCard    
    ForEach ($App in $AppList) {
        If ($App.UninstallString) {
            $GUID = $($App.UninstallString).Replace('MsiExec.exe /I', '').Replace('MsiExec.exe /X', '')
            Write-Log -Message "Found $($App.DisplayName) $($App.DisplayVersion) and a valid uninstall string, now attempting to uninstall."       
            Execute-ProcessAsUser -Path "$exeMsiexec" -Parameters "/x $GUID REBOOT=ReallySuppress /qn /L*v C:\Windows\Logs\Software\Python_Executables_64bit_debug-Uninstall.log" -Wait
            Start-Sleep -Seconds 5
        }
    }

    ## Uninstall Any Existing Versions of Python 3.12 Core Interpreter (32-bit symbols)
    Remove-MSIApplications -Name 'Python 3.12' -FilterApplication (, ('DisplayName', 'Core Interpreter (32-bit symbols)', 'Contains'))

    $AppList = Get-InstalledApplication -Name 'Python 3.12*Core Interpreter (32-bit symbols)' -WildCard    
    ForEach ($App in $AppList) {
        If ($App.UninstallString) {
            $GUID = $($App.UninstallString).Replace('MsiExec.exe /I', '').Replace('MsiExec.exe /X', '')
            Write-Log -Message "Found $($App.DisplayName) $($App.DisplayVersion) and a valid uninstall string, now attempting to uninstall."       
            Execute-ProcessAsUser -Path "$exeMsiexec" -Parameters "/x $GUID REBOOT=ReallySuppress /qn /L*v C:\Windows\Logs\Software\Python_Executables_32bit_symbols-Uninstall.log" -Wait
            Start-Sleep -Seconds 5
        }
    }

    ## Uninstall Any Existing Versions of Python 3.12 Core Interpreter (64-bit symbols)
    Remove-MSIApplications -Name 'Python 3.12' -FilterApplication (, ('DisplayName', 'Core Interpreter (64-bit symbols)', 'Contains'))

    $AppList = Get-InstalledApplication -Name 'Python 3.12*Core Interpreter (64-bit symbols)' -WildCard    
    ForEach ($App in $AppList) {
        If ($App.UninstallString) {
            $GUID = $($App.UninstallString).Replace('MsiExec.exe /I', '').Replace('MsiExec.exe /X', '')
            Write-Log -Message "Found $($App.DisplayName) $($App.DisplayVersion) and a valid uninstall string, now attempting to uninstall."       
            Execute-ProcessAsUser -Path "$exeMsiexec" -Parameters "/x $GUID REBOOT=ReallySuppress /qn /L*v C:\Windows\Logs\Software\Python_Executables_64bit_symbols-Uninstall.log" -Wait
            Start-Sleep -Seconds 5
        }
    }

    ## Uninstall Any Existing Versions of Python 3.12 Core Interpreter (32-bit)
    Remove-MSIApplications -Name 'Python 3.12' -FilterApplication (, ('DisplayName', 'Core Interpreter (32-bit)', 'Contains'))

    $AppList = Get-InstalledApplication -Name 'Python 3.12*Core Interpreter (32-bit)' -WildCard    
    ForEach ($App in $AppList) {
        If ($App.UninstallString) {
            $GUID = $($App.UninstallString).Replace('MsiExec.exe /I', '').Replace('MsiExec.exe /X', '')
            Write-Log -Message "Found $($App.DisplayName) $($App.DisplayVersion) and a valid uninstall string, now attempting to uninstall."       
            Execute-ProcessAsUser -Path "$exeMsiexec" -Parameters "/x $GUID REBOOT=ReallySuppress /qn /L*v C:\Windows\Logs\Software\Python_Executables_32bit-Uninstall.log" -Wait
            Start-Sleep -Seconds 5
        }
    }

    ## Uninstall Any Existing Versions of Python 3.12 Core Interpreter (64-bit)
    Remove-MSIApplications -Name 'Python 3.12' -FilterApplication (, ('DisplayName', 'Core Interpreter (64-bit)', 'Contains'))

    $AppList = Get-InstalledApplication -Name 'Python 3.12*Core Interpreter (64-bit)' -WildCard    
    ForEach ($App in $AppList) {
        If ($App.UninstallString) {
            $GUID = $($App.UninstallString).Replace('MsiExec.exe /I', '').Replace('MsiExec.exe /X', '')
            Write-Log -Message "Found $($App.DisplayName) $($App.DisplayVersion) and a valid uninstall string, now attempting to uninstall."       
            Execute-ProcessAsUser -Path "$exeMsiexec" -Parameters "/x $GUID REBOOT=ReallySuppress /qn /L*v C:\Windows\Logs\Software\Python_Executables_64bit-Uninstall.log" -Wait
            Start-Sleep -Seconds 5
        }
    }

    ## Uninstall Any Existing Versions of Python Launcher
    Remove-MSIApplications -Name 'Python Launcher'

    $AppList = Get-InstalledApplication -Name 'Python Launcher'    
    ForEach ($App in $AppList) {
        If ($App.UninstallString) {
            $GUID = $($App.UninstallString).Replace('MsiExec.exe /I', '').Replace('MsiExec.exe /X', '')
            Write-Log -Message "Found $($App.DisplayName) $($App.DisplayVersion) and a valid uninstall string, now attempting to uninstall."       
            Execute-ProcessAsUser -Path "$exeMsiexec" -Parameters "/x $GUID REBOOT=ReallySuppress /qn /L*v C:\Windows\Logs\Software\Python_Launcher-Uninstall.log" -Wait
            Start-Sleep -Seconds 5
        }
    }

    ## Remove Any Existing Versions of Python 3.12 (User Profile)
    $Users = Get-ChildItem C:\Users
    ForEach ($user in $Users) {

        $PackageCache = "$($user.fullname)\AppData\Local\Package Cache"
        If (Test-Path $PackageCache) {

            $PythonPath = Get-ChildItem -Path "$PackageCache\*" -Include python-3.12*.exe -Recurse -ErrorAction SilentlyContinue
            ForEach ($Python in $PythonPath) {
                Write-Log -Message "Found $($Python.FullName), now attempting to uninstall existing versions of Python Launcher."
                Execute-ProcessAsUser -Path "$Python" -Parameters "/uninstall /quiet /norestart /log C:\Windows\Logs\Software\Python_3.12-Uninstall.log" -Wait
                Start-Sleep -Seconds 5
            }
        }
    }
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
