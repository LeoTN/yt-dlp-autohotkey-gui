**********IMPORTANT**********

At the very first launch of the VideoDownloader-Setup.exe you might encounter the following:

1. Very long loading time. -> This is because it installs and configures components for a successful installation process.
2. You are asked to download / activate windows features e.g. ".NET". -> If this happens I recommend restarting the system to avoid problems while installing.
3. Nothing happens at all. -> If that's the case you can try the following:

Run the Windows PowerShell as administrator. Change the directory to the folder which contains the "Deploy-Application.ps1" file.
In PowerShell you can do this by typing 'cd "DIRECTORY_PATH_HERE"'. Then type 'powershell.exe -executionPolicy bypass -file ".\Deploy-Application.ps1"'.
If you don't want the window to close immediately (for example to collect debug information) simply add the parameter "-noExit".
The installation should start now prompting for input. If nothing happens, even after waiting a few minutes,
please report the issue here: (https://github.com/LeoTN/yt-dlp-autohotkey-gui/issues).


**********GOOD TO KNOW**********
In case you are having trouble installing the application correctly:

1. VideoDownloader could not be installed -> Please make sure there is no other version of this program installed on the system.
2. Python could not be installed -> You can download and install it yourself here (https://www.python.org/downloads) or install it using the Microsoft Store. Just make sure to pick a version above 3.12.0.
3. yt-dlp won't install correctly -> Search for "cmd" in the windows search bar and open it. Type "pip install yt-dlp". This only works with an installed instance of python 3.12.0 or higher. Administrator rights might be required.

You can report bugs and suggest features here: (https://github.com/LeoTN/yt-dlp-autohotkey-gui/issues).