# scenes/levels

Właściciel: Alex.

Pomieszczenia i biomy: na start graybox pierwszego pomieszczenia z `docs/biom-1-przeklety-bor.md`, czyli szare prostokąty, bez grafiki. Każde pomieszczenie to osobna scena z `room.gd` na korzeniu (konwencja węzłów: `Geometry`, `Props`, `Exits`, `Spawns`).

Dziś prostokąty to instancje `graybox/graybox_block.tscn` (pozycja plus `size`, lewy górny róg jako początek układu), bo da się je czytać i poprawiać w pliku `.tscn` bez tilesetu. Gdy powstanie pierwszy tileset, geometria przechodzi na `TileMapLayer`, a bloki zostają do szybkich szkiców. Wyjścia to `room_exit.tscn`: domyślnie czekają na oboje graczy (ogólna zasada przejść z dokumentu bioma).

Ściany boczne pomieszczenia leżą na warstwie `bounds` (tylko gracze się z nimi zderzają), bo wrogowie Boru wbiegają spoza ekranu; w pomieszczeniu trzyma ich `Room.bounds`. Podłoga przy krawędzi, z której wbiega wróg, musi wychodzić poza ekran (S2: `FloorLeft` od x = -96).

Nad rozpadliną w S3 leży niewidoczny blok na warstwie `enemy_floor` (tylko wrogowie się z nim zderzają): wilki szarżują nad przepaścią, a gracze w nią wpadają. Każda następna przepaść, przez którą mają biegać wrogowie, dostaje taki sam most.

Gotowe: `osada.tscn`, `s1_za_plotem.tscn`, `s2_porzucony_woz.tscn` (wilkołak z `EnemySpawnTrigger`, dźwignia na dwóch, krata do S3), `s3_rozstaje.tscn` (kleszcze dwóch wilków, ognik wabiący nad rozpadlinę, dwa zejścia do G1). Następne: `g1_pod_koronami` (dwie strzygi nad ścieżką, ukryte przejście do G2, wejścia `from_s3_main` i `from_s3_crevasse`).

Zmiany w tych plikach robi Alex, Krystian zgłasza potrzeby w PR albo na callu.
