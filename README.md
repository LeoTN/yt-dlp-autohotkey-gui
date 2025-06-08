# **Video Downloader with basic AutoHotkey GUI**

<p align="left">
        <a href="https://github.com/LeoTN/yt-dlp-autohotkey-gui/releases/latest" style="text-decoration: none;"><img src="https://img.shields.io/github/v/release/LeoTN/yt-dlp-autohotkey-gui?sort=semver&display_name=release&style=for-the-badge&logo=Rocket&logoColor=green&label=CLICK%20TO%20INSTALL%20LATEST%20VERSION&color=green"></a>
        <br>
        <a href="https://github.com/LeoTN/yt-dlp-autohotkey-gui/releases" style="text-decoration: none;"><img src="https://img.shields.io/github/v/release/LeoTN/yt-dlp-autohotkey-gui?include_prereleases&sort=semver&filter=*-beta&display_name=release&style=for-the-badge&logo=Textpattern&logoColor=orange&label=LATEST%20BETA%20VERSION&color=orange"></a>
        <br>
        <a href="https://github.com/LeoTN/yt-dlp-autohotkey-gui/blob/main/LICENSE" style="text-decoration: none;"><img src="https://img.shields.io/github/license/LeoTN/yt-dlp-autohotkey-gui?style=for-the-badge&logo=Google%20Docs&logoColor=blue&label=License&color=blue"></a>
</p>

**Add videos** to the list, **select** your **download preferences** and **start downloading**. No yt-dlp command knowledge required.

<div style="display: inline-block; text-align: center; margin-right: 10px;">
  <img src="library/assets/icons/video_list_gui_readme.png" alt="Main GUI" style="width: 100%;">
</div>

## 🚀 Getting Started

<div style="border-left: 4px solid #97ca00; padding: 16px; border-radius: 6px;">
<ol>
  <li>Download and install the latest installer <strong><a href="https://github.com/LeoTN/yt-dlp-autohotkey-gui/releases/latest">here</a></strong>.</li>
  <li>Open the <a href="https://www.youtube.com/watch?v=xvFZjo5PgG0">video</a> you want to download in your browser.</li>
  <li>Press <strong><code>SHIFT + CTRL + ALT + S</code></strong> to save the URL.</li>
  <li>Alternatively, you can copy the URL and enter it into the video list manually.</li>
  <li>Press <strong><code>SHIFT + CTRL + ALT + D</code></strong> to start the download.</li>
</ol>
</div>

<br>

> [!Tip]
> You may download the [source code](https://github.com/LeoTN/yt-dlp-autohotkey-gui/archive/refs/heads/main.zip) and **run** or **compile** the file "*VideoDownloader.ahk*" yourself.

## Additional Information

<table>
  <thead>
    <tr>
      <th>Feature</th>
      <th>Description</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td>⌨️ <strong>Hotkey Control</strong></td>
      <td>Convenient <strong>hotkey control</strong> for all <strong>core functions</strong></td>
    </tr>
    <tr>
      <td>💡 <strong>Help Window</strong></td>
      <td>Provides additional <strong>information</strong> and <strong>interactive tutorials</strong></td>
    </tr>
    <tr>
      <td>⚙️ <strong>Settings Window</strong></td>
      <td>Configure your default (download) preferences</td>
    </tr>
    <tr>
      <td>🎬 <strong>Video List Window</strong></td>
      <td>Easily manage and download videos</td>
    </tr>
    <tr>
      <td>🌐 <strong>Direct URL Capture</strong></td>
      <td>Capture a <strong>video URL</strong> while the video is <strong>open</strong> in your <strong>browser</strong></td>
    </tr>
    <tr>
      <td>🖱️ <strong>Indirect URL Capture</strong></td>
      <td>Capture a <strong>video URL</strong> by <strong>hovering</strong> over the <strong>video thumbnail</strong> (e.g. on YouTube) and pressing <em><strong>SHIFT + CTRL + ALT + F</strong></em></td>
    </tr>
  </tbody>
</table>

### Known Issues

* The hotkey to indirectly capture video URLs is still **experimental** and won't work every time.
* Embedding **video subtitles** might not work sometimes.
* Sometimes yt-dlp's requests will be **blocked by YouTube**. This causes some videos to appear as **not found** in the video list.
  * If this is the case, I recommend waiting a little before trying again.

> [!Important]
> If your YouTube requests are blocked frequently, you should wait a moment to avoid a temporary IP block

## Credits & License

* **yt-dlp** (<https://github.com/yt-dlp/yt-dlp>) → incredibly useful piece of software
* **FFmpeg** (<https://ffmpeg.org>) → additional functionality for yt-dlp
* **Acc library** (<https://github.com/Descolada/Acc-v2>) → important functions regarding direct URL capture
* **ColorButton library** (<https://github.com/nperovic/ColorButton.ahk>) → colored button functionality

I appreciate your **constructive** and **honest** feedback. Feel free to create an **issue** or **feature** request.

*This repository is licensed under the [MIT License](https://github.com/LeoTN/yt-dlp-autohotkey-gui/blob/main/LICENSE).*