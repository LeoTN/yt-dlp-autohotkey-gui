[CmdletBinding()]
Param (
    # The location of the yt-dlp executable file
    [Parameter(Mandatory = $true)]
    [String]$pYTDLPExecutableFileLocation,
    # The arguments or parameters for the yt-dlp executable file
    [Parameter(Mandatory = $true)]
    [String]$pYTDLPCommandString,
    # An optional path to a log file which will contain the stdout of the yt-dlp executable file
    [Parameter(Mandatory = $false)]
    [String]$pYTDLPLogFileLocation = (Join-Path -Path $env:TEMP -ChildPath "yt-dlp.log"),
    # An optional path to a log file which will contain the error stdout of the yt-dlp executable file
    [Parameter(Mandatory = $false)]
    [String]$pYTDLPErrorLogFileLocation = (Join-Path -Path $env:TEMP -ChildPath "yt-dlp_errors.log")
)

$Host.UI.RawUI.BackgroundColor = "Black"
$Host.UI.RawUI.ForegroundColor = "White"
$Host.UI.RawUI.WindowTitle = "VideoDownloader - Run yt-dlp Executable"
$scriptParentDirectory = Split-Path -Parent $MyInvocation.MyCommand.Path
$logFileName = "runYTDLPExecutableWithRedirectedStdout.log"
$logFilePath = Join-Path -Path $scriptParentDirectory -ChildPath $logFileName
$null = Start-Transcript -Path $logFilePath -Force
$null = Clear-Host
$null = Write-Host "Terminal ready..."

# --- Helper functions ---
function Exit-Script() {
    [CmdletBinding()]
    Param (
        # The exit code that the script will return to its caller
        [Parameter(Mandatory = $true)]
        [int]$pExitCode
    )

    $null = Write-Host "[INFO] Exiting with exit code '$pExitCode'."
    $null = Stop-Transcript
    Exit $pExitCode
}

# --- Main code ---
$process = Start-Process -FilePath $pYTDLPExecutableFileLocation -ArgumentList $pYTDLPCommandString -RedirectStandardOutput $pYTDLPLogFileLocation -RedirectStandardError $pYTDLPErrorLogFileLocation -WindowStyle "Hidden" -PassThru -ErrorAction "Continue"
If ([String]::IsNullOrEmpty($process.Id)) {
    # This exit code means that an error has occurred
    $exitCode = 1
}
else {
    # This exit code returns the PID of the launched yt-dlp executable process
    $exitCode = $process.Id
}
Exit-Script -pExitCode $exitCode