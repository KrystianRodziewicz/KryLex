# scenes/enemies

Właściciel: Alex.

Moby, Elita i boss prototypu, każdy jako osobna scena ze swoimi stanami (patrol, zauważenie, atak). Karty wrogów z czasownikami są w `docs/biom-1-przeklety-bor.md`.

Wrogami w sieci zarządza host, więc scena wroga nie potrzebuje własnego kodu sieciowego poza tym, co da `net/`.

Każdy wróg dziedziczy po `enemy.gd` (HP, ukryty pasek postawy, ogłuszenie, okno krytyczne, statusy żywiołowe z reakcją roztrzaskania, osłona żywiołowa, zdarzenie `enemy_killed`) i pisze własne zachowanie w `_tick_behaviour`. Ruch mnoży przez `speed_scale()` (zamrożenie), a na Przerwij reaguje w `_on_interrupted`. Liczby siedzą w `resources/balance/` (`EnemyStats` i klasy pochodne, np. `WerewolfStats`). `enemy_spawn_trigger.gd` wprowadza wroga z krawędzi ekranu po mignięciu oczu; kleszcze to dwa wyzwalacze z przeciwnymi krawędziami.

Gotowe: wilkołak (`werewolf.gd`) i Błędny Ognik (`wisp.gd` z pociskiem `spark.gd`), oba bez czasowników *Przerwij* i *Zamroź*, które jeszcze nie istnieją u graczy. Ognik patrzy na jednego gracza naraz i cofa się w stronę `lure_x` (rozpadlina, gałąź ze strzygą), a z daleka rzuca iskrą z podpaleniem. Kukła `training_dummy` to pomoc testowa, nie wróg.
