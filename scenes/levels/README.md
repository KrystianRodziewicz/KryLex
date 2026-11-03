# scenes/levels

Właściciel: Alex.

Pomieszczenia i biomy: na start graybox pierwszego pomieszczenia z `docs/biom-1-przeklety-bor.md`, czyli szare prostokąty, bez grafiki. Każde pomieszczenie to osobna scena z `room.gd` na korzeniu (konwencja węzłów: `Geometry`, `Props`, `Exits`, `Spawns`).

Dziś prostokąty to instancje `graybox/graybox_block.tscn` (pozycja plus `size`, lewy górny róg jako początek układu), bo da się je czytać i poprawiać w pliku `.tscn` bez tilesetu. Gdy powstanie pierwszy tileset, geometria przechodzi na `TileMapLayer`, a bloki zostają do szybkich szkiców. Wyjścia to `room_exit.tscn`: domyślnie czekają na oboje graczy (ogólna zasada przejść z dokumentu bioma).

Ściany boczne pomieszczenia leżą na warstwie `bounds` (tylko gracze się z nimi zderzają), bo wrogowie Boru wbiegają spoza ekranu; w pomieszczeniu trzyma ich `Room.bounds`. Podłoga przy krawędzi, z której wbiega wróg, musi wychodzić poza ekran (S2: `FloorLeft` od x = -96).

Gotowe: `osada.tscn`, `s1_za_plotem.tscn`, `s2_porzucony_woz.tscn` (wilkołak z `EnemySpawnTrigger`, dźwignia na dwóch, krata do S3). Następne: `s3_rozstaje` (kleszcze: dwa wilki z przeciwnych krawędzi, ognik, rozpadlina).

Zmiany w tych plikach robi Alex, Krystian zgłasza potrzeby w PR albo na callu.
