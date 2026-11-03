# scenes/levels

Właściciel: Alex.

Pomieszczenia i biomy: na start graybox pierwszego pomieszczenia z `docs/biom-1-przeklety-bor.md`, czyli szare prostokąty, bez grafiki. Każde pomieszczenie to osobna scena z `room.gd` na korzeniu (konwencja węzłów: `Geometry`, `Props`, `Exits`, `Spawns`).

Dziś prostokąty to instancje `graybox/graybox_block.tscn` (pozycja plus `size`, lewy górny róg jako początek układu), bo da się je czytać i poprawiać w pliku `.tscn` bez tilesetu. Gdy powstanie pierwszy tileset, geometria przechodzi na `TileMapLayer`, a bloki zostają do szybkich szkiców. Wyjścia to `room_exit.tscn`: domyślnie czekają na oboje graczy (ogólna zasada przejść z dokumentu bioma).

Gotowe: `osada.tscn`, `s1_za_plotem.tscn`. Następne: `s2_porzucony_woz` (pierwszy wilkołak, dźwignia na dwóch).

Zmiany w tych plikach robi Alex, Krystian zgłasza potrzeby w PR albo na callu.
