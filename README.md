# Video Downloader with basic AutoHotkey GUI

A simple AutoHotkey script which acts as a basic GUI to make downloading videos more accessible
for users who do not want to spend time learning every single command line option from the famous downloading script [yt-dlp](https://github.com/yt-dlp/yt-dlp).

**How to install**

> 1. Download the latest installer [here](https://github.com/LeoTN/yt-dlp-autohotkey-gui/releases/latest/download/VideoDownloaderInstaller.zip).
> 2. Extract the folder and execute *VideoDownloader-Setup.exe*.
> 3. Click your way through the prompts.
> 4. Depending on your system and the pre-installed dependencies, the installation (start) may take longer.
> 5. You will be notified once the setup has completed.

**How to use**

> 1. Open the video you wish to download. For example [this](https://www.youtube.com/watch?v=xvFZjo5PgG0) one.
> 2. Press **SHIFT + CTRL + ALT + S** in order to save the URL.
> 3. Alternatively, you can hover over the video thumbnail, for example on the YouTube homepage,
> and press **SHIFT + CTRL + ALT + F** to capture the URL directly.
> 4. Select your preferred downloading options using the **Download Options GUI**
> (Press **SHIFT + CTRL + ALT + A** to open).
> 5. Use the hotkey **SHIFT + CTRL + ALT + D** to start the download process.
> 6. Depending on the settings, the URL file is deleted and a backup is created.

**Features**

- Easy to use and simple to understand.
- Various options provided by yt-dlp are available to fit your needs.
- Archive file to keep track of already downloaded videos.
- Small **Control Panel GUI** (Press **SHIFT + CTRL + ALT + G** to open) for easy access to script functions.
- Many customizable settings in the configuration file, for example changing the script hotkeys, custom paths for files and downloads or personal script launch options.

**Planed features**

- Adding more functionality and options to the script.
- Fixing issues and improve the code.

## Important

> This is my first script using the [PowerShell AppDeploymentToolkit](https://github.com/PSAppDeployToolkit/PSAppDeployToolkit), so expect bugs and errors.  
All the good stuff :)

**NOTE :** The best way of installing this script is the installer archive file included in the [latest release](https://github.com/LeoTN/yt-dlp-autohotkey-gui/releases/latest). You can find all releases [here](https://github.com/LeoTN/yt-dlp-autohotkey-gui/releases).

If you are a developer and would like to use the repository, please note, that parts of this script need to be compiled and components such as Python or FFmpeg may need to be installed first.

Therefore, I recommend cloning the repository first and afterwards executing the **VideDownloader-Setup.exe** file located in the [installer archive](https://github.com/LeoTN/yt-dlp-autohotkey-gui/releases/latest/download/VideoDownloaderInstaller.zip) to install the application. Select the repository folder *yt-dlp-autohotkey-gui* as the installation target folder and you're done.

**I appreciate [yt-dlp](https://github.com/yt-dlp/yt-dlp) for providing such an incredibly useful repository for everyone free to use. Your or rather [these guys](https://github.com/ytdl-org/youtube-dl) work is the reason, why this script can even exist. I would also like to thank the team behind the [FFmpeg](https://ffmpeg.org) software, which is used to provide more functionality for yt-dlp. Shoutout to the guy who made the [Acc library](https://github.com/Descolada/Acc-v2)! Thank you!**

Link to my original project, which will most likely not be developed anymore: [youtube-downloader-using-ahk](https://github.com/LeoTN/youtube-downloader-using-ahk)

## Licence

[MIT License](https://github.com/LeoTN/yt-dlp-autohotkey-gui/blob/main/LICENCE)