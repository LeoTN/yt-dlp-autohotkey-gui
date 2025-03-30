[CmdletBinding()]
Param (
    # The location of the yt-dlp executable file.
    [Parameter(Mandatory = $true)]
    [String]$pYTDLPExecutableFileLocation,
    # The arguments or parameters for the yt-dlp executable file.
    [Parameter(Mandatory = $true)]
    [String]$pYTDLPCommandString,
    # An optional path to a log file which will contain the stdout of the yt-dlp executable file.
    [Parameter(Mandatory = $false)]
    [String]$pYTDLPLogFileLocation = (Join-Path -Path $env:TEMP -ChildPath "yt-dlp.log")
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

function onInit() {
    $process = Start-Process -FilePath $pYTDLPExecutableFileLocation -ArgumentList $pYTDLPCommandString -RedirectStandardOutput $pYTDLPLogFileLocation -WindowStyle "Hidden" -PassThru -ErrorAction "Continue"
    If ($process.Id -eq $null) {
        # This exit code means that an error has occured.
        $exitCode = 1
    }
    else {
        # This exit code returns the PID of the launched yt-dlp executable process.
        $exitCode = $process.Id
    }
    exitScript -pExitCode $exitCode
}

function exitScript() {
    [CmdletBinding()]
    Param (
        # The exit code that the script will return to it's caller.
        [Parameter(Mandatory = $true)]
        [int]$pExitCode
    )

    $null = Write-Host "[exitScript()] Exiting with exit code [$pExitCode]."
    $null = Stop-Transcript
    Exit $pExitCode
}

onInit