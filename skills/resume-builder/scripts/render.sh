#!/usr/bin/env bash
# render.sh - 无头 Chrome 渲染 A4 PDF 并报告页数
# 用法: bash scripts/render.sh <input.html> <output.pdf>
#
# 跨平台适配:
#   - macOS: /Applications/Google Chrome.app/Contents/MacOS/Google Chrome
#   - Linux: chromium / google-chrome / chromium-browser(按优先级查找)
#   - 其他: 抛错并提示安装
set -euo pipefail

IN="${1:-}"
OUT="${2:-}"

if [[ -z "$IN" || -z "$OUT" ]]; then
  echo "用法: $0 <input.html> <output.pdf>" >&2
  exit 1
fi

if [[ ! -f "$IN" ]]; then
  echo "错误: 找不到输入文件 $IN" >&2
  exit 1
fi

# 查找 Chrome / Chromium
CHROME=""
if [[ "$(uname)" == "Darwin" ]]; then
  CHROME="/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
  if [[ ! -x "$CHROME" ]]; then
    CHROME="$(command -v chromium || command -v google-chrome || true)"
  fi
else
  CHROME="$(command -v chromium || command -v chromium-browser || command -v google-chrome || command -v google-chrome-stable || true)"
fi

if [[ -z "$CHROME" || ! -x "$CHROME" ]]; then
  cat >&2 <<'EOF'
错误: 未找到 Chrome / Chromium。可选方案:
  - macOS:   brew install --cask google-chrome
  - Ubuntu:  sudo apt install -y chromium-browser
             或 snap install chromium
  - 其他:    见 https://github.com/GoogleChrome/chrome-for-testing
EOF
  exit 1
fi

# 渲染
"$CHROME" --headless --disable-gpu --no-pdf-header-footer \
  --print-to-pdf="$OUT" \
  "file://$(cd "$(dirname "$IN")" && pwd)/$(basename "$IN")" \
  >/dev/null 2>&1

# 报告页数 + 字节数(用 python3,跨平台)
python3 - "$OUT" <<'PYEOF'
import re, sys
data = open(sys.argv[1], 'rb').read()
pages = len(re.findall(rb'/Type\s*/Page[^s]', data))
print(f"OK {sys.argv[1]}  pages={pages}  bytes={len(data)}")
PYEOF

# 视觉验收提示
cat <<'NOTE'

验收:
  1. 用 PyMuPDF 渲染第一页为 PNG 自查:
     python3 -c "import fitz; doc=fitz.open('OUTPUT_PDF'); doc[0].get_pixmap(matrix=fitz.Matrix(2,2)).save('check.png')"
  2. 确认色块+字号+分行+无孤行溢出
  3. 终稿前所有 .todo 黄色高亮占位应已消除
NOTE