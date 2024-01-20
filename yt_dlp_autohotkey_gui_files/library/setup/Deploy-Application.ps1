<#
.SYNOPSIS

PSApppDeployToolkit - This script performs the installation or uninstallation of an application(s).

.DESCRIPTION

- The script is provided as a template to perform an install or uninstall of an application(s).
- The script either performs an "Install" deployment type or an "Uninstall" deployment type.
- The install deployment type is broken down into 3 main sections/phases: Pre-Install, Install, and Post-Install.

The script dot-sources the AppDeployToolkitMain.ps1 script which contains the logic and functions required to install or uninstall an application.

PSApppDeployToolkit is licensed under the GNU LGPLv3 License - (C) 2023 PSAppDeployToolkit Team (Sean Lillis, Dan Cunningham and Muhammad Mashwani).

This program is free software: you can redistribute it and/or modify it under the terms of the GNU Lesser General Public License as published by the
Free Software Foundation, either version 3 of the License, or any later version. This program is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License
for more details. You should have received a copy of the GNU Lesser General Public License along with this program. If not, see <http://www.gnu.org/licenses/>.

.PARAMETER DeploymentType

The type of deployment to perform. Default is: Install.

.PARAMETER DeployMode

Specifies whether the installation should be run in Interactive, Silent, or NonInteractive mode. Default is: Interactive. Options: Interactive = Shows dialogs, Silent = No dialogs, NonInteractive = Very silent, i.e. no blocking apps. NonInteractive mode is automatically set if it is detected that the process is not user interactive.

.PARAMETER AllowRebootPassThru

Allows the 3010 return code (requires restart) to be passed back to the parent process (e.g. SCCM) if detected from an installation. If 3010 is passed back to SCCM, a reboot prompt will be triggered.

.PARAMETER TerminalServerMode

Changes to "user install mode" and back to "user execute mode" for installing/uninstalling applications for Remote Desktop Session Hosts/Citrix servers.

.PARAMETER DisableLogging

Disables logging to file for the script. Default is: $false.

.EXAMPLE

powershell.exe -Command "& { & '.\Deploy-Application.ps1' -DeployMode 'Silent'; Exit $LastExitCode }"

.EXAMPLE

powershell.exe -Command "& { & '.\Deploy-Application.ps1' -AllowRebootPassThru; Exit $LastExitCode }"

.EXAMPLE

powershell.exe -Command "& { & '.\Deploy-Application.ps1' -DeploymentType 'Uninstall'; Exit $LastExitCode }"

.EXAMPLE

Deploy-Application.exe -DeploymentType "Install" -DeployMode "Silent"

.INPUTS

None

You cannot pipe objects to this script.

.OUTPUTS

None

This script does not generate any output.

.NOTES

Toolkit Exit Code Ranges:
- 60000 - 68999: Reserved for built-in exit codes in Deploy-Application.ps1, Deploy-Application.exe, and AppDeployToolkitMain.ps1
- 69000 - 69999: Recommended for user customized exit codes in Deploy-Application.ps1
- 70000 - 79999: Recommended for user customized exit codes in AppDeployToolkitExtensions.ps1

.LINK

https://psappdeploytoolkit.com
#>


[CmdletBinding()] # Manual change!
Param (
    [Parameter(Mandatory = $false)]
    [ValidateSet('Install', 'Uninstall', 'Repair')]
    [String]$DeploymentType = 'deployment_type_not_set',
    [Parameter(Mandatory = $false)]
    [ValidateSet($true, $false)]
    $booleanRunSetupActionsQuiet = 'quiet_setup_not_set',
    [Parameter(Mandatory = $false)]
    [ValidateSet('Interactive', 'Silent', 'NonInteractive')]
    [String]$DeployMode = 'Interactive',
    [Parameter(Mandatory = $false)]
    [switch]$AllowRebootPassThru = $false,
    [Parameter(Mandatory = $false)]
    [switch]$TerminalServerMode = $false,
    [Parameter(Mandatory = $false)]
    [switch]$DisableLogging = $false
)

Try {
    ## Set the script execution policy for this process
    Try {
        Set-ExecutionPolicy -ExecutionPolicy 'ByPass' -Scope 'Process' -Force -ErrorAction 'Stop'
    }
    Catch {
    }

    ##*===============================================
    ##* VARIABLE DECLARATION
    ##*===============================================
    ## Variables: Application
    ## CHANGE THESE VALUES WITH CARE! They are used within the script for various reasons.
    [string]$appVendor = 'LeoTN'
    [string]$appName = 'VideoDownloader'
    [string]$appVersion = ''
    [string]$appArch = ''
    [string]$appLang = 'EN'
    [string]$appRevision = ''
    [string]$appScriptVersion = '1.0.0'
    [string]$appScriptDate = '22/12/2023'
    [string]$appScriptAuthor = 'LeoTN / PowerShellAppDeploymentToolkit'
    ##*===============================================
    ## Variables: Install Titles (Only set here to override defaults set by the toolkit)
    [string]$installName = ''
    [string]$installTitle = 'VideoDownloader'

    ##* Do not modify section below
    #region DoNotModify

    ## Variables: Exit Code
    [Int32]$mainExitCode = 0

    ## Variables: Script
    [String]$deployAppScriptFriendlyName = 'Deploy Application'
    [Version]$deployAppScriptVersion = [Version]'3.9.3'
    [String]$deployAppScriptDate = '02/05/2023'
    [Hashtable]$deployAppScriptParameters = $PsBoundParameters

    ## Variables: Environment
    If (Test-Path -LiteralPath 'variable:HostInvocation') {
        $InvocationInfo = $HostInvocation
    }
    Else {
        $InvocationInfo = $MyInvocation
    }
    [String]$scriptDirectory = Split-Path -Path $InvocationInfo.MyCommand.Definition -Parent

    ## Dot source the required App Deploy Toolkit Functions
    Try {
        [String]$moduleAppDeployToolkitMain = "$scriptDirectory\AppDeployToolkit\AppDeployToolkitMain.ps1"
        If (-not (Test-Path -LiteralPath $moduleAppDeployToolkitMain -PathType 'Leaf')) {
            Throw "Module does not exist at the specified location [$moduleAppDeployToolkitMain]."
        }
        If ($DisableLogging) {
            . $moduleAppDeployToolkitMain -DisableLogging
        }
        Else {
            . $moduleAppDeployToolkitMain
        }
    }
    Catch {
        If ($mainExitCode -eq 0) {
            [Int32]$mainExitCode = 60008
        }
        Write-Error -Message "Module [$moduleAppDeployToolkitMain] failed to load: `n$($_.Exception.Message)`n `n$($_.InvocationInfo.PositionMessage)" -ErrorAction 'Continue'
        ## Exit the script, returning the exit code to SCCM
        If (Test-Path -LiteralPath 'variable:HostInvocation') {
            $script:ExitCode = $mainExitCode; Exit
        }
        Else {
            Exit $mainExitCode
        }
    }
    #endregion
    ##* Do not modify section above

    ##*===============================================
    ##* SETUP VARIABLES
    ##*===============================================

    # Set the install directories to the default value.
    $videoDownloaderInstallDirectory = "$envProgramFilesX86\$appVendor\$appName"
    $pythonInstallDirectory = "$envLocalAppData\Programs\Python\Python_3.12"
    # Define where the script properties are located.
    $videoDownloaderInstallerLocation = "$dirFiles\VideoDownloaderInstaller.msi"
    $videoDownloaderRegistryDirectory = "HKCU:\SOFTWARE\$appVendor\$appName"
    $ffmpegSetupScriptLocation = "$dirSupportFiles\FFmpegSetup.ps1"
    $ytdlpSetupScriptLocation = "$dirSupportFiles\yt-dlpSetup.ps1"
    # Other important values.
    $pythonRequiredDiskSpace = 200
    $videoDownloaderRequiredDiskSpace = 300
    # Used for the message at the end.
    $booleanSetupErrorOccurred = $false

    If (-not (Test-Path -Path $videoDownloaderInstallerLocation)) {
        Write-Log "`n`n`n`n`n[ERROR] Missing VideoDownloaderInstaller.msi at`n[$videoDownloaderInstallerLocation]`n`n`n`n`n"
        # Language support needed.
        $balloonText = "Missing VideoDownloader installer file!"
        Show-BalloonTip -BalloonTipText $balloonText -BalloonTipIcon "Error"
        Exit-Script
    }
    If (-not (Test-Path -Path $ffmpegSetupScriptLocation)) {
        Write-Log "`n`n`n`n`n[ERROR] Missing FFmpegSetup.ps1 at`n[$ffmpegSetupScriptLocation]`n`n`n`n`n"
        # Language support needed.
        $balloonText = "Missing FFmpeg setup file!"
        Show-BalloonTip -BalloonTipText $balloonText -BalloonTipIcon "Error"
        Exit-Script
    }
    If (-not (Test-Path -Path $ytdlpSetupScriptLocation)) {
        Write-Log "`n`n`n`n`n[ERROR] Missing yt-dlpSetup.ps1 at`n[$ytdlpSetupScriptLocation]`n`n`n`n`n"
        # Language support needed.
        $balloonText = "Missing yt-dlp setup file!"
        Show-BalloonTip -BalloonTipText $balloonText -BalloonTipIcon "Error"
        Exit-Script
    }
    
    ##*===============================================
    ##* END VARIABLE DECLARATION
    ##*===============================================

    ##*===============================================
    ##* NO SETUP VISIBILITY GIVEN SECTION
    ##*===============================================

    If ($booleanRunSetupActionsQuiet -eq 'quiet_setup_not_set') {
        # Language support needed.
        $selectQuietBooleanButtonOption_1 = "Yes"
        $selectQuietBooleanButtonOption_2 = "Cancel"
        $selectQuietBooleanButtonOption_3 = "No"
        $result = Show-InstallationPrompt -Title "Select Setup Visibility" -Message "Would you like to enable the quiet setup?`nThis will hide most setup windows and notifications." -ButtonLeftText $selectQuietBooleanButtonOption_1 -ButtonMiddleText $selectQuietBooleanButtonOption_2 -ButtonRightText $selectQuietBooleanButtonOption_3
        If ($result -eq $selectQuietBooleanButtonOption_1) {
            $booleanRunSetupActionsQuiet = $true
        }  
        ElseIf ($result -eq $selectQuietBooleanButtonOption_2) {
            $balloonText = "$deploymentTypeName $configBalloonTextAbort"
            Show-BalloonTip -BalloonTipText $balloonText
            Exit-Script
        }
        ElseIf ($result -eq $selectQuietBooleanButtonOption_3) {
            $booleanRunSetupActionsQuiet = $false
        }
    }

    Write-Log "`n`n[INFO] booleanRunSetupActionsQuiet = $booleanRunSetupActionsQuiet`n`n"

    ##*===============================================
    ##* NO SETUP VISIBILITY GIVEN SECTION END
    ##*===============================================

    # Makes sure all possibly affected applications are closed.
    Show-InstallationWelcome -AllowDefer -PersistPrompt -CloseApps 'VideoDownloader,python,python_d,pythonw,pythonw_d'

    ##*===============================================
    ##* NO DEPLOYMENT TYPE GIVEN SECTION
    ##*===============================================

    If ($deploymentType -eq "deployment_type_not_set") {
        $selectDeploymentTypeButtonOption_1 = "Install/Repair"
        $selectDeploymentTypeButtonOption_2 = "Cancel"
        $selectDeploymentTypeButtonOption_3 = "Uninstall"
        $result = Show-InstallationPrompt -Title "Select Setup Option" -Message "Choose a setup option below." -ButtonLeftText $selectDeploymentTypeButtonOption_1 -ButtonMiddleText $selectDeploymentTypeButtonOption_2 -ButtonRightText $selectDeploymentTypeButtonOption_3
        If ($result -eq $selectDeploymentTypeButtonOption_1) {
            # Get the versions.
            $videoDownloaderInstalledObject = Get-InstalledApplication -Name $appName -Exact
            If ($videoDownloaderInstalledObject) {
                # This is a weird work-arround because the method getMSIFileVersion returns a weird object with weird properties.
                $tmp = $videoDownloaderInstalledObject.DisplayVersion
                $tmp = [string]$tmp
                # Remove empty space before version.
                $tmp = $tmp.TrimStart()
                $videoDownloaderInstalledVersion = [version]$tmp

                $tmp = getMSIFileVersion($videoDownloaderInstallerLocation)
                $tmp = [string]$tmp
                # Remove empty space before version.
                $tmp = $tmp.TrimStart()
                # Older versions of VideoDownloader had a single "0" as their version number.
                # This guard makes sure that the string to version convertion below won't throw an error because of this.
                If ($tmp -eq "0") {
                    $tmp = "0.0.0"
                }
                $videoDownloaderInstallerVersion = [version]$tmp

                Write-Log "`n`n`n`n`n`n`n`n`n`n[DEBUG]`nInstalled VideoDownloader Version = $videoDownloaderInstalledVersion`nInstaller VideoDownloader Version = $videoDownloaderInstallerVersion`nTMP = $videoDownloaderInstalledObject `n`n`n`n`n`n`n`n`n`n"

                If ($videoDownloaderInstalledVersion -gt $videoDownloaderInstallerVersion) {
                    $confirmDowngradeButtonOption_1 = "Downgrade to [$videoDownloaderInstallerVersion]?"
                    $confirmDowngradeButtonOption_2 = 'Cancel'
                    $result = Show-InstallationPrompt -Title "Confirm Downgrade" -Message "Found installed VideoDownloader [$videoDownloaderInstalledVersion], which is higher than the current installer [$videoDownloaderInstallerVersion]. Proceed with downgrade?" -ButtonLeftText $confirmDowngradeButtonOption_1 -ButtonRightText $confirmDowngradeButtonOption_2
                    If ($result -eq $confirmDowngradeButtonOption_1) {
                        uninstallVideoDownloader
                        $deploymentType = "Install"
                    }
                    ElseIf ($result -eq $confirmDowngradeButtonOption_2) {
                        # Language support needed.
                        $balloonText = "Downgrade canceled."
                        Show-BalloonTip -BalloonTipText $balloonText
                        Exit-Script
                    }
                }
                ElseIf ($videoDownloaderInstalledVersion -lt $videoDownloaderInstallerVersion) {
                    Show-InstallationProgress -StatusMessage "Found installed VideoDownloader [$videoDownloaderInstalledVersion], which is lower than the current installer [$videoDownloaderInstallerVersion]. Starting update..."
                    Start-Sleep -Seconds 4
                    uninstallVideoDownloader
                    $deploymentType = "Install"
                }
                ElseIf ($videoDownloaderInstalledVersion -eq $videoDownloaderInstallerVersion) {
                    Show-InstallationProgress -StatusMessage "Found installed VideoDownloader [$videoDownloaderInstalledVersion], which is equal to the current installer [$videoDownloaderInstallerVersion]. Starting repair..."
                    $deploymentType = "Repair"
                    Start-Sleep -Seconds 4
                }
            }
        }
        ElseIf ($result -eq $selectDeploymentTypeButtonOption_2) {
            $balloonText = "$deploymentTypeName $configBalloonTextAbort"
            Show-BalloonTip -BalloonTipText $balloonText
            Exit-Script
        }
        ElseIf ($result -eq $selectDeploymentTypeButtonOption_3) {
            # Uninstall the application.
            $deploymentType = "Uninstall"
        }
    }

    ##*===============================================
    ##* NO DEPLOYMENT TYPE GIVEN SECTION END
    ##*===============================================

    ## Check deployment type (install/uninstall)
    Switch ($deploymentType) {
        'Install' {
            $deploymentTypeName = $configDeploymentTypeInstall
        }
        'Uninstall' {
            $deploymentTypeName = $configDeploymentTypeUnInstall
        }
        'Repair' {
            $deploymentTypeName = $configDeploymentTypeRepair
        }
        Default {
            $deploymentTypeName = $configDeploymentTypeInstall
        }
    }
    If ($deploymentTypeName) {
        Write-Log -Message "Deployment type is [$deploymentTypeName]." -Source $appDeployToolkitName
    }

    If ($deploymentType -ine 'Uninstall' -and $deploymentType -ine 'Repair') {
        ##*===============================================
        ##* PRE-INSTALLATION
        ##*===============================================
        [string]$installPhase = 'Pre-Installation'

        ## <Perform Pre-Installation tasks here>
        
        ## Microsoft Intune Win32 App Workaround - Check If Running 32-bit Powershell on 64-bit OS, Restart as 64-bit Process
        If (!([Environment]::Is64BitProcess)) {
            If ([Environment]::Is64BitOperatingSystem) {

                Write-Log "Running 32-bit Powershell on 64-bit OS, Restarting as 64-bit Process..." -Severity 2
                $Arguments = "-NoProfile -ExecutionPolicy ByPass -WindowStyle Hidden -File `"" + $myinvocation.mycommand.definition + "`""
                $Path = (Join-Path $Env:SystemRoot -ChildPath "\sysnative\WindowsPowerShell\v1.0\powershell.exe")

                Start-Process $Path -ArgumentList $Arguments -Wait
                Write-Log "Finished Running x64 version of PowerShell."
                Exit
            }
            Else {
                Write-Log "Running 32-bit Powershell on 32-bit OS."
            }
        }

        $selectInstallPathButtonOption_1 = 'Choose directory'
        $selectInstallPathButtonOption_2 = 'Cancel installation'
        $selectInstallPathButtonOption_3 = 'Use default directory'
        $result = Show-InstallationPrompt -Title 'Change Installation Directory' -Message 'You can change the installation directory if you want.' -ButtonLeftText $selectInstallPathButtonOption_1 -ButtonMiddleText $selectInstallPathButtonOption_2 -ButtonRightText $selectInstallPathButtonOption_3 -Icon 'Information'
        If ($result -eq $selectInstallPathButtonOption_1) {
            $videoDownloaderInstallDirectory = chooseInstallDirectory
        }
        ElseIf ($result -eq $selectInstallPathButtonOption_2) {
            $balloonText = "$deploymentTypeName $configBalloonTextAbort"
            Show-BalloonTip -BalloonTipText $balloonText
            Exit-Script
        }

        # Check if there is enough free disk space for the main application.
        $drive = [io.path]::GetPathRoot($videoDownloaderInstallDirectory).TrimEnd('\')
        $freeDiskSpace = Get-FreeDiskSpace -Drive $drive
        Write-Log "`n`n[CheckMainApplicationDiskSpace] [INFO] Free disk space on [$drive] is $freeDiskSpace MB.`n`n"
        If ($freeDiskSpace -gt $videoDownloaderRequiredDiskSpace) {
            Write-Log "`n`n[CheckMainApplicationDiskSpace] [INFO] Enough free disk space for $appName found.`n`n"
        }
        Else {
            Write-Log "`n`n[CheckMainApplicationDiskSpace] [ERROR] Not enough free disk space for $appName found.`n`n"
            # Language support needed.
            $balloonText = "Not enough disk space for $appName!"
            Show-BalloonTip -BalloonTipText $balloonText
            Exit-Script
        }
        # Check if there is enough free disk space for Python.
        $drive = [io.path]::GetPathRoot($pythonInstallDirectory).TrimEnd('\')
        $freeDiskSpace = Get-FreeDiskSpace -Drive $drive
        Write-Log "`n`n[CheckPythonDiskSpace] [INFO] Free disk space on [$drive] is $freeDiskSpace MB.`n`n"
        If ($freeDiskSpace -gt $pythonRequiredDiskSpace) {
            Write-Log "`n`n[CheckPythonDiskSpace] [INFO] Enough free disk space for Python found.`n`n"
        }
        Else {
            Write-Log "`n`n[CheckPythonDiskSpace] [ERROR] Not enough free disk space for Python found.`n`n"
            # Language support needed.
            $balloonText = "Not enough disk space for Python!"
            Show-BalloonTip -BalloonTipText $balloonText
            Exit-Script
        }

        ##*===============================================
        ##* INSTALLATION
        ##*===============================================
        [string]$installPhase = 'Installation'

        ##*===============================================
        ##* INSTALLATION (VideoDownloader)
        ##*===============================================

        $tmpAppName = "VideoDownloader"
        If (getBooleanReturn(installVideoDownloader -pVideoDownloaderInstallationDirectory $videoDownloaderInstallDirectory -pBooleanQuiet $booleanRunSetupActionsQuiet)) {
            Write-Log "`n`n[INSTALL] [INFO] Installed $tmpAppName successfully.`n`n"
        }
        Else {
            Write-Log "`n`n[INSTALL] [WARNING] Could not install $tmpAppName successfully.`n`n"
            $booleanSetupErrorOccurred = $true
            # Language support needed.
            $balloonText = "Could not install $tmpAppName successfully."
            $balloonTitle = "$tmpAppName Install Status"
            Show-BalloonTip -BalloonTipText $balloonText -BalloonTipTitle $balloonTitle -BalloonTipIcon "Warning"
        }

        ##*===============================================
        ##* INSTALLATION (Python 3.12.0)
        ##*===============================================

        $tmpAppName = "Python"
        If (getBooleanReturn(installPython -pPythonInstallDirectory $pythonInstallDirectory -pBooleanQuiet $booleanRunSetupActionsQuiet)) {
            Write-Log "`n`n[INSTALL] [INFO] Installed $tmpAppName successfully.`n`n"
        }
        Else {
            Write-Log "`n`n[INSTALL] [WARNING] Could not install $tmpAppName successfully.`n`n"
            $booleanSetupErrorOccurred = $true
            # Language support needed.
            $balloonText = "Could not install $tmpAppName successfully."
            $balloonTitle = "$tmpAppName Install Status"
            Show-BalloonTip -BalloonTipText $balloonText -BalloonTipTitle $balloonTitle -BalloonTipIcon "Warning"
        }
        
        ##*===============================================
        ##* INSTALLATION (yt-dlp)
        ##*===============================================

        $tmpAppName = "yt-dlp"
        If (getBooleanReturn(installYTDLP -pPythonInstallationDirectory $pythonInstallDirectory -pBooleanQuiet $booleanRunSetupActionsQuiet)) {
            Write-Log "`n`n[INSTALL] [INFO] Installed $tmpAppName successfully.`n`n"
        }
        Else {
            Write-Log "`n`n[INSTALL] [WARNING] Could not install $tmpAppName successfully.`n`n"
            $booleanSetupErrorOccurred = $true
            # Language support needed.
            $balloonText = "Could not install $tmpAppName successfully."
            $balloonTitle = "$tmpAppName Install Status"
            Show-BalloonTip -BalloonTipText $balloonText -BalloonTipTitle $balloonTitle -BalloonTipIcon "Warning"
        }

        ##*===============================================
        ##* INSTALLATION (FFmpeg library)
        ##*===============================================

        $tmpAppName = "FFmpeg"
        If (getBooleanReturn(installFFmpeg -pVideoDownloaderInstallationDirectory $videoDownloaderInstallDirectory -pBooleanQuiet $booleanRunSetupActionsQuiet)) {
            Write-Log "`n`n[INSTALL] [INFO] Installed $tmpAppName successfully.`n`n"
        }
        Else {
            Write-Log "`n`n[INSTALL] [WARNING] Could not install $tmpAppName successfully.`n`n"
            $booleanSetupErrorOccurred = $true
            # Language support needed.
            $balloonText = "Could not install $tmpAppName successfully."
            $balloonTitle = "$tmpAppName Install Status"
            Show-BalloonTip -BalloonTipText $balloonText -BalloonTipTitle $balloonTitle -BalloonTipIcon "Warning"
        }

        ##*===============================================
        ##* POST-INSTALLATION
        ##*===============================================
        [string]$installPhase = 'Post-Installation'

        ## <Perform Post-Installation tasks here>

        # Disables the forced setup and tells the main script to create any necessary files without prompt.
        Set-RegistryKey -Key $videoDownloaderRegistryDirectory -Name "booleanSetupRequired" -Value 0 -Type "DWord"
        Set-RegistryKey -Key $videoDownloaderRegistryDirectory -Name "booleanFirstTimeLaunch" -Value 1 -Type "Dword"
        Write-Log "`n`n[INFO] Changed registry entries:`n[booleanSetupRequired = 0 and booleanFirstTimeLaunch = 1] at`n[$videoDownloaderRegistryDirectory].`n`n"
        # Language support needed.
        If ($booleanSetupErrorOccurred) {
            Show-InstallationPrompt -Message "$appName installation completed with errors. It is recommended to repair the installation." -ButtonRightText "OK" -Icon "Warning"
        }
        Else {
            Show-InstallationPrompt -Message "$appName installation completed. Have fun with the application :)" -ButtonRightText "OK" -Icon "Information"
        }
    }
    ElseIf ($deploymentType -ieq 'Uninstall') {
        ##*===============================================
        ##* PRE-UNINSTALLATION
        ##*===============================================
        [String]$installPhase = 'Pre-Uninstallation'

        ## <Perform Pre-Uninstallation tasks here>

        ##*===============================================
        ##* UNINSTALLATION
        ##*===============================================
        [String]$installPhase = 'Uninstallation'

        ## <Perform Uninstallation tasks here>

        ##*===============================================
        ##* UNINSTALLATION (FFmpeg library)
        ##*===============================================

        $tmpAppName = "FFmpeg"
        If (getBooleanReturn(uninstallFFmpeg -pVideoDownloaderInstallationDirectory $videoDownloaderInstallDirectory -pBooleanQuiet $booleanRunSetupActionsQuiet)) {
            Write-Log "`n`n[INSTALL] [INFO] Uninstalled $tmpAppName successfully.`n`n"
        }
        Else {
            Write-Log "`n`n[INSTALL] [WARNING] Could not uninstall $tmpAppName successfully.`n`n"
            $booleanSetupErrorOccurred = $true
            # Language support needed.
            $balloonText = "Could not uninstall $tmpAppName successfully."
            $balloonTitle = "$tmpAppName Uninstall Status"
            Show-BalloonTip -BalloonTipText $balloonText -BalloonTipTitle $balloonTitle -BalloonTipIcon "Warning"
        }

        ##*===============================================
        ##* UNINSTALLATION (yt-dlp)
        ##*===============================================

        $tmpAppName = "yt-dlp"
        If (getBooleanReturn(uninstallYTDLP -pPythonInstallationDirectory $pythonInstallDirectory -pBooleanQuiet $booleanRunSetupActionsQuiet)) {
            Write-Log "`n`n[INSTALL] [INFO] Uninstalled $tmpAppName successfully.`n`n"
        }
        Else {
            Write-Log "`n`n[INSTALL] [WARNING] Could not uninstall $tmpAppName successfully.`n`n"
            $booleanSetupErrorOccurred = $true
            # Language support needed.
            $balloonText = "Could not uninstall $tmpAppName successfully."
            $balloonTitle = "$tmpAppName Uninstall Status"
            Show-BalloonTip -BalloonTipText $balloonText -BalloonTipTitle $balloonTitle -BalloonTipIcon "Warning"
        }

        ##*===============================================
        ##* UNINSTALLATION (Python 3.12.0)
        ##*===============================================

        $tmpAppName = "Python"
        If (getBooleanReturn(uninstallPython)) {
            Write-Log "`n`n[INSTALL] [INFO] Uninstalled $tmpAppName successfully.`n`n"
        }
        Else {
            Write-Log "`n`n[INSTALL] [WARNING] Could not uninstall $tmpAppName successfully.`n`n"
            $booleanSetupErrorOccurred = $true
            # Language support needed.
            $balloonText = "Could not uninstall $tmpAppName successfully."
            $balloonTitle = "$tmpAppName Uninstall Status"
            Show-BalloonTip -BalloonTipText $balloonText -BalloonTipTitle $balloonTitle -BalloonTipIcon "Warning"
        }

        ##*===============================================
        ##* UNINSTALLATION (VideoDownloader)
        ##*===============================================

        $tmpAppName = "VideoDownloader"
        If (getBooleanReturn(uninstallVideoDownloader -pBooleanQuiet $booleanRunSetupActionsQuiet)) {
            Write-Log "`n`n[INSTALL] [INFO] Uninstalled $tmpAppName successfully.`n`n"
        }
        Else {
            Write-Log "`n`n[INSTALL] [WARNING] Could not uninstall $tmpAppName successfully.`n`n"
            $booleanSetupErrorOccurred = $true
            # Language support needed.
            $balloonText = "Could not uninstall $tmpAppName successfully."
            $balloonTitle = "$tmpAppName Uninstall Status"
            Show-BalloonTip -BalloonTipText $balloonText -BalloonTipTitle $balloonTitle -BalloonTipIcon "Warning"
        }

        ##*===============================================
        ##* POST-UNINSTALLATION
        ##*===============================================
        [String]$installPhase = 'Post-Uninstallation'

        ## <Perform Post-Uninstallation tasks here>
        # Language support needed.
        If ($booleanSetupErrorOccurred) {
            Show-InstallationPrompt -Message "$appName uninstallation completed with errors. Errors may also occur when components were previously uninstalled." -ButtonRightText "OK" -Icon "Warning"
        }
        Else {
            Show-InstallationPrompt -Message "$appName uninstallation completed. Until next time :')" -ButtonRightText "OK" -Icon "Information"
        }
    }
    ElseIf ($deploymentType -ieq 'Repair') {
        ##*===============================================
        ##* PRE-REPAIR
        ##*===============================================
        [String]$installPhase = 'Pre-Repair'

        ## <Perform Pre-Repair tasks here>

        ##*===============================================
        ##* REPAIR
        ##*===============================================
        [String]$installPhase = 'Repair'

        ## <Perform Repair tasks here>

        ##*===============================================
        ##* REPAIR (VideoDownloader)
        ##*===============================================

        $tmpAppName = "VideoDownloader"
        If (getBooleanReturn(repairVideoDownloader -pBooleanQuiet $booleanRunSetupActionsQuiet)) {
            Write-Log "`n`n[REPAIR] [INFO] Repaired $tmpAppName successfully.`n`n"
        }
        Else {
            Write-Log "`n`n[REPAIR] [WARNING] Could not repair $tmpAppName successfully.`n`n"
            $booleanSetupErrorOccurred = $true
            # Language support needed.
            $balloonText = "Could not repair $tmpAppName successfully."
            $balloonTitle = "$tmpAppName Repair Status"
            Show-BalloonTip -BalloonTipText $balloonText -BalloonTipTitle $balloonTitle -BalloonTipIcon "Warning"
        }

        ##*===============================================
        ##* REPAIR (Python 3.12.0)
        ##*===============================================

        $tmpAppName = "Python"
        If (getBooleanReturn(repairPython -pPythonInstallDirectory $pythonInstallDirectory -pBooleanQuiet $booleanRunSetupActionsQuiet)) {
            Write-Log "`n`n[REPAIR] [INFO] Repaired $tmpAppName successfully.`n`n"
        }
        Else {
            Write-Log "`n`n[REPAIR] [WARNING] Could not repair $tmpAppName successfully.`n`n"
            $booleanSetupErrorOccurred = $true
            # Language support needed.
            $balloonText = "Could not repair $tmpAppName successfully."
            $balloonTitle = "$tmpAppName Repair Status"
            Show-BalloonTip -BalloonTipText $balloonText -BalloonTipTitle $balloonTitle -BalloonTipIcon "Warning"
        }

        ##*===============================================
        ##* REPAIR (yt-dlp)
        ##*===============================================

        $tmpAppName = "yt-dlp"
        If (getBooleanReturn(repairYTDLP -pPythonInstallationDirectory $pythonInstallDirectory -pBooleanQuiet $booleanRunSetupActionsQuiet)) {
            Write-Log "`n`n[REPAIR] [INFO] Repaired $tmpAppName successfully.`n`n"
        }
        Else {
            Write-Log "`n`n[REPAIR] [WARNING] Could not repair $tmpAppName successfully.`n`n"
            $booleanSetupErrorOccurred = $true
            # Language support needed.
            $balloonText = "Could not repair $tmpAppName successfully."
            $balloonTitle = "$tmpAppName Repair Status"
            Show-BalloonTip -BalloonTipText $balloonText -BalloonTipTitle $balloonTitle -BalloonTipIcon "Warning"
        }

        ##*===============================================
        ##* REPAIR (FFmpeg library)
        ##*===============================================

        $tmpAppName = "FFmpeg"
        If (getBooleanReturn(repairFFmpeg -pVideoDownloaderInstallationDirectory $videoDownloaderInstallDirectory -pBooleanQuiet $booleanRunSetupActionsQuiet)) {
            Write-Log "`n`n[REPAIR] [INFO] Repaired $tmpAppName successfully.`n`n"
        }
        Else {
            Write-Log "`n`n[REPAIR] [WARNING] Could not repair $tmpAppName successfully.`n`n"
            $booleanSetupErrorOccurred = $true
            # Language support needed.
            $balloonText = "Could not repair $tmpAppName successfully."
            $balloonTitle = "$tmpAppName Repair Status"
            Show-BalloonTip -BalloonTipText $balloonText -BalloonTipTitle $balloonTitle -BalloonTipIcon "Warning"
        }

        ##*===============================================
        ##* POST-REPAIR
        ##*===============================================
        [String]$installPhase = 'Post-Repair'

        ## <Perform Post-Repair tasks here>

        # Disables the forced setup and tells the main script to create any necessary files without prompt.
        Set-RegistryKey -Key $videoDownloaderRegistryDirectory -Name "booleanSetupRequired" -Value 0 -Type "DWord"
        Set-RegistryKey -Key $videoDownloaderRegistryDirectory -Name "booleanFirstTimeLaunch" -Value 1 -Type "Dword"
        Write-Log "`n`n[INFO] Changed registry entries:`n[booleanSetupRequired = 0 and booleanFirstTimeLaunch = 1] at`n[$videoDownloaderRegistryDirectory].`n`n"
        # Language support needed.
        If ($booleanSetupErrorOccurred) {
            Show-InstallationPrompt -Message "$appName repair completed with errors. It is recommended to repair the installation again. If this error persists, please uninstall and re-install all components or report the issue on the GitHub page." -ButtonRightText "OK" -Icon "Warning"
        }
        Else {
            Show-InstallationPrompt -Message "$appName repair completed. Have fun with the repaired application :D" -ButtonRightText "OK" -Icon "Information"
        }
    }
    ##*===============================================
    ##* END SCRIPT BODY
    ##*===============================================

    ## Call the Exit-Script function to perform final cleanup operations
    Exit-Script -ExitCode $mainExitCode
}
Catch {
    [Int32]$mainExitCode = 60001
    [String]$mainErrorMessage = "$(Resolve-Error)"
    Write-Log -Message $mainErrorMessage -Severity 3 -Source $deployAppScriptFriendlyName
    Show-DialogBox -Text $mainErrorMessage -Icon 'Stop'
    Exit-Script -ExitCode $mainExitCode
}
