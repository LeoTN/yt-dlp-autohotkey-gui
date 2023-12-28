**********IMPORTANT**********

At the very first launch of the VideoDownloader-Setup.exe you might encounter the following:

1. Very long loading time. -> This is because it installs and configures components for a successful installation process.
2. You are asked to download / activate windows features e.g. ".NET". -> If this happens I recommend restarting the system to avoid problems while installing.
3. Nothing happens at all. -> If that's the case you can try the following:

Run the Windows PowerShell as administrator. Change the directory to the directory which contains the "Deploy-Application.ps1" file.
In PowerShell you can do this by typing 'cd "DIRECTORY_PATH_HERE"'. Then type 'powershell.exe -executionPolicy bypass -file ".\Deploy-Application.ps1"'.
If you don't want the window to close immediately (for example to collect debug information) simply add the parameter "-noExit".
The installation should start now prompting for input. If nothing happens, even after waiting a few minutes,
please report the issue here: (https://github.com/LeoTN/yt-dlp-autohotkey-gui/issues).