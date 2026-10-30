**Podstawowe informacje i organizacja**

* Projekt utrzymany w stylistyce pixel art z kampanią fabularną zaplanowaną na około 10 godzin rozgrywki.
* Podział obowiązków: Krystian odpowiada za architekturę sieciową i tryb online, Alex za design i mechaniki (przy ogólnej współpracy).
* Rygorystyczny przepływ pracy w Git: Każda funkcja, mechanika, projekt mapy i postaci musi być tworzona na osobnym branchu, a dopiero potem łączona z całością.

**Świat, Eksploracja i NPC**

* Jedna rozległa mapa z kilkoma lokacjami i wertykalnymi poziomami (warstwy głębi przypominające strukturę z Tibii).
* System świata jako baza danych SQL, w której zapisywane są wszystkie zabójstwa, śmierci i rozmowy, co wpływa na stan gry.
* Minimum 20 proceduralnie generowanych, wędrujących NPC, którzy dynamicznie reagują na historię poczynań gracza.
* Eksplorację urozmaica mechanika latarni oraz możliwość wykorzystywania elementów otoczenia do walki.

**Klasy, Rozwój i Ekwipunek**

* Gra zaoferuje 4 grywalnych klas postaci na start.
* Broń i pancerze dedykowane konkretnym klasom będą poukrywane i rozrzucone po różnych rejonach mapy.
* System "Ślubów": gracz zyskuje bardzo potężną zdolność, ale musi zaakceptować przypisane do niej poważne ograniczenie.
* Złożone skalowanie matematyczne statystyk broni i zbroi, aby precyzyjnie balansować siłę postaci względem poziomu wrogów.
* Zaimplementowany system zużywania się ekwipunku oraz mechanika rzucania bronią w walce.

**Walka, Bossowie i Przeciwnicy**

* Przeciwnicy inspirowani słowiańskim bestiariuszem, projektowani w ścisłym powiązaniu z biomami mapy oraz fabułą.
* Zaawansowane AI wrogów: zapamiętują ataki najczęściej zabijające gracza, a wróg, który pokona postać, automatycznie awansuje.
* Adaptacyjni bossowie, którzy stają się trudniejsi po śmierci gracza (jednocześnie gra ułatwia wtedy zbieranie doświadczenia w okolicy).

**Mechaniki Kooperacji (Online)**

* Ścisła współpraca wymuszona wspólną, pojedynczą flaszką leczenia dzieloną między dwóch graczy.
* Możliwość wyprowadzania potężnych, wspólnych ataków z partnerem.
* Wbudowany system gestów i pingów do szybkiej komunikacji taktycznej podczas walki.
