$Host.UI.RawUI.BackgroundColor = "Black"
$Host.UI.RawUI.ForegroundColor = "Green"
Clear-Host
Write-Host "Terminal ready..."

$targetSearchFolder = $env:localAppdata + "\Packages"
$pythonSoftwareFoundationFolder = Get-ChildItem -Path $targetSearchFolder -Directory | Where-Object { $_.Name -like "*PythonSoftwareFoundation*" }
foreach ($folder in $pythonSoftwareFoundationFolder) {
    Write-Host "Found Python folder in: ["$folder.FullName"]"
}

function searchAndSetYTDLPPath($folderPath) {
    $ytDlpPath = Join-Path -Path $folderPath -ChildPath "yt-dlp.exe"
    
    if (Test-Path $ytDlpPath -PathType Leaf) {
        [System.Environment]::SetEnvironmentVariable("yt-dlp", $ytDlpPath, [System.EnvironmentVariableTarget]::Machine)
        $tmpValue = [System.Environment]::GetEnvironmentVariable("yt-dlp", [System.EnvironmentVariableTarget]::Machine)

        if ($tmpValue -ne $null) {
            Write-Host "System environment variable 'yt-dlp' has been created successfully"
        }
        else {
            Write-Host "Failed to create system environment variable 'yt-dlp'"
        }
        Start-Sleep -Seconds 5
        Exit
    }
    else {
        $subFolders = Get-ChildItem -Path $folderPath -Directory
        foreach ($subFolder in $subFolders) {
            searchAndSetYTDLPPath $subFolder.FullName
        }
    }
}

foreach ($folder in $pythonSoftwareFoundationFolder) {
    searchAndSetYTDLPPath $folder.FullName
}