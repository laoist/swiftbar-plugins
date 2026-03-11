#!/bin/bash

# <xbar.title>Now Playing</xbar.title>
# <xbar.version>v1.0</xbar.version>
# <xbar.author>Josh Pomery</xbar.author>
# <xbar.author.github>laoist</xbar.author.github>
# <xbar.desc>Displays currently playing track from Tidal via media-control.</xbar.desc>
# <xbar.dependencies>media-control</xbar.dependencies>
# <swiftbar.refreshOnOpen>true</swiftbar.refreshOnOpen>
# <swiftbar.persistentWebView>true</swiftbar.persistentWebView>
# <swiftbar.hideAbout>true</swiftbar.hideAbout>
# <swiftbar.hideRunInTerminal>true</swiftbar.hideRunInTerminal>
# <swiftbar.hideLastUpdated>true</swiftbar.hideLastUpdated>
# <swiftbar.hideDisablePlugin>true</swiftbar.hideDisablePlugin>
# <swiftbar.hideSwiftBar>true</swiftbar.hideSwiftBar>

# Timeout prevents the plugin hanging if media-control stalls
output=$(timeout 3 /opt/homebrew/bin/media-control get 2>/dev/null)

if [ $? -ne 0 ]; then
    echo "♫ | color=#555555"
    echo "---"
    echo "media-control timed out or failed"
    exit 0
fi

if [ -z "$output" ] || [ "$output" = "null" ]; then
    echo "♫ | color=#555555"
    exit 0
fi

/usr/bin/python3 - <<'PYEOF' "$output"
import sys, json, os, re, traceback
from html import escape

def placeholder():
    print("♫ | color=#555555")
    sys.exit(0)

try:
    d = json.loads(sys.argv[1])

    if not d.get('playing') or not d.get('title'):
        placeholder()

    # Escape all metadata before interpolating into HTML
    artist    = escape(d.get('artist', ''))
    title     = escape(d.get('title', ''))
    album     = escape(d.get('album', ''))
    timestamp = d.get('timestamp', '')

    # Escape asterisks separately for menu bar markdown rendering
    artist_md = artist.replace('*', '\\*')
    title_md  = title.replace('*', '\\*')

    # Cast explicitly to float to handle null or unexpected types
    duration = float(d.get('duration') or 0)
    elapsed  = float(d.get('elapsedTime') or 0)

    # Whitelist known safe MIME types, fall back to jpeg
    ALLOWED_MIME = {'image/jpeg', 'image/png', 'image/webp', 'image/gif'}
    mime = d.get('artworkMimeType', 'image/jpeg')
    if mime not in ALLOWED_MIME:
        mime = 'image/jpeg'

    # Validate artwork is pure base64 — discard if anything unexpected is present
    artwork = d.get('artworkData', '')
    if artwork and not re.match(r'^[A-Za-z0-9+/=\n]+$', artwork):
        artwork = ''

    def fmt_time(s):
        if not s:
            return '0:00'
        s = int(s)
        return f"{s // 60}:{s % 60:02d}"

    duration_fmt = fmt_time(duration)
    progress_pct = (elapsed / duration * 100) if duration else 0

    # Write to user-owned path instead of /tmp — file contains artwork data
    html_dir  = os.path.expanduser('~/.cache/swiftbar')
    html_path = os.path.join(html_dir, 'nowplaying.html')
    os.makedirs(html_dir, exist_ok=True)

    html = f"""<!DOCTYPE html>
<html>
<head>
<meta charset="utf-8">
<style>
  * {{ margin: 0; padding: 0; box-sizing: border-box; }}
  html, body {{ overflow: hidden; }}
  ::-webkit-scrollbar {{ display: none; }}
  body {{
    background: #1a1a1a;
    font-family: -apple-system, sans-serif;
    padding: 14px;
    display: flex;
    flex-direction: column;
    gap: 12px;
    height: 100vh;
  }}
  .top {{
    display: flex;
    gap: 14px;
    align-items: center;
  }}
  img {{
    width: 72px;
    height: 72px;
    border-radius: 6px;
    flex-shrink: 0;
    object-fit: cover;
  }}
  .placeholder {{
    width: 72px;
    height: 72px;
    border-radius: 6px;
    background: #333;
    display: flex;
    align-items: center;
    justify-content: center;
    font-size: 28px;
    flex-shrink: 0;
  }}
  .info {{
    flex: 1;
    overflow: hidden;
    border-left: 3px solid #e84393;
    padding-left: 12px;
  }}
  .title {{
    font-size: 14px;
    font-weight: 600;
    color: #ffffff;
    white-space: nowrap;
    overflow: hidden;
    text-overflow: ellipsis;
  }}
  .artist {{
    font-size: 12px;
    color: #aaaaaa;
    margin-top: 3px;
    white-space: nowrap;
    overflow: hidden;
    text-overflow: ellipsis;
  }}
  .album {{
    font-size: 11px;
    color: #666666;
    margin-top: 3px;
    white-space: nowrap;
    overflow: hidden;
    text-overflow: ellipsis;
  }}
  .progress-container {{
    width: 100%;
    background: #333;
    border-radius: 2px;
    height: 3px;
    overflow: hidden;
  }}
  .progress-bar {{
    height: 3px;
    background: #e84393;
    border-radius: 2px;
    transition: width 1s linear;
  }}
  .time-row {{
    display: flex;
    justify-content: space-between;
    margin-top: 4px;
  }}
  .time {{
    font-size: 10px;
    color: #555;
  }}
</style>
</head>
<body>
  <div class="top">
    {'<img src="data:' + mime + ';base64,' + artwork + '">' if artwork else '<div class="placeholder">♫</div>'}
    <div class="info">
      <div class="title">{title}</div>
      <div class="artist">{artist}</div>
      {'<div class="album">' + album + '</div>' if album else ''}
    </div>
  </div>

  <div>
    <div class="progress-container">
      <div class="progress-bar" id="progress" style="width:{progress_pct:.1f}%"></div>
    </div>
    <div class="time-row">
      <span class="time" id="elapsed">{fmt_time(elapsed)}</span>
      <span class="time">{duration_fmt}</span>
    </div>
  </div>

  <script>
    const elapsed = {elapsed:.2f};
    const duration = {duration:.2f};
    const tsMs = "{timestamp}" !== "" ? new Date("{timestamp}").getTime() : Date.now();

    function update() {{
      const now = Date.now();
      const current = elapsed + (now - tsMs) / 1000;
      const pct = duration ? Math.min(current / duration * 100, 100) : 0;

      const bar = document.getElementById('progress');
      const elapsedEl = document.getElementById('elapsed');

      if (bar) bar.style.width = pct.toFixed(1) + '%';
      if (elapsedEl) {{
        const s = Math.floor(current);
        elapsedEl.textContent = Math.floor(s / 60) + ':' + String(s % 60).padStart(2, '0');
      }}
    }}

    update();
    setInterval(update, 1000);
  </script>
</body>
</html>"""

    with open(html_path, 'w') as f:
        f.write(html)

    # Owner read/write only
    os.chmod(html_path, 0o600)

    html_file_url = f"file://{html_path}"
    print(f"**{artist_md}** — {title_md} | md=true href={html_file_url} webview=true webvieww=320 webviewh=160")

except Exception:
    # Show error in menu bar dropdown for easier debugging
    print("♫ | color=#ff4444")
    print("---")
    print("nowplaying error:")
    for line in traceback.format_exc().splitlines():
        print(line)

PYEOF

