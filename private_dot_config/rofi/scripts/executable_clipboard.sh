#!/usr/bin/env python3
"""
Rofi Clipboard Manager
- Full images: saves raw decoded images directly to cache without any resizing/downscaling.
- Direct text: passes text directly to Rofi for native crisp font rendering (no blur).
- Preserves searchability, copy on Enter, delete on Alt+D, and clear all.
"""

import os
import sys
import subprocess
import re

ROFI_THEME = os.path.expanduser("~/.config/rofi/clipboard.rasi")
CACHE_DIR = os.path.join(os.environ.get("XDG_RUNTIME_DIR", "/tmp"), "cliphist-full-images")
os.makedirs(CACHE_DIR, exist_ok=True)

def detect_image_extension(content):
    match = re.search(r'\b(png|jpeg|jpg|gif|bmp|webp|tif|tiff|svg)\b', content.lower())
    if match:
        ext = match.group(1)
        if ext == "jpeg":
            ext = "jpg"
        return ext
    return "png"

def save_full_image(cid, raw_line, content):
    ext = detect_image_extension(content)
    dest_path = os.path.join(CACHE_DIR, f"{cid}.{ext}")
    if os.path.exists(dest_path) and os.path.getsize(dest_path) > 0:
        return dest_path

    try:
        p = subprocess.Popen(["cliphist", "decode"], stdin=subprocess.PIPE, stdout=open(dest_path, "wb"))
        p.communicate(input=raw_line.encode("utf-8"))
        if os.path.exists(dest_path) and os.path.getsize(dest_path) > 0:
            return dest_path
    except Exception:
        pass
    return None

def get_cliphist_entries():
    try:
        raw = subprocess.check_output(["cliphist", "list"], stderr=subprocess.DEVNULL)
        return raw.decode("utf-8", errors="ignore").splitlines()
    except Exception:
        return []

def main():
    entries = get_cliphist_entries()
    if not entries:
        subprocess.run(["rofi", "-e", "Clipboard is empty.", "-theme", ROFI_THEME])
        sys.exit(0)

    rofi_items = []
    lookup = []

    # Sentinel row for clearing all history
    rofi_items.append("󰆴  Clear all history")
    lookup.append(("SENTINEL", ""))

    for line in entries:
        parts = line.split("\t", 1)
        if len(parts) < 2:
            continue
        cid, content = parts[0].strip(), parts[1]

        is_image = "[[" in content and "binary" in content

        if is_image:
            img_path = save_full_image(cid, line, content)
            if img_path:
                # Direct full image passed as icon with a zero-width space text
                rofi_items.append(f"\u200B\0icon\x1f{img_path}")
            else:
                rofi_items.append(content)
        else:
            # Direct native text (clean, crisp, no rasterization or blur)
            clean_text = content.strip()
            # Collapse single line or keep multiline preview
            rofi_items.append(clean_text)

        lookup.append((cid, line))

    rofi_input = "\n".join(rofi_items)

    rofi_cmd = [
        "rofi",
        "-dmenu",
        "-i",
        "-p", "Clipboard",
        "-show-icons",
        "-format", "i",
        "-theme", ROFI_THEME,
        "-kb-custom-1", "Alt+d",
        "-kb-remove-char-forward", "ctrl+Delete",
        "-mesg", "↵ Paste  |  Alt+D Delete entry"
    ]

    p = subprocess.Popen(rofi_cmd, stdin=subprocess.PIPE, stdout=subprocess.PIPE, stderr=subprocess.DEVNULL, text=True)
    stdout, _ = p.communicate(input=rofi_input)
    exit_code = p.returncode

    selected_str = stdout.strip()
    if not selected_str or selected_str == "-1":
        sys.exit(0)

    try:
        selected_idx = int(selected_str)
    except ValueError:
        sys.exit(0)

    if selected_idx < 0 or selected_idx >= len(lookup):
        sys.exit(0)

    cid, raw_line = lookup[selected_idx]

    # Clear all history
    if cid == "SENTINEL":
        subprocess.run(["cliphist", "wipe"])
        for f in os.listdir(CACHE_DIR):
            try:
                os.remove(os.path.join(CACHE_DIR, f))
            except Exception:
                pass
        subprocess.run(["notify-send", "-i", "edit-clear", "Clipboard", "History cleared.", "-t", "2000"], stderr=subprocess.DEVNULL)
        sys.exit(0)

    # Alt+D: Delete entry
    if exit_code == 10:
        subprocess.run(["cliphist", "delete"], input=raw_line.encode("utf-8"), stderr=subprocess.DEVNULL)
        for ext in ["png", "jpg", "jpeg", "gif", "webp"]:
            f = os.path.join(CACHE_DIR, f"{cid}.{ext}")
            if os.path.exists(f):
                os.remove(f)
        os.execv(sys.argv[0], sys.argv)

    # Normal select: decode & wl-copy
    p_dec = subprocess.Popen(["cliphist", "decode"], stdin=subprocess.PIPE, stdout=subprocess.PIPE)
    dec_out, _ = p_dec.communicate(input=raw_line.encode("utf-8"))

    p_copy = subprocess.Popen(["wl-copy"], stdin=subprocess.PIPE)
    p_copy.communicate(input=dec_out)

if __name__ == "__main__":
    main()
