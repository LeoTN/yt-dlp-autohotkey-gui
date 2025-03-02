$Host.UI.RawUI.BackgroundColor = "Black"
$Host.UI.RawUI.ForegroundColor = "White"
$host.UI.RawUI.WindowTitle = "Download is running..."
Clear-Host
$logfile = $env:temp + "\yt_dlp_download_log.txt"
Write-Host "Terminal ready..."

while (-not (Test-Path -Path $logfile)) {
    Write-Host "Waiting for hook file..."
    Start-Sleep -Seconds 3
}

$currentLineCount = 0
Get-Content -Path $logfile -Wait | ForEach-Object {
    $newLineCount = (Get-Content -Path $logfile).Count

    if ($newLineCount -gt $currentLineCount) {
        $newLines = Get-Content -Path $logfile | Select-Object -Skip $currentLineCount
        $newLines | ForEach-Object {
            if ($_ -ne "") {
                Write-Host $_
            }
        }
        $currentLineCount = $newLineCount
    }
}