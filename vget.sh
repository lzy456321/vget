#!/usr/bin/env bash
# ╔═══════════════════════════════════════════════════════════╗
# ║              vget — 傻瓜式视频下载工具                    ║
# ║         No-install Video Downloader  v2.0.0               ║
# ║   支持 YouTube · B站 · Twitter · TikTok · 1000+ 网站      ║
# ╚═══════════════════════════════════════════════════════════╝
#
# 用法 / Usage:
#   bash vget.sh <视频链接>
#   bash vget.sh <视频链接> [选项]
#
# 示例 / Examples:
#   bash vget.sh https://www.youtube.com/watch?v=xxxxx
#   bash vget.sh https://www.bilibili.com/video/BVxxxxx
#   bash vget.sh https://www.youtube.com/watch?v=xxxxx --audio
#   bash vget.sh https://www.youtube.com/watch?v=xxxxx --list
#   bash vget.sh --history

set -euo pipefail

# ── 版本 ────────────────────────────────────
VERSION="2.0.0"

# ── 颜色 ────────────────────────────────────
RED='\033[0;31m'
GRN='\033[0;32m'
YEL='\033[1;33m'
CYA='\033[0;36m'
BLU='\033[0;34m'
BLD='\033[1m'
DIM='\033[2m'
RST='\033[0m'

# ── 打印函数 ─────────────────────────────────
info()    { echo -e "${CYA}[vget]${RST} $*"; }
success() { echo -e "${GRN}[✓]${RST} $*"; }
warn()    { echo -e "${YEL}[!]${RST} $*"; }
error()   { echo -e "${RED}[✗]${RST} $*" >&2; }
step()    { echo -e "\n${BLD}${BLU}▶ $*${RST}"; }

# ── Banner ───────────────────────────────────
banner() {
  echo -e "${BLD}${CYA}"
  echo "  ╦  ╦╔═╗╔═╗╔╦╗"
  echo "  ╚╗╔╝║ ╦║╣  ║ "
  echo "   ╚╝ ╚═╝╚═╝ ╩ "
  echo -e "${RST}${DIM}  傻瓜式视频下载工具 v${VERSION}${RST}"
  echo -e "${DIM}  支持 YouTube · B站 · Twitter · TikTok · 1000+ 网站${RST}\n"
}

# ── 帮助 ─────────────────────────────────────
usage() {
  banner
  echo -e "${BLD}用法:${RST}"
  echo "  bash vget.sh <视频链接> [选项]"
  echo ""
  echo -e "${BLD}选项:${RST}"
  echo "  --audio         仅下载音频（MP3）"
  echo "  --list          下载整个播放列表"
  echo "  --quality N     指定画质（best/worst/720/1080，默认 best）"
  echo "  --output DIR    指定下载目录（默认 ./downloads）"
  echo "  --subtitle      同时下载字幕"
  echo "  --proxy URL     使用代理（如 socks5://127.0.0.1:1080）"
  echo "  --history       查看下载历史"
  echo "  --clear-history 清空下载历史"
  echo "  --update        更新 yt-dlp 到最新版本"
  echo "  --version       显示版本号"
  echo "  --help          显示此帮助"
  echo ""
  echo -e "${BLD}示例:${RST}"
  echo "  bash vget.sh https://www.youtube.com/watch?v=dQw4w9WgXcQ"
  echo "  bash vget.sh https://www.bilibili.com/video/BV1xx411c7mD"
  echo "  bash vget.sh https://www.youtube.com/watch?v=xxxxx --audio"
  echo "  bash vget.sh https://www.youtube.com/watch?v=xxxxx --quality 1080"
  echo "  bash vget.sh --history"
  echo ""
  exit 0
}

# ── 检测系统 ─────────────────────────────────
detect_os() {
  OS="unknown"
  ARCH=$(uname -m)

  case "$(uname -s)" in
    Linux*)
      OS="linux"
      [[ -d /data/data/com.termux ]] && OS="termux"
      ;;
    Darwin*) OS="macos" ;;
    MINGW*|MSYS*|CYGWIN*) OS="windows" ;;
  esac

  case "$ARCH" in
    x86_64|amd64) ARCH="x86_64" ;;
    aarch64|arm64) ARCH="aarch64" ;;
    armv7*) ARCH="armv7" ;;
  esac

  info "系统: ${OS} / ${ARCH}"
}

# ── 确定路径 ─────────────────────────────────
setup_paths() {
  SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  BIN_DIR="${SCRIPT_DIR}/bin"
  mkdir -p "$BIN_DIR"

  YT_DLP_BIN="${BIN_DIR}/yt-dlp"
  [[ "$OS" == "windows" ]] && YT_DLP_BIN="${BIN_DIR}/yt-dlp.exe"

  # 历史记录文件
  HISTORY_FILE="${SCRIPT_DIR}/.vget_history"
}

# ── 国内镜像下载 yt-dlp ───────────────────────
download_ytdlp() {
  local filename=""
  case "${OS}-${ARCH}" in
    linux-x86_64)  filename="yt-dlp" ;;
    linux-aarch64) filename="yt-dlp_linux_aarch64" ;;
    linux-armv7)   filename="yt-dlp_linux_armv7l" ;;
    termux-*)      filename="yt-dlp" ;;
    macos-*)       filename="yt-dlp_macos" ;;
    windows-*)     filename="yt-dlp.exe" ;;
    *)             filename="yt-dlp" ;;
  esac

  # 下载源列表（国内镜像优先）
  local urls=(
    "https://gh-proxy.com/https://github.com/yt-dlp/yt-dlp/releases/latest/download/${filename}"
    "https://ghfast.top/https://github.com/yt-dlp/yt-dlp/releases/latest/download/${filename}"
    "https://github.com/yt-dlp/yt-dlp/releases/latest/download/${filename}"
  )

  step "首次运行：下载核心组件 yt-dlp..."

  local download_ok=0
  for url in "${urls[@]}"; do
    info "尝试: $url"
    if command -v curl &>/dev/null; then
      if curl -L --progress-bar --retry 2 --connect-timeout 10 \
           -o "$YT_DLP_BIN" "$url" 2>/dev/null; then
        download_ok=1
        break
      fi
    elif command -v wget &>/dev/null; then
      if wget --show-progress -q --tries=2 --timeout=10 \
           -O "$YT_DLP_BIN" "$url" 2>/dev/null; then
        download_ok=1
        break
      fi
    fi
    warn "该源失败，尝试下一个..."
  done

  if [[ $download_ok -eq 0 ]]; then
    error "所有下载源均失败！请手动下载："
    error "  https://github.com/yt-dlp/yt-dlp/releases/latest"
    error "  → 保存到: $YT_DLP_BIN"
    exit 1
  fi

  chmod +x "$YT_DLP_BIN"
  success "yt-dlp 已就绪"
}

# ── 确保 yt-dlp 可用 ─────────────────────────
ensure_ytdlp() {
  if [[ -x "$YT_DLP_BIN" ]]; then
    return 0
  fi
  if command -v yt-dlp &>/dev/null; then
    YT_DLP_BIN=$(command -v yt-dlp)
    info "使用系统 yt-dlp: $YT_DLP_BIN"
    return 0
  fi
  download_ytdlp
}

# ── 检测 ffmpeg ───────────────────────────────
check_ffmpeg() {
  if command -v ffmpeg &>/dev/null; then
    FFMPEG_AVAILABLE=1
    info "ffmpeg 已检测到，支持最高画质"
  else
    FFMPEG_AVAILABLE=0
    warn "未检测到 ffmpeg，画质可能受限"
    case "$OS" in
      linux|termux) warn "  安装: pkg install ffmpeg" ;;
      macos)        warn "  安装: brew install ffmpeg" ;;
    esac
  fi
}

# ── 更新 yt-dlp ───────────────────────────────
update_ytdlp() {
  step "更新 yt-dlp..."
  if [[ -x "$YT_DLP_BIN" ]]; then
    "$YT_DLP_BIN" -U || download_ytdlp
  else
    download_ytdlp
  fi
  success "更新完成"
  exit 0
}

# ── 下载历史 ─────────────────────────────────
save_history() {
  local url="$1" title="$2" time
  time=$(date '+%Y-%m-%d %H:%M:%S')
  echo "${time} | ${url} | ${title}" >> "$HISTORY_FILE"
}

show_history() {
  banner
  if [[ ! -f "$HISTORY_FILE" ]] || [[ ! -s "$HISTORY_FILE" ]]; then
    info "暂无下载历史"
    exit 0
  fi
  echo -e "${BLD}── 下载历史 ──────────────────────────────${RST}"
  local i=1
  while IFS='|' read -r time url title; do
    printf "${DIM}%3d.${RST} ${CYA}%s${RST}\n     %s\n     ${DIM}%s${RST}\n\n" \
      "$i" "${title// /}" "${url// /}" "${time// /}"
    ((i++))
  done < "$HISTORY_FILE"
  exit 0
}

clear_history() {
  > "$HISTORY_FILE"
  success "历史记录已清空"
  exit 0
}

# ── 发送通知 ─────────────────────────────────
send_notification() {
  local title="$1"
  # Termux 通知
  if command -v termux-notification &>/dev/null; then
    termux-notification \
      --title "vget 下载完成 ✓" \
      --content "$title" \
      --sound 2>/dev/null || true
    return
  fi
  # macOS 通知
  if [[ "$OS" == "macos" ]] && command -v osascript &>/dev/null; then
    osascript -e "display notification \"$title\" with title \"vget 下载完成\"" 2>/dev/null || true
    return
  fi
  # Linux notify-send
  if command -v notify-send &>/dev/null; then
    notify-send "vget 下载完成" "$title" 2>/dev/null || true
  fi
}

# ── 自动读取浏览器 Cookie ─────────────────────
detect_cookies() {
  COOKIE_ARGS=()

  # 只对需要登录的网站尝试读取 Cookie
  local need_cookie=0
  [[ "$URL" =~ bilibili\.com ]] && need_cookie=1
  [[ "$URL" =~ youtube\.com ]] && need_cookie=1
  [[ "$URL" =~ instagram\.com ]] && need_cookie=1
  [[ $need_cookie -eq 0 ]] && return

  # 优先用本地 cookies.txt 文件
  if [[ -f "${SCRIPT_DIR}/cookies.txt" ]]; then
    COOKIE_ARGS+=("--cookies" "${SCRIPT_DIR}/cookies.txt")
    info "Cookie: 使用本地 cookies.txt"
    return
  fi

  # 尝试从浏览器自动读取（yt-dlp 支持）
  local browsers=("chrome" "firefox" "edge" "safari")
  for browser in "${browsers[@]}"; do
    if "$YT_DLP_BIN" --cookies-from-browser "$browser" \
       --simulate "$URL" &>/dev/null 2>&1; then
      COOKIE_ARGS+=("--cookies-from-browser" "$browser")
      info "Cookie: 自动读取 ${browser} 浏览器"
      return
    fi
  done

  warn "未找到浏览器 Cookie，部分内容可能无法下载"
  warn "提示：将 cookies.txt 放在脚本同目录可解决此问题"
}

# ── 构建下载参数 ──────────────────────────────
build_args() {
  YTDLP_ARGS=()

  # 输出目录
  YTDLP_ARGS+=("-P" "$OUTPUT_DIR")

  # 文件名模板
  YTDLP_ARGS+=("-o" "%(title)s.%(ext)s")

  # 断点续传
  YTDLP_ARGS+=("--continue")

  # 仅音频模式
  if [[ "$MODE_AUDIO" -eq 1 ]]; then
    YTDLP_ARGS+=("-x" "--audio-format" "mp3" "--audio-quality" "0")
    info "模式: 仅音频 (MP3)"
  else
    case "$QUALITY" in
      best)
        if [[ "$FFMPEG_AVAILABLE" -eq 1 ]]; then
          YTDLP_ARGS+=("-f" "bestvideo+bestaudio/best")
        else
          YTDLP_ARGS+=("-f" "best")
        fi
        ;;
      worst) YTDLP_ARGS+=("-f" "worst") ;;
      *)
        if [[ "$FFMPEG_AVAILABLE" -eq 1 ]]; then
          YTDLP_ARGS+=("-f" "bestvideo[height<=${QUALITY}]+bestaudio/best[height<=${QUALITY}]")
        else
          YTDLP_ARGS+=("-f" "best[height<=${QUALITY}]")
        fi
        ;;
    esac
    info "模式: 视频  画质: ${QUALITY}"
  fi

  # 播放列表
  [[ "$MODE_LIST" -eq 0 ]] && YTDLP_ARGS+=("--no-playlist")

  # 字幕
  if [[ "$SUBTITLE" -eq 1 ]]; then
    YTDLP_ARGS+=("--write-subs" "--write-auto-subs" "--sub-langs" "zh-Hans,zh,en")
    info "字幕: 开启"
  fi

  # 代理
  if [[ -n "$PROXY" ]]; then
    YTDLP_ARGS+=("--proxy" "$PROXY")
    info "代理: $PROXY"
  fi

  # Cookie
  YTDLP_ARGS+=("${COOKIE_ARGS[@]+"${COOKIE_ARGS[@]}"}")

  # 重试
  YTDLP_ARGS+=("--progress" "--retries" "5" "--fragment-retries" "5")
}

# ── 执行下载 ─────────────────────────────────
do_download() {
  step "开始下载..."
  info "链接: $URL"
  info "保存到: $OUTPUT_DIR"
  echo ""

  mkdir -p "$OUTPUT_DIR"

  # 先获取视频标题
  local title=""
  title=$("$YT_DLP_BIN" --get-title --no-playlist "$URL" 2>/dev/null || echo "未知视频")

  if "$YT_DLP_BIN" "${YTDLP_ARGS[@]}" "$URL"; then
    echo ""
    success "下载完成！文件保存在: ${BLD}$OUTPUT_DIR${RST}"

    # 文件列表
    echo -e "\n${DIM}── 文件列表 ──────────────────────────${RST}"
    ls -lh "$OUTPUT_DIR" | tail -n +2 | awk '{print "  "$NF" ("$5")"}'

    # 自动复制到手机相册
    if [[ -d "/sdcard/Movies" ]]; then
      mkdir -p /sdcard/Movies/vget
      cp "$OUTPUT_DIR"/* /sdcard/Movies/vget/ 2>/dev/null || true
      success "已同步到手机相册: /sdcard/Movies/vget/"
    fi

    # 保存历史记录
    save_history "$URL" "$title"

    # 发送通知
    send_notification "$title"

  else
    echo ""
    error "下载失败！常见解决方案："
    echo "  1. 使用代理：bash vget.sh <链接> --proxy socks5://127.0.0.1:1080"
    echo "  2. 更新工具：bash vget.sh --update"
    echo "  3. 检查链接是否有效"
    echo "  4. 将 cookies.txt 放在脚本同目录"
    exit 1
  fi
}

# ── 参数解析 ─────────────────────────────────
URL=""
MODE_AUDIO=0
MODE_LIST=0
QUALITY="best"
OUTPUT_DIR="./downloads"
SUBTITLE=0
PROXY=""

[[ $# -eq 0 ]] && usage

while [[ $# -gt 0 ]]; do
  case "$1" in
    --help|-h)       usage ;;
    --version|-v)    echo "vget v${VERSION}"; exit 0 ;;
    --update)        detect_os; setup_paths; update_ytdlp ;;
    --history)       detect_os; setup_paths; show_history ;;
    --clear-history) detect_os; setup_paths; clear_history ;;
    --audio|-a)      MODE_AUDIO=1; shift ;;
    --list|-l)       MODE_LIST=1; shift ;;
    --subtitle|-s)   SUBTITLE=1; shift ;;
    --quality|-q)    QUALITY="$2"; shift 2 ;;
    --output|-o)     OUTPUT_DIR="$2"; shift 2 ;;
    --proxy|-p)      PROXY="$2"; shift 2 ;;
    http*|https*)    URL="$1"; shift ;;
    *)
      error "未知选项: $1"
      echo "运行 bash vget.sh --help 查看用法"
      exit 1
      ;;
  esac
done

if [[ -z "$URL" ]]; then
  error "请提供视频链接！"
  echo "示例: bash vget.sh https://www.youtube.com/watch?v=xxxxx"
  exit 1
fi

# ── 主流程 ───────────────────────────────────
banner
detect_os
setup_paths
ensure_ytdlp
check_ffmpeg
detect_cookies
build_args
do_download
success() { echo -e "${GRN}[✓]${RST} $*"; }
warn()    { echo -e "${YEL}[!]${RST} $*"; }
error()   { echo -e "${RED}[✗]${RST} $*" >&2; }
step()    { echo -e "\n${BLD}${BLU}▶ $*${RST}"; }

# ── Banner ───────────────────────────────────
banner() {
  echo -e "${BLD}${CYA}"
  echo "  ╦  ╦╔═╗╔═╗╔╦╗"
  echo "  ╚╗╔╝║ ╦║╣  ║ "
  echo "   ╚╝ ╚═╝╚═╝ ╩ "
  echo -e "${RST}${DIM}  傻瓜式视频下载工具 v${VERSION}${RST}"
  echo -e "${DIM}  支持 YouTube · B站 · Twitter · TikTok · 1000+ 网站${RST}\n"
}

# ── 帮助 ─────────────────────────────────────
usage() {
  banner
  echo -e "${BLD}用法:${RST}"
  echo "  bash vget.sh <视频链接> [选项]"
  echo ""
  echo -e "${BLD}选项:${RST}"
  echo "  --audio       仅下载音频（MP3）"
  echo "  --list        下载整个播放列表"
  echo "  --quality N   指定画质（best/worst/720/1080，默认 best）"
  echo "  --output DIR  指定下载目录（默认 ./downloads）"
  echo "  --subtitle    同时下载字幕"
  echo "  --proxy URL   使用代理（如 socks5://127.0.0.1:1080）"
  echo "  --version     显示版本号"
  echo "  --help        显示此帮助"
  echo ""
  echo -e "${BLD}示例:${RST}"
  echo "  bash vget.sh https://www.youtube.com/watch?v=dQw4w9WgXcQ"
  echo "  bash vget.sh https://www.bilibili.com/video/BV1xx411c7mD"
  echo "  bash vget.sh https://twitter.com/NASA/status/1234567890"
  echo "  bash vget.sh https://www.youtube.com/watch?v=xxxxx --audio"
  echo "  bash vget.sh https://www.youtube.com/watch?v=xxxxx --quality 1080"
  echo ""
  exit 0
}

# ── 检测系统 ─────────────────────────────────
detect_os() {
  OS="unknown"
  ARCH=$(uname -m)

  case "$(uname -s)" in
    Linux*)
      OS="linux"
      # 检测是否是 Android/Termux
      [[ -d /data/data/com.termux ]] && OS="termux"
      ;;
    Darwin*) OS="macos" ;;
    MINGW*|MSYS*|CYGWIN*) OS="windows" ;;
  esac

  case "$ARCH" in
    x86_64|amd64) ARCH="x86_64" ;;
    aarch64|arm64) ARCH="aarch64" ;;
    armv7*) ARCH="armv7" ;;
  esac

  info "系统: ${OS} / ${ARCH}"
}

# ── 确定 yt-dlp 存放路径 ─────────────────────
setup_paths() {
  # 优先使用脚本同目录下的 bin/
  SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  BIN_DIR="${SCRIPT_DIR}/bin"
  mkdir -p "$BIN_DIR"

  YT_DLP_BIN="${BIN_DIR}/yt-dlp"
  [[ "$OS" == "windows" ]] && YT_DLP_BIN="${BIN_DIR}/yt-dlp.exe"
}

# ── 下载 yt-dlp（免安装核心） ─────────────────
download_ytdlp() {
  local url=""

  case "${OS}-${ARCH}" in
    linux-x86_64)   url="https://github.com/yt-dlp/yt-dlp/releases/latest/download/yt-dlp" ;;
    linux-aarch64)  url="https://github.com/yt-dlp/yt-dlp/releases/latest/download/yt-dlp_linux_aarch64" ;;
    linux-armv7)    url="https://github.com/yt-dlp/yt-dlp/releases/latest/download/yt-dlp_linux_armv7l" ;;
    termux-*)       url="https://github.com/yt-dlp/yt-dlp/releases/latest/download/yt-dlp" ;;
    macos-*)        url="https://github.com/yt-dlp/yt-dlp/releases/latest/download/yt-dlp_macos" ;;
    windows-*)      url="https://github.com/yt-dlp/yt-dlp/releases/latest/download/yt-dlp.exe" ;;
    *)
      warn "未知系统，尝试通用版本..."
      url="https://github.com/yt-dlp/yt-dlp/releases/latest/download/yt-dlp"
      ;;
  esac

  step "首次运行：下载核心组件 yt-dlp..."
  info "来源: $url"
  info "目标: $YT_DLP_BIN"

  local download_ok=0

  # 尝试 curl
  if command -v curl &>/dev/null; then
    if curl -L --progress-bar --retry 3 --connect-timeout 15 \
         -o "$YT_DLP_BIN" "$url"; then
      download_ok=1
    fi
  fi

  # 回退到 wget
  if [[ $download_ok -eq 0 ]] && command -v wget &>/dev/null; then
    if wget --show-progress -q --tries=3 --timeout=15 \
         -O "$YT_DLP_BIN" "$url"; then
      download_ok=1
    fi
  fi

  if [[ $download_ok -eq 0 ]]; then
    error "下载失败！请检查网络连接，或手动下载："
    error "  $url"
    error "  → 保存到: $YT_DLP_BIN"
    exit 1
  fi

  chmod +x "$YT_DLP_BIN"
  success "yt-dlp 已就绪 → ${BIN_DIR}/yt-dlp"
}

# ── 确保 yt-dlp 可用 ─────────────────────────
ensure_ytdlp() {
  # 1. 优先用本地 bin/yt-dlp
  if [[ -x "$YT_DLP_BIN" ]]; then
    return 0
  fi

  # 2. 检查系统全局安装
  if command -v yt-dlp &>/dev/null; then
    YT_DLP_BIN=$(command -v yt-dlp)
    info "使用系统已安装的 yt-dlp: $YT_DLP_BIN"
    return 0
  fi

  # 3. 自动下载
  download_ytdlp
}

# ── 检测 ffmpeg（可选，用于合并音视频）─────────
check_ffmpeg() {
  if command -v ffmpeg &>/dev/null; then
    FFMPEG_AVAILABLE=1
    info "ffmpeg 已检测到，支持最高画质合并"
  else
    FFMPEG_AVAILABLE=0
    warn "未检测到 ffmpeg，将自动选择单文件格式（画质可能受限）"
    warn "提示：安装 ffmpeg 可获得最佳画质"
    case "$OS" in
      linux|termux) warn "  sudo apt install ffmpeg  /  pkg install ffmpeg" ;;
      macos)        warn "  brew install ffmpeg" ;;
    esac
  fi
}

# ── 更新 yt-dlp ───────────────────────────────
update_ytdlp() {
  step "更新 yt-dlp..."
  if [[ -x "$YT_DLP_BIN" ]]; then
    "$YT_DLP_BIN" -U || download_ytdlp
  else
    download_ytdlp
  fi
  success "更新完成"
  exit 0
}

# ── 构建下载参数 ──────────────────────────────
build_args() {
  YTDLP_ARGS=()

  # 输出目录
  YTDLP_ARGS+=("-P" "$OUTPUT_DIR")

  # 文件名模板
  YTDLP_ARGS+=("-o" "%(title)s.%(ext)s")

  # 仅音频模式
  if [[ "$MODE_AUDIO" -eq 1 ]]; then
    YTDLP_ARGS+=("-x" "--audio-format" "mp3" "--audio-quality" "0")
    info "模式: 仅音频 (MP3)"
  else
    # 画质选择
    case "$QUALITY" in
      best)
        if [[ "$FFMPEG_AVAILABLE" -eq 1 ]]; then
          YTDLP_ARGS+=("-f" "bestvideo+bestaudio/best")
        else
          YTDLP_ARGS+=("-f" "best")
        fi
        ;;
      worst) YTDLP_ARGS+=("-f" "worst") ;;
      *)
        # 指定分辨率，如 720 / 1080
        if [[ "$FFMPEG_AVAILABLE" -eq 1 ]]; then
          YTDLP_ARGS+=("-f" "bestvideo[height<=${QUALITY}]+bestaudio/best[height<=${QUALITY}]")
        else
          YTDLP_ARGS+=("-f" "best[height<=${QUALITY}]")
        fi
        ;;
    esac
    info "模式: 视频  画质: ${QUALITY}"
  fi

  # 播放列表
  [[ "$MODE_LIST" -eq 0 ]] && YTDLP_ARGS+=("--no-playlist")

  # 字幕
  if [[ "$SUBTITLE" -eq 1 ]]; then
    YTDLP_ARGS+=("--write-subs" "--write-auto-subs" "--sub-langs" "zh-Hans,zh,en")
    info "字幕: 开启（中文优先）"
  fi

  # 代理
  if [[ -n "$PROXY" ]]; then
    YTDLP_ARGS+=("--proxy" "$PROXY")
    info "代理: $PROXY"
  fi

  # 进度条 & 重试
  YTDLP_ARGS+=("--progress" "--retries" "5" "--fragment-retries" "5")

  # B站 Cookie 提示
  if [[ "$URL" =~ bilibili\.com ]]; then
    warn "B站提示：若下载失败或画质受限，可添加 Cookie："
    warn "  在浏览器登录 B站，导出 cookies.txt，然后添加选项 --cookies cookies.txt"
  fi
}

# ── 执行下载 ─────────────────────────────────
do_download() {
  step "开始下载..."
  info "链接: $URL"
  info "保存到: $OUTPUT_DIR"
  echo ""

  mkdir -p "$OUTPUT_DIR"

  if "$YT_DLP_BIN" "${YTDLP_ARGS[@]}" "$URL"; then
    echo ""
    success "下载完成！文件保存在: ${BLD}$OUTPUT_DIR${RST}"
    # 列出刚下载的文件
    echo -e "\n${DIM}── 文件列表 ──────────────────────────${RST}"
    ls -lh "$OUTPUT_DIR" | tail -n +2 | awk '{print "  "$NF" ("$5")"}'
  else
    echo ""
    error "下载失败！常见解决方案："
    echo "  1. 检查网络 / 开启代理：bash vget.sh <链接> --proxy socks5://127.0.0.1:1080"
    echo "  2. 更新工具：bash vget.sh --update"
    echo "  3. 检查链接是否正确且视频未被删除"
    echo "  4. B站大会员视频需要 Cookie，请参考 README"
    exit 1
  fi
}

# ── 参数解析 ─────────────────────────────────
URL=""
MODE_AUDIO=0
MODE_LIST=0
QUALITY="best"
OUTPUT_DIR="./downloads"
SUBTITLE=0
PROXY=""

[[ $# -eq 0 ]] && usage

while [[ $# -gt 0 ]]; do
  case "$1" in
    --help|-h)       usage ;;
    --version|-v)    echo "vget v${VERSION}"; exit 0 ;;
    --update)        detect_os; setup_paths; update_ytdlp ;;
    --audio|-a)      MODE_AUDIO=1; shift ;;
    --list|-l)       MODE_LIST=1; shift ;;
    --subtitle|-s)   SUBTITLE=1; shift ;;
    --quality|-q)    QUALITY="$2"; shift 2 ;;
    --output|-o)     OUTPUT_DIR="$2"; shift 2 ;;
    --proxy|-p)      PROXY="$2"; shift 2 ;;
    http*|https*)    URL="$1"; shift ;;
    *)
      error "未知选项: $1"
      echo "运行 bash vget.sh --help 查看用法"
      exit 1
      ;;
  esac
done

if [[ -z "$URL" ]]; then
  error "请提供视频链接！"
  echo "示例: bash vget.sh https://www.youtube.com/watch?v=xxxxx"
  exit 1
fi

# ── 主流程 ───────────────────────────────────
banner
detect_os
setup_paths
ensure_ytdlp
check_ffmpeg
build_args
do_download
