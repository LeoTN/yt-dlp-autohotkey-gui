param (
    [string]$pSetupType
)
$Host.UI.RawUI.BackgroundColor = "Black"
$Host.UI.RawUI.ForegroundColor = "Green"
$host.UI.RawUI.WindowTitle = "FFmpeg download running..."
Clear-Host
Write-Host "Terminal ready..."

if ($pSetupType -eq "/run-setup" -or $pSetupType -eq "/force-run-setup") {
    Write-Host "Valid parameters found."
}
else {
    Write-Host "Invalid parameter found: [$pSetupType] '/run-setup' or '/force-run-setup' are allowed only."
    Start-Sleep -Seconds 5
    Exit
}

$downloadUrl = "https://www.gyan.dev/ffmpeg/builds/ffmpeg-release-essentials.zip"
$ffmpegArchivePath = Join-Path -Path $PSScriptRoot -ChildPath "ffmpeg-release-essentials.zip"
$registryPath = "HKCU:\SOFTWARE\LeoTN\VideoDownloader"
$registryVariableName = "ffmpegLocation"
$targetDir = $PSScriptRoot
for ($i = 1; $i -le 2; $i++) {
    $targetDir = Split-Path -Path $targetDir -Parent
}
$outputFolder = Join-Path -Path $targetDir -ChildPath "library\FFmpeg"
$extractedDirectory = Join-Path -Path $PSScriptRoot -ChildPath "ffmpeg-release-essentials"

if ($pSetupType -eq "/run-setup") {
    $expectedExeFiles = Get-ChildItem -Path $outputFolder -Recurse -File | Where-Object { $_.Extension -eq ".exe" }

    if ($expectedExeFiles.Count -eq 3) {
        Write-Host "3 FFmpeg files have been found. Use /force-run-setup to re-install them."
        Write-Host "Checking registry for ffmpegLocation variable..."

        try {
            $tmpValue = Get-ItemProperty -Path $registryPath -Name $registryVariableName | Select-Object -ExpandProperty $registryVariableName
            if ($tmpValue -ne $outputFolder + "\ffmpeg.exe") {
                Write-Host "Overwriting registy variable value..."
                Set-ItemProperty -Path $registryPath -Name $registryVariableName -Value $outputFolder"\ffmpeg.exe"
                Write-Host "Added FFmpeg executable path to registry at $registryPath."
            }
            else {
                Write-Host "The specified path is correct."
            }
        }
        catch {
            Write-Host "No existing variable found. Adding ffmpeg path to registry..."
            Set-ItemProperty -Path $registryPath -Name "ffmpegLocation" -Value $outputFolder"\ffmpeg.exe"
            Write-Host "Added FFmpeg executable path to registry at $registryPath."
        }
        Start-Sleep -Seconds 5
        Exit
    }
    else {
        Invoke-WebRequest -Uri $downloadUrl -OutFile $ffmpegArchivePath
    } 
} 
elseif ($pSetupType -eq "/force-run-setup") {
    Remove-Item -Path $outputFolder -Recurse -Force -ErrorAction SilentlyContinue
    Invoke-WebRequest -Uri $downloadUrl -OutFile $ffmpegArchivePath
}

if (Test-Path -Path $ffmpegArchivePath) {
    $host.UI.RawUI.WindowTitle = "Postprocessing FFmpeg files..."
    Write-Host "FFmpeg was downloaded successfully. Starting further processing...."

    Remove-Item -Path $extractedDirectory -Recurse -Force -ErrorAction SilentlyContinue
    Expand-Archive -Path $ffmpegArchivePath -DestinationPath $extractedDirectory -Force

    $exeFiles = Get-ChildItem -Path $extractedDirectory -Recurse -File | Where-Object { $_.Extension -eq ".exe" }

    New-Item -Path $outputFolder -ItemType Directory -ErrorAction SilentlyContinue | Out-Null

    $exeFiles | ForEach-Object {
        Copy-Item -Path $_.FullName -Destination $outputFolder -Force -Recurse
    }

    Remove-Item -Path $ffmpegArchivePath -Force -Recurse
    Remove-Item -Path $extractedDirectory -Force -Recurse

    Write-Host "Extracted executables to $outputFolder."
    Set-ItemProperty -Path $registryPath -Name $registryVariableName -Value $outputFolder"\ffmpeg.exe"
    Write-Host "Added FFmpeg executable path to registry at $registryPath."
    Start-Sleep -Seconds 5	
    Exit
}
else {
    Write-Host "There was an error while downloading FFmpeg. If this error persists please try to download it manually."
    Start-Sleep -Seconds 5
    Exit
}
