"""Serve the built APK over the local network so a phone can install it.

Usage:  python tools/serve_apk.py [port]

Builds a small download page next to the APK and serves it on every local
interface. Nothing leaves the machine — the phone just needs to be on the same
Wi-Fi. Stop it with Ctrl-C.
"""

import hashlib
import http.server
import shutil
import socket
import socketserver
import sys
from datetime import datetime
from pathlib import Path

PROJECT = Path(__file__).resolve().parent.parent
DIST = PROJECT / "dist"
APK_CANDIDATES = [
    PROJECT / "build/app/outputs/flutter-apk/app-release.apk",
    PROJECT / "build/app/outputs/flutter-apk/app-debug.apk",
]


def lan_ip() -> str:
    """Best-guess address the phone should dial."""
    s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    try:
        # No packets are actually sent; this just picks the outbound interface.
        s.connect(("8.8.8.8", 80))
        return s.getsockname()[0]
    except OSError:
        return "127.0.0.1"
    finally:
        s.close()


PAGE = """<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>Cafe POS - Install</title>
<style>
  :root {{ color-scheme: light dark; }}
  * {{ box-sizing: border-box; }}
  body {{
    margin: 0; padding: 24px;
    font: 16px/1.5 -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif;
    background: #0f172a; color: #e2e8f0;
    display: flex; justify-content: center;
  }}
  .card {{ width: 100%; max-width: 460px; }}
  h1 {{ font-size: 26px; margin: 0 0 4px; }}
  .sub {{ color: #94a3b8; margin: 0 0 24px; }}
  .cup {{ font-size: 44px; }}
  a.dl {{
    display: block; text-align: center; text-decoration: none;
    background: #2563eb; color: #fff; font-weight: 600; font-size: 18px;
    padding: 18px; border-radius: 14px; margin: 20px 0;
  }}
  a.dl:active {{ background: #1d4ed8; }}
  .meta {{
    background: #1e293b; border-radius: 12px; padding: 14px 16px;
    font-size: 13px; color: #cbd5e1;
  }}
  .meta div {{ display: flex; justify-content: space-between; padding: 3px 0; gap: 12px; }}
  .meta code {{ font-size: 11px; word-break: break-all; text-align: right; }}
  ol {{ padding-left: 20px; color: #cbd5e1; font-size: 14px; }}
  li {{ margin-bottom: 8px; }}
  h2 {{ font-size: 15px; margin: 28px 0 8px; color: #f1f5f9; }}
  .warn {{
    background: rgba(245,158,11,.14); border-radius: 10px;
    padding: 12px 14px; font-size: 13px; color: #fcd34d; margin-top: 20px;
  }}
</style>
</head>
<body>
<div class="card">
  <div class="cup">&#9749;</div>
  <h1>Caf&eacute; POS</h1>
  <p class="sub">Point of sale for caf&eacute;s and restaurants</p>

  <a class="dl" href="{apk_name}" download>Download APK &middot; {size_mb} MB</a>

  <div class="meta">
    <div><span>Version</span><span>{version}</span></div>
    <div><span>Built</span><span>{built}</span></div>
    <div><span>Min Android</span><span>5.0 (API 21)</span></div>
    <div><span>SHA-256</span><code>{sha}</code></div>
  </div>

  <h2>Installing</h2>
  <ol>
    <li>Tap <b>Download APK</b> above.</li>
    <li>Open the downloaded file.</li>
    <li>Android will ask to allow installs from this source &mdash; allow it,
        then press Install.</li>
    <li>Open the app and create your owner account and PIN.</li>
  </ol>

  <h2>First run</h2>
  <ol>
    <li>Set your currency under <b>More &rarr; Shop Details</b>.</li>
    <li>A sample caf&eacute; menu is already loaded &mdash; edit it under <b>Menu</b>.</li>
    <li>Pair a Bluetooth thermal printer under <b>More &rarr; Printer</b> (optional;
        orders save without one).</li>
  </ol>

  <div class="warn">
    This page is served from a computer on your own Wi-Fi. It is not on the
    internet, and it stops working when that computer stops serving it.
  </div>
</div>
</body>
</html>
"""


def main() -> int:
    port = int(sys.argv[1]) if len(sys.argv) > 1 else 8000

    apk = next((p for p in APK_CANDIDATES if p.exists()), None)
    if apk is None:
        print("No APK found. Run:  flutter build apk --release")
        return 1

    DIST.mkdir(exist_ok=True)
    target = DIST / "cafe-pos.apk"
    shutil.copy2(apk, target)

    size_mb = round(target.stat().st_size / (1024 * 1024), 1)
    sha = hashlib.sha256(target.read_bytes()).hexdigest()
    built = datetime.fromtimestamp(apk.stat().st_mtime).strftime("%d %b %Y, %H:%M")

    (DIST / "index.html").write_text(
        PAGE.format(
            apk_name=target.name,
            size_mb=size_mb,
            sha=sha,
            built=built,
            version=f"1.0.0 ({'release' if 'release' in apk.name else 'debug'})",
        ),
        encoding="utf-8",
    )

    ip = lan_ip()
    print("=" * 52)
    print(f"  Cafe POS ready:  http://{ip}:{port}")
    print(f"  APK: {size_mb} MB   sha256: {sha[:16]}...")
    print("=" * 52)
    print("  Open that address on your phone (same Wi-Fi).")
    print("  Ctrl-C to stop serving.")

    class Handler(http.server.SimpleHTTPRequestHandler):
        def __init__(self, *a, **kw):
            super().__init__(*a, directory=str(DIST), **kw)

        def guess_type(self, path):
            # Must be set here, not in end_headers: the base handler emits
            # Content-Type from this before end_headers ever runs, so a late
            # send_header() is ignored and the APK goes out as octet-stream.
            if str(path).endswith(".apk"):
                return "application/vnd.android.package-archive"
            return super().guess_type(path)

        def log_message(self, fmt, *args):
            print(f"  [{self.address_string()}] {fmt % args}", flush=True)

    socketserver.TCPServer.allow_reuse_address = True
    with socketserver.TCPServer(("0.0.0.0", port), Handler) as httpd:
        try:
            httpd.serve_forever()
        except KeyboardInterrupt:
            print("\nstopped.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
