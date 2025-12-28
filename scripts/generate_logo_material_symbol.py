#!/usr/bin/env python3
"""Generate a simple red-on-black SVG logo from Google Material Symbols.

This script fetches a minimal, single-icon TTF from Google Fonts (Material Symbols)
for a specific icon name and style configuration, then extracts the glyph outline
and writes it as an SVG.

Why this approach?
- It uses the official Google Fonts distribution for Material Symbols.
- It’s reproducible and avoids checking in large font files.

License note:
- Material Symbols are available under the Apache License 2.0.
  See docs/brand/THIRD_PARTY_NOTICES.md.

Usage (example):
  python3 scripts/generate_logo_material_symbol.py

Output:
  docs/brand/logo-emoji-language-red-black.svg
"""

from __future__ import annotations

import argparse
import io
import re
import sys
import urllib.request
from dataclasses import dataclass


@dataclass(frozen=True)
class SymbolConfig:
    family: str = "Material+Symbols+Outlined"
    icon_name: str = "emoji_language"
    codepoint_hex: str = "f4cd"
    opsz: int = 48
    wght: int = 700
    fill: int = 0
    grad: int = 0


def _fetch_text(url: str) -> str:
    req = urllib.request.Request(url, headers={"User-Agent": "Mozilla/5.0"})
    with urllib.request.urlopen(req, timeout=30) as r:
        return r.read().decode("utf-8")


def _fetch_bytes(url: str) -> bytes:
    req = urllib.request.Request(url, headers={"User-Agent": "Mozilla/5.0"})
    with urllib.request.urlopen(req, timeout=60) as r:
        return r.read()


def _extract_ttf_url_from_css(css: str) -> str:
    # Google Fonts sometimes serves woff2, sometimes a TTF (for icons it’s TTF).
    # We accept either, but we strongly prefer TTF because it works without extra deps.
    urls = re.findall(r"src:\s*url\((https?://[^)]+)\)\s*format\('([^']+)'\)", css)
    if not urls:
        raise RuntimeError("Could not find font src url(...) in CSS")

    # Prefer truetype.
    for url, fmt in urls:
        if fmt.lower() == "truetype":
            return url

    # Fall back to first.
    return urls[0][0]


def _glyph_svg_path_from_ttf(ttf_bytes: bytes, codepoint: int) -> tuple[str, tuple[float, float, float, float]]:
    try:
        from fontTools.ttLib import TTFont
        from fontTools.pens.boundsPen import BoundsPen
        from fontTools.pens.svgPathPen import SVGPathPen
    except Exception as e:  # pragma: no cover
        raise RuntimeError(
            "Missing dependency: fontTools. Install with: pip install fonttools"
        ) from e

    font = TTFont(io.BytesIO(ttf_bytes))

    cmap = font.getBestCmap() or {}
    glyph_name = cmap.get(codepoint)
    if not glyph_name:
        available = sorted(cmap.keys())
        raise RuntimeError(
            f"Codepoint U+{codepoint:04X} not found in cmap. "
            f"Available codepoints count: {len(available)}"
        )

    glyph_set = font.getGlyphSet()
    glyph = glyph_set[glyph_name]

    bpen = BoundsPen(glyph_set)
    glyph.draw(bpen)
    if not bpen.bounds:
        raise RuntimeError("Glyph has no bounds (empty outline?)")

    xmin, ymin, xmax, ymax = bpen.bounds

    pen = SVGPathPen(glyph_set)
    glyph.draw(pen)

    path_d = pen.getCommands()
    if not path_d.strip():
        raise RuntimeError("Failed to extract SVG path commands from glyph")

    return path_d, (xmin, ymin, xmax, ymax)


def _write_svg(
    *,
    out_path: str,
    path_d: str,
    bounds: tuple[float, float, float, float],
    fg: str,
    bg: str,
    padding: float,
) -> None:
    xmin, ymin, xmax, ymax = bounds
    width = xmax - xmin
    height = ymax - ymin

    dim = max(width, height) + 2.0 * padding

    # Center glyph in a square canvas.
    x_off = (dim - width) / 2.0
    y_off = (dim - height) / 2.0

    # We want to flip the font’s y-up coordinates to SVG’s y-down coordinates.
    # Using: translate(tx, ty) scale(1, -1)
    # ...where tx shifts xmin to x_off, and ty shifts ymax to y_off.
    tx = x_off - xmin
    ty = y_off + ymax

    svg = f"""<?xml version=\"1.0\" encoding=\"UTF-8\"?>
<svg xmlns=\"http://www.w3.org/2000/svg\" width=\"{int(dim)}\" height=\"{int(dim)}\" viewBox=\"0 0 {dim:.2f} {dim:.2f}\" role=\"img\" aria-label=\"Logo (Material Symbols: emoji_language)\">
  <rect x=\"0\" y=\"0\" width=\"100%\" height=\"100%\" fill=\"{bg}\"/>
  <path d=\"{path_d}\" fill=\"{fg}\" transform=\"translate({tx:.2f} {ty:.2f}) scale(1 -1)\"/>
</svg>
"""

    with open(out_path, "w", encoding="utf-8") as f:
        f.write(svg)


def main(argv: list[str]) -> int:
    ap = argparse.ArgumentParser(description="Generate an SVG logo from a Material Symbol")
    ap.add_argument("--icon-name", default="emoji_language")
    ap.add_argument("--codepoint", default="f4cd", help="Hex codepoint (e.g. f4cd)")
    ap.add_argument("--family", default="Material+Symbols+Outlined")
    ap.add_argument("--opsz", type=int, default=48)
    ap.add_argument("--wght", type=int, default=700)
    ap.add_argument("--fill", type=int, default=0)
    ap.add_argument("--grad", type=int, default=0)
    ap.add_argument("--fg", default="#FF2D2D", help="Foreground (icon) color")
    ap.add_argument("--bg", default="#000000", help="Background color")
    ap.add_argument("--padding", type=float, default=96.0)
    ap.add_argument(
        "--out",
        default="docs/brand/logo-emoji-language-red-black.svg",
        help="Output SVG path",
    )

    args = ap.parse_args(argv)

    codepoint = int(args.codepoint, 16)

    css_url = (
        "https://fonts.googleapis.com/css2?"
        f"family={args.family}:opsz,wght,FILL,GRAD@{args.opsz},{args.wght},{args.fill},{args.grad}"
        f"&icon_names={args.icon_name}"
    )

    css = _fetch_text(css_url)
    font_url = _extract_ttf_url_from_css(css)

    ttf = _fetch_bytes(font_url)

    path_d, bounds = _glyph_svg_path_from_ttf(ttf, codepoint)

    _write_svg(
        out_path=args.out,
        path_d=path_d,
        bounds=bounds,
        fg=args.fg,
        bg=args.bg,
        padding=args.padding,
    )

    print(f"Wrote: {args.out}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
