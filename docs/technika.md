# Technika: sieć, baza danych i testy

Notatki techniczne do README, obszar Krystiana. Numery sekcji w tekście odnoszą się do README. Propozycje do ustalenia razem, punkty już ustalone są tak oznaczone.

## Kolejność prac w M0

> **Propozycja:** kolejność prac w M0.
> 1. Dwie postacie w jednym procesie, bez sieci: jedna na klawiaturze, druga na padzie. Tak sprawdzamy sterowanie obu postaci, zanim dojdzie sieć.
> 2. To samo przez localhost: dwie instancje z edytora (`Debug > Customize Run Instances`), jedna startuje jako host, druga jako klient (argument uruchomienia albo feature tag). Klawiatura trafia tylko do aktywnego okna, a pad w 4.7 do obu, więc każda instancja czyta tylko swoje urządzenie (`InputEvent.device`).
> 3. Potem wspólna flaszka i log do SQLite. Obie instancje mają ten sam folder `user://`, więc każda dostaje własną nazwę profilu w ścieżce zapisu, a bazę otwiera tylko host.
> 4. Od pierwszego buildu sieciowego testujemy ze sztucznym opóźnieniem: ok. 80 do 150 ms w obie strony (RTT) i 1 do 2% utraty pakietów. Godot 4.7 nie ma wbudowanego symulatora. Na Windowsie jest clumsy, uruchamiany jako administrator, z presetem `localhost ipv4 udp`. Jego opóźnienie działa w obu kierunkach, więc ustawiamy połowę RTT. Druga opcja to `NetworkSimulator` z netfox.extras, gdzie `latency_ms` też liczy się w jedną stronę.

## Git w projekcie Godota

- Projekt zakładamy w Project Managerze z włączonymi metadanymi Git. Godot sam zapisze `.gitignore` i `.gitattributes`, który wymusza końce linii LF.
- Do repo idą pliki `.import` z ustawieniami importu oraz pliki `.uid`, które Godot od 4.4 tworzy dla skryptów i shaderów. Ignorujemy `.godot/` (cache) i folder eksportu.
- Pliku SQLite nie trzymamy w repo. Żywa baza leży w `user://`, a `.gitignore` pomija `*.db`, `*.db-journal`, `*.db-wal` i `*.db-shm`. W repo trzymamy schemat jako tekst `.sql`, dodany do filtra eksportu plików niebędących zasobami, bo inaczej nie trafi do buildu.
- Jedna scena, jeden właściciel. Sceny są cienkie, np. gracz to scena główna z podscenami walki, sieci i grafiki. Liczby do strojenia siedzą w plikach `.tres`, więc balans nie rusza sceny. Przy konflikcie w `.tscn` bierzemy jedną wersję w całości, a drugą zmianę robimy jeszcze raz w edytorze.
- `project.godot` (akcje wejścia, autoloady, nazwy warstw kolizji) zmieniamy tylko w małych, osobnych pull requestach.
- Pliki przenosimy i zmieniamy im nazwy tylko w docku FileSystem w Godocie, bo przeniesienie w Eksploratorze albo w IDE bez `.uid` i `.import` psuje referencje. Nazwy od początku w snake_case: Git na Windowsie nie widzi zmiany samej wielkości liter, a wyeksportowana gra ją rozróżnia.
- **Do ustalenia:** Git LFS, zanim pierwszy asset trafi do repo, bo LFS ustawia się przed commitem plików. Opcja A: LFS dla grafik i dźwięków od razu, jak w tabeli decyzji technicznych w README. Opcja B: w grze 2D na start bez LFS. GitHub Free daje 10 GiB miejsca na LFS i 10 GiB transferu miesięcznie.
- Do `main` wchodzi krótki pull request, który sprawdza druga osoba. Zmianę nazwy albo przeniesienie węzła w scenie sieciowej opisujemy w PR, bo RPC trafia tylko do węzła z tym samym `NodePath` u obu graczy.
- Osobiste gałęzie `alex-branch` i `krystian-branch` mogą zostać obok gałęzi `feature/`, `fix/` i `art/`.

## Model Sieci (ustalone: opcja A)

**Ustalone:** host, czyli prowadzący gracz, decyduje o wszystkim, a klient wysyła tylko input. Opcje B i C zostają w tabeli jako plan B, gdyby w testach przez internet parowanie gościa okazało się za bardzo opóźnione.

| Opcja | Kto o czym decyduje | Co zyskujemy | Co tracimy |
|---|---|---|---|
| **A. Host decyduje o wszystkim** (ustalone) | Klient wysyła input, host liczy walkę i odsyła stan. | Jeden sędzia, prościej szukać błędów. | Parowanie i unik gościa host ocenia na starych danych. Przy RTT 40 ms i buforze interpolacji 70 do 100 ms to ok. 110 do 140 ms, czyli 7 do 8 klatek przy 60 fps. Bez predykcji unik gościa rusza dopiero po pełnym round tripie. |
| **B. Jak A, ale na netfox** | Pełny host authority na dodatku netfox (licencja MIT): synchronizacja czasu, predykcja, rollback. | Jeden sędzia, a gość ma predykcję i wspólny zegar. | Dużo nauki, pewnie zajmie nam pierwsze miesiące. |
| **C. Każdy decyduje o swojej postaci** | Maszyna gracza: ruch, unik, parowanie, otrzymane obrażenia. Host: wrogowie, flaszka, log i świat, do tego rozstrzyga spory. | Parowanie działa od razu u obu graczy. | Brak ochrony przed oszukiwaniem (między nami bez znaczenia). Ruch wroga, który zależy od trafienia gościa, dostaje odpowiedź z opóźnieniem. |

- Wbudowane node'y multiplayer w Godocie nie mają predykcji, rollbacku ani lag compensation, a `MultiplayerAPI` nie ma wspólnego zegara. Brak zegara dotyczy też Ataku Zgranego (szczegóły w sekcji 5). W opcji B zegar daje netfox.
- `Engine.time_scale` jest globalny dla całej uruchomionej gry. Spowalnia `Timer`, `SceneTreeTimer` i wszystko, co korzysta z `delta`, więc hit-stop zrobiony w ten sposób zatrzymuje też wszystkich wrogów, a w opcji A także postać gościa.
- `MultiplayerSynchronizer` wysyła snapshoty, czyli tylko najnowszą wartość, i nigdy nie interpoluje. Błysk parowania, który zacznie się i skończy między dwiema wysyłkami, w ogóle nie dotrze do partnera.

> **Propozycja:** hit-stop osobno dla każdej postaci. Na 3 do 6 klatek tylko atakujący i cel dostają `speed_scale` równe 0 w `AnimationPlayer` albo `AnimatedSprite2D`, do tego pauzę ruchu i timerów stanu. Długość zamrożenia przychodzi w zdarzeniu trafienia. Każde cięcie liczy trafienie raz, bo zamrożona animacja wydłuża aktywne klatki hitboxa.
>
> **Propozycja:** pozycja, prędkość i kierunek idą przez synchronizer ze stałym `replication_interval` (np. 1/30 s) i małym własnym buforem, który rysuje zdalne postacie parę interwałów w przeszłości. Fakty (atak zaczęty, trafienie, parowanie, użycie flaszki, śmierć) idą jako zdarzenia RPC w trybie reliable, każde z id. Każdy atak wroga też ma id, żeby zgłoszenie mogło go wskazać, a spóźnione dało się odrzucić.
>
> **Do sprawdzenia w testach (z kartami Alexa):** szarża wilkołaka (trafił albo chybił) i *Uchwyt* Niedźwiedzia zależą od trafienia gościa. W opcji A host wie od razu, ale unik gościa ocenia na starych danych, więc okno uniku u gościa może wymagać tolerancji o jeden RTT. Gdybyśmy przeszli na opcję C, odpowiedź gościa dociera do hosta z opóźnieniem, więc taki ruch potrzebuje krótkiej pauzy przed rozgałęzieniem.

## Kto Czym Zarządza

Propozycja tabeli dla mechanik z sekcji 3 do 5, uzupełniona pod opcję A (host decyduje o wszystkim).

| Stan | Właściciel | Jak idzie przez sieć | Zapis |
|---|---|---|---|
| Trafienie we wroga | Host (opcja A) | Zdarzenie: kto, który wróg (ścieżka node'a), który cios, obrażenia. Przy hoście: atak jako zdarzenie, potwierdzenie wraca do obu | Nie |
| HP i pasek postawy wroga | Host | Właściwości `ON_CHANGE` (reliable, tylko przy zmianie). Złamanie postawy jako zdarzenie, śmierć jako despawn przez `MultiplayerSpawner` hosta | Nie, poza listą pokonanych bossów i Nemesis |
| Ładunki flaszki | Host zatwierdza (sekcja 5) | Prośba, zgoda i odmowa jako zdarzenia, licznik jako `ON_CHANGE`. Animacja picia rusza od razu i cofa się po odmowie | Przy kapliczce i tak się odnawia. Bieżącą liczbę tylko wtedy, gdy da się wyjść z gry poza kapliczką |
| Zasób współpracy Maga | Host (jeden licznik dla dwóch osób, jak flaszka) | +1 z każdego zdarzenia trafienia Wojownika. Wydanie jako prośba do hosta, animacja zaklęcia rusza od razu i cofa się po odmowie | Nie |
| Pasek Ataku Zgranego | Host | Pasek jako `ON_CHANGE`. Wciśnięcia jako zdarzenia ze znacznikiem czasu, wynik jako zdarzenie od hosta | Nie |
| Statusy żywiołowe | Host | Nałożenie jako zdarzenie z czasem trwania, każda maszyna sama odlicza. Reakcję rozstrzyga tylko host, więc roztrzaskanie odpala się raz | Nie |
| Duch i wskrzeszenie | Host ogłasza każdą śmierć, także śmierć obojga, bo widzi oboje | Śmierć i wskrzeszenie jako zdarzenia, postęp wskrzeszania jako `ON_CHANGE` | Wiersz `player_death` w `events` |
| Kurhany | Host | Nowy kurhan jako zdarzenie. Pełna lista jednym RPC, gdy gość dołącza (słownik przejdzie jako argument, obiekty nie) | Wyliczane z wierszy `player_death` |
| Rekord Nemesis (elita z sekcji 4 albo, do ustalenia, każdy mob jak w pierwszym pomyśle Krystiana) | Host | Awansowany wróg spawnuje się jak każdy inny, a imię, ranga i wygląd idą jako właściwości przy spawnie | W SQLite, jeśli sesja to całe przejście. Tylko w pamięci, jeśli jeden wieczór |
| Nauczone ruchy bossa | Host | Nic nowego: nauczony atak to zwykły stan animacji bossa | Do ustalenia: trwałe albo reset po wyjściu z gry |
| Pingi | Maszyna wysyłającego | RPC reliable (domyślne w 4.7) z `any_peer` i `call_local`, więc wysyłający widzi ping od razu. Ping na wrogu niesie jego ścieżkę node'a, bo RPC nie wyśle samego node'a | Nie |
| Log zdarzeń (`events`) | Host, tylko on pisze do bazy | Zdarzenia gościa lecą do hosta, host je zapisuje | Tak, wsadowo w spokojnych chwilach (np. przy kapliczce) |
| Plik zapisu | Dysk hosta | Nie jest wysyłany w trakcie gry | Jeden plik SQLite w `user://` |

## Rozdzielanie się w poziomie

> **Do ustalenia:** jak daleko gracze mogą się rozejść przy rozwidleniu. Biom 1 zakłada dziś wspólne pomieszczenie: scena zmienia się obojgu, gdy oboje dotkną wyjścia albo gdy jeden skoczy do Matecznika. Opcje:
> 1. Tylko wspólne pomieszczenie, jak teraz. Rozwidlenie mieści się w jednym pomieszczeniu albo obie drogi kończą się w tym samym.
> 2. Smycz: można odejść od partnera najwyżej o jedno pomieszczenie. Strzałka partnera z sekcji 5 pokazuje drogę, a następne wyjście czeka na drugiego.
> 3. Swobodnie, bez limitu.
>
> Opcje 2 i 3 oznaczają, że host prowadzi dwa pomieszczenia naraz, każde z własnymi wrogami (szczegóły w sekcji 6).

Sekcja 2 ma rozwidlenia, na których gracze się rozdzielają, a sekcja 5 osobne kamery. W obrębie jednego pomieszczenia to tanie, bo host i tak je liczy. Drożej robi się, gdy gracze są w dwóch pomieszczeniach naraz, bo wtedy host musi liczyć oba.

- RPC i synchronizatory szukają node'ów po ścieżce, więc oba komputery muszą mieć pomieszczenie pod tą samą ścieżką. `change_scene_to_file` podmienia scenę tylko lokalnie. Starą od razu wyjmuje z drzewa, a pod koniec klatki zwalnia ją razem ze wszystkim pod nią, więc słabo pasuje do świata, który ma trwać.

> **Propozycja A: reguła jednego pomieszczenia.** Zgadza się z dokumentem bioma (nowa scena ładuje się, gdy oboje dotkną wyjścia). Drzwi czekają na oboje albo po krótkim odliczaniu przeciągają partnera, a rozwidlenia zostają w obrębie pomieszczenia. Host podmienia pomieszczenie przez `MultiplayerSpawner` ze `spawn_limit` równym 1. Do ustalenia: rozpadlina w S3 i skok w K2 (gracze lądują w arenie w różnych momentach) albo przenoszą partnera razem, albo na chwilę wymagają dwóch pomieszczeń u hosta.
>
> **Propozycja B: swobodne rozdzielanie.** Sceny pomieszczeń jako dzieci jednej stałej sceny świata, która trzyma graczy i sieć. `MultiplayerSpawner` replikuje tylko bezpośrednie dzieci swojej ścieżki spawnu, zarejestrowane jako spawnowalne sceny. Każde pomieszczenie ma synchronizator z widocznością per peer (`set_visibility_for()`, `add_visibility_filter()`), więc gość dostaje tylko swoje. Wszystkie dzielą jedną przestrzeń fizyki (`World2D`), więc leżą w różnych miejscach jednej siatki świata, żeby na siebie nie wpływały. Druga droga: każde w osobnym `SubViewport`, który ma własny `World2D`. To rzadszy układ, więc najpierw mały prototyp. Ta opcja jest najbliższa pierwszemu pomysłowi Krystiana z jedną dużą mapą.

## Jedno zdarzenie śmierci

> **Propozycja:** jedno zdarzenie śmierci, z którego czytają wszystkie systemy. To może być wiersz `player_death` z tabeli `events` w `docs/npc-guslarz.md`: obok gracza, miejsca, czasu i zabójcy dochodzi rodzaj zabójcy (mob, Elita, boss, otoczenie, upadek, partner), id konkretnego wroga i ruch, którym zabił. Do tego mała tabela: który system reaguje na którą śmierć (kurhan, Nemesis, nauka bossa, przeciwwaga areny, kwestie Guślarza), najwyżej jedna lub dwie reakcje na przypadek. Przykład: śmierć od Elity to kurhan i awans, a śmierć obojga u bossa to kurhan i albo nauka bossa, albo ułatwienie areny, nie oba naraz. Wtedy jedna śmierć nie pociąga pięciu dźwigni naraz. Przy okazji do ustalenia: czy śmierć obojga w jednej walce liczy się raz, czy dwa razy.

## Tabela reguł świata

> **Propozycja:** jedna tabela reguł świata, z której czytają oba kanały, a później też Nemesis i przeciwwaga po porażce z sekcji 4. Każda reguła ma wyzwalacz, zakres (pomieszczenie, biom, cały świat), warunek, efekt, znak, który oboje widzą albo słyszą, i częstotliwość (raz, zawsze, raz na odpoczynek). Tabela Guślarza z `docs/npc-guslarz.md` ma już ten kształt, więc może być pierwszym blokiem. Przykład:
>
> | Wyzwalacz | Zakres | Warunek | Efekt | Znak dla obojga | Ile razy |
> |---|---|---|---|---|---|
> | śmierć gracza | pomieszczenie (miejsce śmierci) | brak | kurhan pojawia się albo rośnie | kopiec | zawsze |
> | pojawienie się przy kapliczce 1 | biom 1 | śmierci w Borze ≥ 3 | kwestia nr 4 Guślarza | sama kwestia | raz |
>
> Zmiany, które ruszają rozgrywkę (przejścia, ceny, wrogowie), wchodzą przy kapliczce albo przy wejściu do obszaru, nie w środku walki. Od razu mogą wchodzić tylko znaki, jak kurhan, i duże momenty, jak śmierć bossa. Zmiana, której gracze nie zobaczą, jest zmarnowana.
>
> Pierwsza wersja Krystiana (spawn rate wrogów i dostępność ukrytych przejść zmieniane w czasie rzeczywistym) może zostać opcją na później. Ryzyko: jeśli śmierci podnoszą zagrożenie, para, która sobie nie radzi, dostaje trudniejszy obszar, ginie częściej i robi go jeszcze trudniejszym.
>
> Jeśli tabela trafi do pliku `.csv`, ten plik potrzebuje w Godocie typu importu `Keep File (exported as is)`, bo domyślnie każdy `.csv` importuje się jako tłumaczenie.

## Wspólny zegar dla Ataku Zgranego

> **Uwaga:** żeby host mógł porównać znaczniki czasu wciśnięć, obie maszyny potrzebują wspólnego zegara, a `MultiplayerAPI` w Godocie go nie ma. Każdy komputer liczy czas po swojemu, więc goły znacznik z klienta hostowi nic nie mówi. Dwie instancje na jednym PC dzielą zegar, więc ten problem wyjdzie dopiero w grze z dwóch domów.
>
> **Do ustalenia:** jak liczymy to okno. Opcje 1 i 2 zostają przy znacznikach czasu z uwagi wyżej, opcja 3 z nich rezygnuje.
> 1. Sami szacujemy przesunięcie zegarów pingiem RPC ze znacznikami czasu, a statystyka `PEER_ROUND_TRIP_TIME` z `ENetPacketPeer` służy do kontroli.
> 2. Bierzemy gotową synchronizację czasu z addonu netfox (MIT). To dodatkowa zależność.
> 3. Host mierzy okno w chwili odbioru wciśnięć i dodaje tolerancję ok. jednego RTT (między domami zwykle kilkadziesiąt ms, na Wi-Fi bywa ponad 100 ms). Najmniej kodu, a okno po prostu trochę rośnie.

## Pingi w sieci

> **Uwaga:** w sieci ping to pojedyncze zdarzenie, a nie stan. Najprościej wysłać go jednym RPC w trybie `any_peer` (klient może je wywołać) z `call_local` (wysyłający widzi swój ping od razu, partner chwilę później). W Godocie 4.7 RPC jest domyślnie niezawodne (reliable), więc ping nie zginie po drodze. RPC nie wyśle samego węzła, dlatego ping na wrogu niesie coś, co znają obie maszyny, np. ścieżkę węzła wroga, którą i tak muszą mieć zgodną. Znacznik przesuwa się wtedy razem z wrogiem.
>
> **Do ustalenia:**
> 1. Numery pingowanych wrogów. Przez `call_local` każdy widzi swój ping pierwszy, więc przy dwóch pingach w tej samej chwili numery mogą się zamienić między ekranami. Opcje: osobna numeracja dla każdego gracza, w jego kolorze, albo numery nadaje host (wtedy własny numer widać po jednym RTT).
> 2. Limit przeciw spamowi i po ilu sekundach ping znika.
> 3. Gesty z koła na start jako ikony albo dymki nad postacią, bo każdy animowany gest to nowe klatki pixel artu dla każdej klasy. Opcje: zostają ikony na stałe albo animacje później.

## Rozłączenie i łączenie

> **Uwaga:** gdy partnerowi padnie gra albo internet, ENet zgłosi to dopiero po swoim domyślnym timeoucie, od 5 do 30 s. Do tego czasu jego postać stoi zamrożona w walce i może zginąć.
>
> **Propozycja:**
> 1. Komunikat „partner traci połączenie" po sekundzie lub dwóch bez pakietów, na obu ekranach. Host wtedy od razu pauzuje, bez czekania na ENet. Timeouty da się skrócić przez `ENetPacketPeer.set_timeout` (wartości w ms, peer z `ENetMultiplayerPeer.get_peer(id)`). W buildach debug odwrotnie: dłuższe timeouty po obu stronach, żeby breakpoint nie zrywał połączenia.
> 2. Rozłączenie nigdy nie jest śmiercią: bez kurhanu, bez awansu wroga, bez nauki bossa i bez zdarzenia `player_death`, które zlicza Guślarz. Osobną ścieżkę dają sygnały `peer_disconnected` (u hosta) i `server_disconnected` (u klienta), a w logu ląduje np. `session_aborted`.
> 3. Przy łączeniu sprawdzamy, czy oboje mają ten sam build. RPC leci jako numer na posortowanej liście metod węzła, więc jedno dodane albo przemianowane RPC po jednej stronie może odpalić inną funkcję, a Godot tylko wypisuje błąd w konsoli i działa dalej. `SceneMultiplayer` ma na to krok uwierzytelniania: `auth_callback`, ID buildu przez `send_auth`, `complete_auth` tylko przy zgodności. `peer_connected` przychodzi dopiero potem.
>
> **Do ustalenia:** skąd ID buildu (stała `PROTOCOL` podbijana ręcznie albo commit z gita) i czy na wspólne sesje oboje bierzemy ten sam commit.

## Baza Danych (SQLite)

- **Dodatek:** Godot nie ma wbudowanego SQLite, więc zostaje godot-sqlite. Obecne v4.9 (9 sierpnia 2026) jest zbudowane pod Godot 4.7.1 z SQLite 3.51.0. W pre-release jest już v5 z innym API (`SQLiteConnection` zamiast `SQLite`, bez `open_db()`, `close_db()` i `query_result`). To kierunek, nie pilna zmiana. **Propozycja:** cały SQL w jednym autoloadzie (np. `WorldStore`) z metodami nazwanymi od czynności (`record_kill`, `open_door`). Zmiana dodatku dotknie wtedy jednego pliku.
- **Gdzie leży plik:** w `user://`, bo `res://` w wyeksportowanej grze jest tylko do odczytu. Do `.gitignore` idą `*.db`, `*.db-journal`, `*.db-wal` i `*.db-shm`.
- **Ustawienia przy otwarciu:** addon otwiera bazę z rollback journal, `synchronous` FULL i bez busy timeout. **Propozycja:** WAL, `synchronous` na NORMAL i busy timeout. WAL zostaje w pliku, a dwa pozostałe resetują się przy każdym otwarciu, więc idą do funkcji otwierającej bazę.
- **Kiedy pisać:** każdy zapis poza transakcją czeka na dysk na głównym wątku, a przestój hosta czują oboje gracze. **Propozycja:** zdarzenia zbierane w pamięci i commitowane jedną transakcją przy kapliczce, zmianie pomieszczenia, końcu walki z bossem, w menu albo przy wyjściu. Nie w środku walki, a śmierć jednego gracza to nie pauza dla drugiego.
- **Pułapka dodatku:** `insert_rows`, `update_rows` i `delete_rows` same robią BEGIN i END. Wywołane w naszej transakcji commitują ją za wcześnie i nie robią rollbacku. W transakcji tylko `query()` albo `query_with_bindings()`.
- **Stałe id:** `get_instance_id()` jest ważne tylko w bieżącej sesji, a ścieżka node'a zmienia się, gdy go przeniesiemy albo zmienimy mu nazwę. **Propozycja:** tekstowe id w eksportowanej właściwości dla drzwi, dźwigni, NPC, kapliczek i pomieszczeń, w stylu, którego Alex już używa (`shrine_2`, `leszy`, `guslarz`). Ctrl+D kopiuje też id, więc w buildzie debug przy ładowaniu poziomu sprawdzamy puste i powtórzone id.
- **Wersje schematu:** bez numeru wersji każda zmiana schematu psuje stare zapisy. **Propozycja:** numer w `PRAGMA user_version`, zmiany jako ponumerowane migracje `.sql` stosowane po kolei przy otwarciu zapisu. `*.sql` trzeba dodać do filtra eksportu, bo Godot nie traktuje tych plików jako zasobów.
- **JSON:** parser Godota zwraca każdą liczbę jako float, a `1` i `1.0` to różne klucze w `Dictionary`. **Propozycja:** to, po czym gra filtruje albo liczy, dostaje osobną kolumnę z typem.
- **DataGrip:** przy domyślnym journalu blokada odczytu z DataGrip sprawia, że następny commit gry od razu dostaje `SQLITE_BUSY`. `query()` zwraca wtedy false i zdarzenie przepada, jeśli kod nie sprawdza wyniku. **Propozycja:** żywy plik tylko jako kopia albo, przy włączonym WAL, w trybie read-only, a autoload sprawdza każdą zwracaną wartość.

> **Propozycja:** startujemy od dwóch tabel z `docs/npc-guslarz.md` (`events`, `npc_lines_said`) i dokładamy tabele dopiero wtedy, gdy potrzebuje ich konkretna funkcja. Jedna drobna uwaga: kurhan stoi w miejscu śmierci, a `events` ma tylko `biome` i `room`, więc przydadzą się kolumny `x` i `y`.

## Zapis Świata i Zmiana Hosta

Sekcja 1 trzyma świat w SQLite u hosta i nazywa bazę „per sesja”. Trzy rzeczy zostają otwarte.

> **Do ustalenia: co znaczy sesja.** Jeden wieczór: co wieczór nowa baza, więc kurhany, liczniki śmierci dla Guślarza i Nemesis znikają po wyjściu z gry. Całe przejście: jeden plik świata na parę, który rośnie z każdym wieczorem.
>
> **Do ustalenia: kto hostuje.** Jeśli hostujemy na zmianę, robią się dwa światy, każdy z własnymi kurhanami i logiem. Opcje:
> 1. Jeden stały host dla danego świata.
> 2. Plik zapisu wędruje z hostem. Kopiujemy go tylko przy zamkniętej grze albo jako snapshot przez `VACUUM INTO` (spójna kopia otwartej bazy) i ustalamy, która kopia wygrywa. Nigdy kopia otwartego pliku ani folder synchronizowany z chmurą: plik WAL to część stanu i oddzielony od bazy może zgubić transakcje albo ją uszkodzić.
>
> **Do ustalenia: gdzie żyje postać gościa** (klasa, Ślub, sprzęt, exp). W zapisie świata razem z postacią hosta: prosto i pasuje do stałej pary. Albo w pliku postaci, który gość przynosi: zagra z każdym partnerem, ale przekazania między dwoma plikami na dwóch PC nie mają wspólnej transakcji, więc przy awarii coś może zniknąć albo się podwoić.

## Łączenie przez Internet

- High-level multiplayer w Godocie (ENet) używa tylko UDP. Przez internet host zwykle musi przekierować port UDP na routerze. Klasa `UPNP` może spróbować zrobić to sama, ale jej wywołania blokują (osobny `Thread`), a nie każdy router ma UPnP włączone.
- Jeśli adres WAN routera hosta leży w `100.64.0.0/10` (albo innym prywatnym zakresie), dostawca ma carrier-grade NAT i przekierowanie na naszym routerze nic nie da.
- ENet zgłasza zerwanie dopiero po swoim timeoucie, domyślnie od 5 do 30 s. Co z tym zrobić, opisuje sekcja 5 (Rozłączenie).

> **Propozycja:** na czas prac Tailscale albo ZeroTier, oba darmowe do użytku prywatnego, niekomercyjnego. Instalacja na obu PC, host podaje adres z sieci nakładkowej i nie trzeba pisać żadnego kodu. Gdy Tailscale nie zestawi bezpośredniej ścieżki, puszcza ruch przez relay z większym opóźnieniem (`tailscale ping` pokaże wtedy „via DERP”). GodotSteam dopiero przy ewentualnym wydaniu na Steam: wymaga uruchomionego Steama i testowego app ID 480, a Steam Direct to 100 USD za grę.
>
> **Propozycja:** całe zestawianie połączenia w jednym skrypcie, który tworzy `MultiplayerPeer` i ustawia `multiplayer.multiplayer_peer`. Wywołania ENet zostają poza kodem rozgrywki, więc późniejsza zmiana na Steam dotknie głównie tego pliku. Ten skrypt może też sprawdzać wersję gry przy łączeniu (sekcja 5, Rozłączenie).

## Testowanie we Dwóch

Propozycja zestawu, żeby jedna osoba mogła testować co-op bez partnera:

- `Debug > Customize Run Instances` (od Godota 4.3) uruchamia kilka instancji naraz, każdą z własnymi argumentami i feature tagami. Argumenty: host albo join, urządzenie wejścia i nazwa profilu. Gra czyta argumenty użytkownika przez `OS.get_cmdline_user_args()`, a tagi przez `OS.has_feature()`, i pomija menu. Jedno Run daje wtedy od razu połączoną sesję.
- Obie instancje mają domyślnie ten sam folder `user://`, więc otworzyłyby ten sam plik świata. Każda dostaje podfolder nazwany od profilu (Godot nie ma na to przełącznika, folder wybiera gra). Bazę otwiera tylko host, gość dostaje stan wyłącznie przez sieć.
- W 4.7 pad trafia domyślnie do każdej uruchomionej instancji (`input_devices/joypads/ignore_joypad_on_unfocused_application` jest wyłączone). Każda instancja czyta więc tylko swoje urządzenie (`InputEvent.device`, klawiatura to `DEVICE_ID_KEYBOARD`).
- Zastępczy partner: stojący manekin, bot chodzący za graczem albo nagrane wejścia. Wystarczy, żeby jedna osoba sprawdziła flaszkę, ducha i wskrzeszenie, dźwignię na dwóch w S2 i *Uchwyt*.
- Godot nie ma symulatora opóźnień. Na Windowsie jest clumsy, uruchamiany jako administrator, z presetem „localhost ipv4 udp”. Opóźnienie działa w nim w obie strony, więc wartość Lag liczy się do RTT podwójnie. Druga droga to `NetworkSimulator` z netfox.extras: `latency_ms` to opóźnienie w jedną stronę, a symulator działa tylko przy uruchomieniu z edytora. Rozsądny zestaw przy pracy nad walką: 80 ms RTT i 1 do 2% utraty pakietów.
- Nakładka debug pod jednym klawiszem: liczniki, flagi, ostatnie zdarzenia z logu, pamięć wroga i który warunek Guślarza jest teraz spełniony. Do tego komendy, które ustawiają licznik albo flagę.
- Instancja zatrzymana na breakpoincie przestaje obsługiwać połączenie, więc druga zrywa je po timeoucie ENet. W buildach debug można ten timeout podnieść przez `ENetPacketPeer.set_timeout()`.
- Cotygodniowy test z sekcji 1 najlepiej z dwóch domów: dwa okna na jednym PC mają wspólny zegar, wspólny procesor i prawie zerowe opóźnienie.

## Język i Narzędzia

> **Ustalone: GDScript z typami.** Typy wszędzie, a ostrzeżenia `UNTYPED_DECLARATION` i `UNSAFE_*` ustawione na `Error` (`Project Settings > Debug > GDScript`, po włączeniu Advanced Settings; domyślnie są wyłączone). Kod z typami działa też szybciej. C# odpada: pierwszy plik `.cs` oznaczałby edytor w wersji .NET i .NET SDK u obojga, projekty C# w 4.7 nie eksportują się na web, a godot-sqlite nie ma typowanego API dla C#. Nie dokładamy go później, bo to przepisywanie kodu sieci i stanu świata.
>
> **Ustalone: Godot 4.7.2-stable, build standardowy, u obojga ta sama wersja.** Gdy jedno z nas otworzy projekt w nowszym edytorze, zmieniają się zapisane pliki i wpis wersji w `project.godot`. Aktualizacja tylko razem i tylko między kamieniami milowymi, w jednym osobnym PR (`Upgrade Project Files` z menu Project plus nowe wersje addonów, np. godot-sqlite). Bety pomijamy, 4.8 też, póki nie wyjdzie stabilna. Pobrany zip warto zachować, a Godot ze Steama nie powinien aktualizować się sam.
>
> **Ustalone: o trafieniach, parowaniach i unikach rozstrzyga host, czyli prowadzący gracz.** Klient wysyła tylko input, tak jak w notatce wyżej (opcja A w sekcji 6). Opcje B (netfox) i C (każdy o swojej postaci) zostają spisane w sekcji 6 jako plan B, gdyby w testach przez internet parowanie gościa okazało się za bardzo opóźnione.

Język i wersja silnika są ustalone w sekcji 1, reszta do przegadania:

- **Wersja silnika i język (ustalone):** Godot `4.7.2-stable` z 18 sierpnia 2026, build standardowy, GDScript z typami. 4.8 jest w becie (beta2 z 29 października 2026) i ją pomijamy. W README wpisujemy też wersję godot-sqlite.
- **Sieć i baza:** high-level multiplayer na ENet, zdarzenia przez RPC, pozycje przez `MultiplayerSynchronizer`, SQLite przez godot-sqlite za jednym autoloadem. Tailscale albo ZeroTier do grania przez internet w trakcie prac, GodotSteam tylko przy ewentualnym wydaniu na Steam.
- **Python obok gry, nie w niej:** pytest na tych samych plikach `.sql` (wbudowany moduł `sqlite3`), pandas albo DataGrip na logach z testów. Uwaga: SQLite w DataGrip i w Pythonie na Windowsie ma funkcje matematyczne, FTS5 i `R*Tree`, a gotowe binarki godot-sqlite nie mają żadnej z nich. Trzymamy się podstawowego SQL.
- **Testy:** GUT (9.7.1 dla 4.7.x) albo gdUnit4 (ma scene runner, który symuluje akcje wejścia). Oba działają z GDScript.
- **IDE:** na start wystarczy edytor wbudowany w Godota. JetBrains Rider jest darmowy do użytku niekomercyjnego i też obsługuje GDScript.
