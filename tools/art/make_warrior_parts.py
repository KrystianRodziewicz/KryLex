"""Generuje pikselowe części Wojownika do rigu "z części" (paper doll).

Uruchomienie (z katalogu projektu, bez zależności poza biblioteką standardową):
    python tools/art/make_warrior_parts.py

Każda część to mapa ASCII: jeden znak = jeden piksel, litera = kolor z PALETTE,
kropka = przezroczysty. Zmiana wyglądu to edycja mapy i ponowne uruchomienie.
Wynik trafia do assets/sprites/warrior/*.png (po imporcie Godot dopisze .import).
"""

from __future__ import annotations

import struct
import sys
import zlib
from pathlib import Path

PALETTE: dict[str, tuple[int, int, int, int]] = {
    ".": (0, 0, 0, 0),
    "o": (27, 21, 34, 255),      # kontur
    "s": (217, 167, 132, 255),   # skóra
    "S": (176, 119, 90, 255),    # skóra w cieniu
    "h": (58, 42, 34, 255),      # włosy
    "r": (138, 47, 42, 255),     # tunika
    "R": (181, 65, 58, 255),     # tunika, światło
    "l": (90, 58, 36, 255),      # skóra garbowana (pas, spodnie)
    "L": (122, 79, 48, 255),     # skóra, światło
    "b": (46, 31, 24, 255),      # buty
    "m": (201, 194, 176, 255),   # stal
    "M": (141, 138, 133, 255),   # stal w cieniu
    "w": (107, 74, 44, 255),     # drewno
    "W": (142, 106, 63, 255),    # drewno, światło
    "g": (217, 164, 65, 255),    # okucie
    "e": (27, 21, 34, 255),      # oko
    "B": (232, 228, 216, 255),   # klinga, jaśniejsza od zbroi
}

# Każda część patrzy w prawo. Rig odwraca całość przez scale.x.
PARTS: dict[str, str] = {
    # Hełm z wizurą: stal, ciemny pas wizury ze szczeliną na oko, podbródek.
    "head": """
.ooooo.
oMmmmmo
ommmmmo
ommmmmo
ohhhheo
oMmmmmo
.ooooo.
""",
    # Napierśnik ze stali, czerwona tunika herbowa, złoty pas.
    "torso": """
.oooooo.
oMmmmmMo
omrRRrmo
omrRRrmo
omrrrrmo
oMrrrrMo
olgggglo
omrrrrmo
.oooooo.
""",
    # Rękaw kolczugi i rękawica.
    "arm": """
.oo.
oMmo
oMmo
oMmo
oMmo
oMMo
.oo.
""",
    # Nagolenica z kolanem i but.
    "leg": """
.oo.
ommo
ommo
oMMo
ommo
ommo
obbo
.oo.
""",
    "sword": """
..o..
.oBo.
.oBo.
.oBo.
.oBo.
.oBo.
.oBo.
.oBo.
.omo.
ogggo
..o..
.oWo.
.oWo.
..o..
""",
    # Tarcza migdałowa 9x12: jasne okucie, czerwone pole, biały krzyż.
    "shield": """
.ooooooo.
oBmmmmmBo
omrrBrrmo
omrrBrrmo
omBBBBBmo
omrrBrrmo
omrrBrrmo
.omrBrmo.
.omrBrmo.
..omBmo..
...omo...
....o....
""",
}


def parse(part: str) -> list[str]:
    rows = [line for line in part.strip("\n").splitlines() if line]
    width = len(rows[0])
    for row in rows:
        if len(row) != width:
            raise ValueError(f"nierówna szerokość wiersza: {row!r}")
    return rows


def write_png(path: Path, rows: list[str]) -> None:
    height = len(rows)
    width = len(rows[0])
    raw = bytearray()
    for row in rows:
        raw.append(0)  # filtr "none" dla wiersza
        for ch in row:
            if ch not in PALETTE:
                raise ValueError(f"nieznany znak palety {ch!r} w {path.name}")
            raw.extend(PALETTE[ch])

    def chunk(kind: bytes, data: bytes) -> bytes:
        body = kind + data
        return struct.pack(">I", len(data)) + body + struct.pack(">I", zlib.crc32(body) & 0xFFFFFFFF)

    ihdr = struct.pack(">IIBBBBB", width, height, 8, 6, 0, 0, 0)  # 8 bit RGBA
    png = b"\x89PNG\r\n\x1a\n" + chunk(b"IHDR", ihdr) + chunk(b"IDAT", zlib.compress(bytes(raw), 9)) + chunk(b"IEND", b"")
    path.write_bytes(png)


def main() -> int:
    root = Path(__file__).resolve().parents[2]
    out_dir = root / "assets" / "sprites" / "warrior"
    out_dir.mkdir(parents=True, exist_ok=True)
    for name, art in PARTS.items():
        rows = parse(art)
        write_png(out_dir / f"{name}.png", rows)
        print(f"{name}: {len(rows[0])}x{len(rows)} px")
    return 0


if __name__ == "__main__":
    sys.exit(main())
