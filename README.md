<div align="center">

# 🎬 vget

**一条命令，下载全网视频 · Download videos from anywhere, instantly**

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Shell](https://img.shields.io/badge/Shell-Bash-green.svg)](vget.sh)
[![Platform](https://img.shields.io/badge/Platform-Linux%20%7C%20macOS%20%7C%20Windows%20WSL%20%7C%20Termux-lightgrey.svg)](#)
[![Powered by yt-dlp](https://img.shields.io/badge/Powered%20by-yt--dlp-red.svg)](https://github.com/yt-dlp/yt-dlp)

[中文说明](#中文说明) · [English Guide](#english-guide) · [常见问题 FAQ](#常见问题--faq)

</div>

---

## 中文说明

### ✨ 这是什么？

**vget** 是一个傻瓜式视频下载脚本。**无需安装任何软件**，只需一个命令，即可下载 YouTube、B站、Twitter、TikTok 等 1000+ 网站的视频。

首次运行时，脚本会自动下载核心组件（[yt-dlp](https://github.com/yt-dlp/yt-dlp)），之后直接使用，无需任何额外配置。

### 🌐 支持的平台（部分）

| 平台 | 支持情况 |
|------|----------|
| 🎥 YouTube | ✅ 完整支持，最高 8K |
| 📺 哔哩哔哩 (B站) | ✅ 支持（大会员内容需 Cookie） |
| 🐦 Twitter / X | ✅ 支持 |
| 🎵 TikTok / 抖音 | ✅ 支持 |
| 📸 Instagram | ✅ 支持 |
| 🎮 Twitch | ✅ 支持 |
| 📻 SoundCloud | ✅ 支持（音频） |
| 🌐 其他 1000+ 网站 | ✅ [查看完整列表](https://github.com/yt-dlp/yt-dlp/blob/master/supportedsites.md) |

### 🖥 系统要求

- **Linux**（Ubuntu / Debian / CentOS 等）
- **macOS**（10.13+）
- **Windows**（通过 WSL 或 Git Bash）
- **Android Termux**

只需系统自带的 `bash` + `curl` 或 `wget`，无需 Python、pip 等环境。

### 🚀 快速开始

**第一步：下载脚本**

```bash
curl -O https://raw.githubusercontent.com/你的用户名/vget/main/vget.sh
```

或者直接克隆仓库：

```bash
git clone https://github.com/你的用户名/vget.git
cd vget
```

**第二步：给予执行权限**

```bash
chmod +x vget.sh
```

**第三步：开始下载！**

```bash
bash vget.sh https://www.youtube.com/watch?v=dQw4w9WgXcQ
```

首次运行会自动下载 `yt-dlp`（约 15MB），之后无需重复。

### 📖 使用示例

```bash
# 下载 YouTube 视频（默认最高画质）
bash vget.sh https://www.youtube.com/watch?v=xxxxx

# 下载 B站视频
bash vget.sh https://www.bilibili.com/video/BVxxxxx

# 下载 Twitter 视频
bash vget.sh https://twitter.com/user/status/xxxxx

# 仅提取音频（保存为 MP3）
bash vget.sh https://www.youtube.com/watch?v=xxxxx --audio

# 指定画质（720p）
bash vget.sh https://www.youtube.com/watch?v=xxxxx --quality 720

# 下载整个播放列表
bash vget.sh https://www.youtube.com/playlist?list=xxxxx --list

# 下载视频 + 字幕
bash vget.sh https://www.youtube.com/watch?v=xxxxx --subtitle

# 指定保存目录
bash vget.sh https://www.youtube.com/watch?v=xxxxx --output ~/视频

# 使用代理（国内用户推荐）
bash vget.sh https://www.youtube.com/watch?v=xxxxx --proxy socks5://127.0.0.1:1080

# 更新核心组件
bash vget.sh --update
```

### ⚙️ 全部参数

| 参数 | 简写 | 说明 | 默认值 |
|------|------|------|--------|
| `--audio` | `-a` | 仅下载音频，保存为 MP3 | 关闭 |
| `--list` | `-l` | 下载整个播放列表 | 关闭 |
| `--quality N` | `-q` | 画质：`best` / `worst` / `720` / `1080` | `best` |
| `--output DIR` | `-o` | 下载保存目录 | `./downloads` |
| `--subtitle` | `-s` | 同时下载字幕（中文优先） | 关闭 |
| `--proxy URL` | `-p` | 使用代理，如 `socks5://127.0.0.1:1080` | 无 |
| `--update` | | 更新 yt-dlp 到最新版本 | — |
| `--help` | `-h` | 显示帮助 | — |
| `--version` | `-v` | 显示版本号 | — |

### 💡 进阶技巧

**安装 ffmpeg 获得最佳画质**

```bash
# Ubuntu / Debian
sudo apt install ffmpeg

# macOS
brew install ffmpeg

# Android Termux
pkg install ffmpeg
```

> 没有 ffmpeg 也能用，但 YouTube 1080p+ 画质需要 ffmpeg 合并音视频流。

**B站大会员视频下载**

1. 在浏览器登录哔哩哔哩
2. 安装浏览器插件导出 `cookies.txt`（推荐 [Get cookies.txt LOCALLY](https://chromewebstore.google.com/detail/get-cookiestxt-locally/cclelndahbckbenkjhflpdbgdldlbecc)）
3. 运行时添加参数：

```bash
bash vget.sh https://www.bilibili.com/video/BVxxxxx --cookies cookies.txt
```

---

## English Guide

### ✨ What is vget?

**vget** is a zero-install video downloader. Run a single command to download videos from YouTube, Bilibili, Twitter, TikTok, and 1000+ other sites — **no Python, no pip, no package manager needed**.

On first run, the script auto-downloads [yt-dlp](https://github.com/yt-dlp/yt-dlp) (~15MB) into a local `bin/` folder. Everything is self-contained.

### 🚀 Quick Start

```bash
# Download the script
curl -O https://raw.githubusercontent.com/YOUR_USERNAME/vget/main/vget.sh
chmod +x vget.sh

# Download a video
bash vget.sh https://www.youtube.com/watch?v=dQw4w9WgXcQ
```

That's it. No installation required.

### 📖 Examples

```bash
# YouTube — best quality
bash vget.sh https://www.youtube.com/watch?v=xxxxx

# Audio only (MP3)
bash vget.sh https://www.youtube.com/watch?v=xxxxx --audio

# Specific resolution
bash vget.sh https://www.youtube.com/watch?v=xxxxx --quality 1080

# Full playlist
bash vget.sh https://www.youtube.com/playlist?list=xxxxx --list

# With subtitles
bash vget.sh https://www.youtube.com/watch?v=xxxxx --subtitle

# Custom output directory
bash vget.sh https://www.youtube.com/watch?v=xxxxx --output ~/Videos

# With proxy
bash vget.sh https://www.youtube.com/watch?v=xxxxx --proxy socks5://127.0.0.1:1080

# Update yt-dlp
bash vget.sh --update
```

### 📋 Requirements

- Bash shell
- `curl` or `wget` (pre-installed on most systems)
- Optional: `ffmpeg` for best quality (1080p+ on YouTube)

Works on: **Linux · macOS · Windows (WSL/Git Bash) · Android (Termux)**

---

## 常见问题 / FAQ

**Q: 下载速度很慢怎么办？/ Download is slow?**

> 国内用户建议使用代理：`bash vget.sh <链接> --proxy socks5://127.0.0.1:1080`
>
> Use a proxy with `--proxy` option for better speeds.

**Q: 提示"下载失败"？/ Download failed?**

> 1. 检查链接是否有效（视频未被删除）
> 2. 尝试更新：`bash vget.sh --update`
> 3. YouTube 限制地区视频需要代理
>
> Check the link is valid, try `--update`, or use a proxy.

**Q: 如何下载 1080p 以上画质？/ How to get 1080p+?**

> 安装 ffmpeg 后脚本会自动启用高画质模式。
>
> Install `ffmpeg` — the script will auto-enable HD merging.

**Q: 脚本安全吗？/ Is this safe?**

> 完全开源，代码可自行审阅。核心下载功能由 [yt-dlp](https://github.com/yt-dlp/yt-dlp)（万星开源项目）提供。
>
> Fully open source. The download engine is [yt-dlp](https://github.com/yt-dlp/yt-dlp), a well-known open source project.

**Q: Windows 用户怎么用？/ How to use on Windows?**

> 推荐安装 [WSL](https://learn.microsoft.com/zh-cn/windows/wsl/install) 或 [Git Bash](https://git-scm.com/downloads)，然后按正常步骤运行。
>
> Install [WSL](https://learn.microsoft.com/en-us/windows/wsl/install) or [Git Bash](https://git-scm.com/downloads), then follow the same steps.

---

## 免责声明 / Disclaimer

本工具仅供个人学习与研究使用。请遵守相关网站的服务条款，尊重版权，勿用于商业用途。

This tool is for personal and educational use only. Please respect the terms of service of each platform and applicable copyright laws.

---

## License

MIT © 2024

---

<div align="center">
如果这个工具对你有帮助，欢迎点个 ⭐ Star！<br>
If this helped you, please give it a ⭐ Star!
</div>
