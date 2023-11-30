$Host.UI.RawUI.BackgroundColor = "Black"
$Host.UI.RawUI.ForegroundColor = "Green"
$host.UI.RawUI.WindowTitle = "Download is running..."
Clear-Host
$logfile = $env:temp + "\yt_dlp_download_log.txt"
Write-Host "Terminal ready..."

$result = Test-Path $logfile
while (-not($result)) {
    Write-Host "Waiting for hook file..."
    Start-Sleep -Seconds 3
    $result = Test-Path -Path $logfile
}

$currentLineCount = 0

While ($true) {
    $content = Get-Content -Path $logfile
    $newLineCount = $content.Count

    If ($newLineCount -gt $currentLineCount) {
        $newLines = $content[$currentLineCount..($newLineCount - 1)]
        Foreach ($line in $newLines) {
            If ($line -ne "") {
                Write-Host $line
            }
        }
        $currentLineCount = $newLineCount
    }
    Else {
        Start-Sleep -Seconds 0.1
    }
}