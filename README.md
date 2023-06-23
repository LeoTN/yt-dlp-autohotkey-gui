# Video Downloader with basic Autohotkey GUI

A simple AutoHotkey script which acts as a basic GUI to make downloading videos more accessible 
for users who do not want to spend time learning every single command line option from the famous downloading script :                    
"yt-dlp" (https://github.com/yt-dlp/yt-dlp).                                   
**Note :** This version currently may only work well with Firefox (don't worry, only the URL capture part),
but in the future these capture options will be updated to function with most common browsers.

**User manual**
1. Open the video you wish to download.

2. Press *SHIFT + CTRL + ALT + S* in order to save its URL.

3. Alternatively you may hover over the video thumbnail, for example on the YouTube homepage  
   and press *SHIFT + CTRL + ALT + F* to capture the URL directly.

4. Select your preferred download options in the matching **download option GUI** (Press *SHIFT + CTRL + ALT + A* to open).
5. Use the hotkey *SHIFT + CTRL + ALT + D* to start the download process.  
   Alternatively, you can also use the button in the **download option GUI**.

6. When it has finished, the script will ask you to clear the URL file.

7. Select your preferred option and you are ready to start the process again.

**Features**
- The amount of videos is probably unlimited.
- Various options provided by "yt-dlp" are available to fit your needs.
- Each video will be downloaded once, so don't worry about selecting the same URL twice.
- There is also a practical **main GUI** (Press *SHIFT + CTRL + ALT + G* to open) which will help you navigate the scripts functions.

**Planed features**
- The GUI will receive more additional buttons and options depending on the available options in "yt-dlp".
- Add customisation options and an own GUI for it.

## Important
It is recommended to follow the setup instructions given by the script at first launch and install python and all required components so that the download will happen without complications. There might be more options to install "yt-dlp" other than using the pip command.

**I appreciate yt-dlp (https://github.com/yt-dlp/yt-dlp) for providing such an incredibly useful repository for everyone free to use. Your, or rather these guys (https://github.com/ytdl-org/youtube-dl) work is the reason why this script can even exist. Thank you !**

Link to my original project which will most likely not be developed : https://github.com/LeoTN/youtube-downloader-using-ahk
