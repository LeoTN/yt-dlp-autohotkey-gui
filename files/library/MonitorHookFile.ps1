$Host.UI.RawUI.BackgroundColor = "Black"
$Host.UI.RawUI.ForegroundColor = "Green"
Clear-Host
$logfile = $env:temp + "\yt_dlp_download_log.txt"
Write-Host "Terminal ready..."

$currentLineCount = (Get-Content -Path $logfile).Count

# Creates an infinite loop to display new text file content.
While ($true) {
    $content = Get-Content -Path $logfile
    $newLineCount = $content.Count

    # Checks if new lines have arrived.
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
        # Waits for new lines to arrive.
        Start-Sleep -Seconds 0.1
    }
}