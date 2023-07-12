$Host.UI.RawUI.BackgroundColor = "Black"
$Host.UI.RawUI.ForegroundColor = "Green"
Clear-Host
$logfile = $env:temp + "\yt_dlp_download_log.txt"

# Creates an infinite loop to display the text file content.
while ($true) {
    Clear-Host
    Get-Content -Path $logfile -Wait
}