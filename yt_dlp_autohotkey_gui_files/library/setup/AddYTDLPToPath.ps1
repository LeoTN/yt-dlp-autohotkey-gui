$Host.UI.RawUI.BackgroundColor = "Black"
$Host.UI.RawUI.ForegroundColor = "Green"
$host.UI.RawUI.WindowTitle = "Modifying system environment variables..."
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
        $ytDlpDirectory = [System.IO.Path]::GetDirectoryName($ytDlpPath)
        $currentPath = [System.Environment]::GetEnvironmentVariable("Path", [System.EnvironmentVariableTarget]::Machine)

        if ($currentPath -notlike "*$ytDlpDirectory*") {
            $newPath = "$currentPath;$ytDlpDirectory"
            [System.Environment]::SetEnvironmentVariable("Path", $newPath, [System.EnvironmentVariableTarget]::Machine)
            Write-Host "System environment variable 'Path' has been modified successfully"
        }
        else {
            Write-Host "Program yt-dlp seems to already be in the system environment variable 'Path'"
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
