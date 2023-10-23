$Host.UI.RawUI.BackgroundColor = "Black"
$Host.UI.RawUI.ForegroundColor = "Green"
Clear-Host
$logfile = $env:temp + "\yt_dlp_download_log.txt"
Write-Host "Terminal ready..."

# Wait for the hook file.
$result = Test-Path $logfile
while (-not($result)) {
    Write-Host "Waiting for hook file..."
    Start-Sleep -Seconds 3
    $result = Test-Path -Path $logfile
}

$currentLineCount = 0

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