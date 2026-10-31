# ⚔️ Projekt KryLex - Game Design Document

Mroczna gra akcji/RPG 2D (side-scroller) w stylistyce pixel art, oparta na słowiańskiej mitologii, nastawiona na ścisłą kooperację dwóch graczy online i świat, który pamięta ich czyny.

> **Status dokumentu:** wersja prototypowa (październik 2026). Opisuje zakres prototypu testowego oraz kierunki rozwoju pełnej gry. Pozycje oznaczone `[DO UZUPEŁNIENIA]` zebrane są w sekcji 7.

---

## 📑 Spis Treści
1. [Organizacja i Założenia](#1-organizacja-i-założenia)
2. [Świat, Eksploracja i NPC](#2-świat-eksploracja-i-npc)
3. [Klasy, Rozwój i Ekwipunek](#3-klasy-rozwój-i-ekwipunek)
4. [Walka, Bossowie i Przeciwnicy](#4-walka-bossowie-i-przeciwnicy)
5. [Mechaniki Kooperacji (Online)](#5-mechaniki-kooperacji-online)
6. [Technika: Sieć, Baza Danych i Testy](#6-technika-sieć-baza-danych-i-testy)
7. [Lista Otwartych Punktów](#7-lista-otwartych-punktów)

---

## 1. Organizacja i Założenia

### 🎯 Pitch
Mroczna, pixel-artowa gra akcji/RPG w świecie słowiańskiej mitologii, w której dwoje graczy dzieli jedną flaszkę leczenia, a świat zapamiętuje każdą ich śmierć i każde zwycięstwo.

### 🏛️ Filary Projektu
Każda nowa mechanika musi wspierać przynajmniej jeden filar. Jeśli nie wspiera żadnego – nie wchodzi.
1. **Współzależność** – nic ważnego nie da się zrobić w pełni samemu. Gracze potrzebują siebie nawzajem do leczenia, walki i eksploracji.
2. **Świat pamięta** – akcje graczy mają widoczne, trwałe konsekwencje (wrogowie, NPC, otoczenie).
3. **Mroczna słowiańszczyzna** – świat, wrogowie i NPC czerpią z mitologii i są ponure; mitologia to źródło mechanik, nie tylko dekoracja. Bohaterowie są z innych czasów i mogą być barwniejsi – kontrast między nimi a światem jest zamierzony.

### 📐 Parametry Główne
- **Gatunek:** Action RPG / metroidvania 2D, kooperacja online dla 2 graczy.
- **Perspektywa:** Side-scroller (widok z boku).
- **Status projektu:** Prototyp testowy. Celem jest sprawdzenie, czy kluczowe mechaniki (co-op online, wspólna flaszka, świat sterowany bazą) są wykonalne i dają frajdę. Decyzja o pełnej kampanii zapada dopiero po ukończeniu prototypu.
- **Czas gry prototypu:** ok. 20–40 minut, jeden zamknięty obszar.
- **Stylistyka:** Pixel art, mroczny, słowiański klimat (w prototypie: grafika zastępcza).

### 🛠️ Decyzje Techniczne
| Obszar | Decyzja | Uzasadnienie |
|---|---|---|
| Silnik | **Godot 4.7.2-stable**, build standardowy, ta sama wersja u obojga | Darmowy, silne 2D, wbudowany high-level multiplayer (ENet / RPC). |
| Model sieci | **Host-authoritative P2P** | Jeden gracz hostuje i jest źródłem prawdy, drugi jest klientem. Brak kosztów serwera. |
| Baza danych | **SQLite przy hoście** | Stan świata żyje w sesji hosta i jest replikowany do klienta. Baza jest *per sesja*, nie globalna. |
| Język | **GDScript z typami** | Jeden język u obojga, bez .NET SDK. Typy wszędzie, a ostrzeżenia o ich braku ustawione na błąd. |
| Kontrola wersji | Git + **GitHub** ([KrystianRodziewicz/KryLex](https://github.com/KrystianRodziewicz/KryLex)) | Git LFS dla grafik i dźwięków. |

> **Konsekwencja modelu sieci:** wszystko, co wpływa na stan gry (AI, fizyka otoczenia, drop, baza SQL), liczy się wyłącznie na hoście. Klient wysyła tylko input i otrzymuje stan. Mechaniki wymagające precyzyjnego timingu po stronie klienta (parowanie, uniki, Atak Zgrany) muszą uwzględniać kompensację opóźnień.

> **Ustalone: GDScript z typami.** Typy wszędzie, a ostrzeżenia `UNTYPED_DECLARATION` i `UNSAFE_*` ustawione na `Error` (`Project Settings > Debug > GDScript`, po włączeniu Advanced Settings; domyślnie są wyłączone). Kod z typami działa też szybciej. C# odpada: pierwszy plik `.cs` oznaczałby edytor w wersji .NET i .NET SDK u obojga, projekty C# w 4.7 nie eksportują się na web, a godot-sqlite nie ma typowanego API dla C#. Nie dokładamy go później, bo to przepisywanie kodu sieci i stanu świata.
>
> **Ustalone: Godot 4.7.2-stable, build standardowy, u obojga ta sama wersja.** Gdy jedno z nas otworzy projekt w nowszym edytorze, zmieniają się zapisane pliki i wpis wersji w `project.godot`. Aktualizacja tylko razem i tylko między kamieniami milowymi, w jednym osobnym PR (`Upgrade Project Files` z menu Project plus nowe wersje addonów, np. godot-sqlite). Bety pomijamy, 4.8 też, póki nie wyjdzie stabilna. Pobrany zip warto zachować, a Godot ze Steama nie powinien aktualizować się sam.
>
> **Ustalone: o trafieniach, parowaniach i unikach rozstrzyga host, czyli prowadzący gracz.** Klient wysyła tylko input, tak jak w notatce wyżej (opcja A w sekcji 6). Opcje B (netfox) i C (każdy o swojej postaci) zostają spisane w sekcji 6 jako plan B, gdyby w testach przez internet parowanie gościa okazało się za bardzo opóźnione.

### 👥 Zespół i Role
- **Krystian – Backend / Netcode:** architektura sieciowa, synchronizacja stanu, SQLite, system zapisu, narzędzia deweloperskie.
- **Alex – Design / Mechaniki:** game design, balans, projektowanie poziomów, AI, walka, dokumentacja.
- **Wspólne:** oboje testują grę w co-opie minimum raz w tygodniu.

### 🎯 Zakres Prototypu

**W zakresie:**
- 1 zamknięty obszar (fragment jednego bioma), ok. 20–40 minut rozgrywki.
- 2 klasy (uzupełniające się), 1 Ślub na klasę + 1 Ślub wspólny.
- 1 boss z pełnymi mechanikami, 3–4 typy zwykłych mobów, 1 elita.
- Działający co-op online z wspólną flaszką i podstawowymi pingami.
- Logowanie akcji do SQLite + **jedna** prosta reakcja świata na dane z bazy (dowód koncepcji „świat pamięta").

**Poza zakresem prototypu (kandydaci do pełnej wersji):**
- Pozostałe biomy, klasy i pula Ślubów.
- System Nemesis, adaptacyjni bossowie, pamięć AI.
- Proceduralni NPC.
- Niszczalne otoczenie, mechanika latarni.
- Tryb solo, więcej niż 2 graczy, PvP, cross-play, migracja hosta.
- **Grafika i dźwięk** – prototyp używa assetów zastępczych (placeholder / darmowe paczki). Decyzja o docelowej oprawie i tym, kto ją wykona, zapada po prototypie.

**Kryterium sukcesu prototypu:**
Dwoje graczy może przejść obszar od początku do pokonania bossa w sesji online bez desynchronizacji, a wspólna flaszka wymusza komunikację zamiast ją irytować.

### 🗓️ Kamienie Milowe
| Etap | Cel | Termin |
|---|---|---|
| M0 – Prototyp sieci | Dwie postacie biegają po jednej planszy online, wspólna flaszka działa, zapis do SQLite. | bez terminu |
| M1 – Prototyp grywalny | Pełny zakres opisany wyżej, od startu do bossa. | bez terminu |
| Decyzja | Czy robimy pełną grę? Jeśli tak – nowy plan i aktualizacja tego dokumentu. | po M1 |

> **Ustalone:** terminów nie wyznaczamy. Robimy to po godzinach i bez pośpiechu, a etap jest gotowy, gdy spełnia swój cel z tabeli, nie gdy mija data. Kolejność etapów zostaje.

> **Propozycja:** kolejność prac w M0.
> 1. Dwie postacie w jednym procesie, bez sieci: jedna na klawiaturze, druga na padzie. Tak sprawdzamy sterowanie obu postaci, zanim dojdzie sieć.
> 2. To samo przez localhost: dwie instancje z edytora (`Debug > Customize Run Instances`), jedna startuje jako host, druga jako klient (argument uruchomienia albo feature tag). Klawiatura trafia tylko do aktywnego okna, a pad w 4.7 do obu, więc każda instancja czyta tylko swoje urządzenie (`InputEvent.device`).
> 3. Potem wspólna flaszka i log do SQLite. Obie instancje mają ten sam folder `user://`, więc każda dostaje własną nazwę profilu w ścieżce zapisu, a bazę otwiera tylko host.
> 4. Od pierwszego buildu sieciowego testujemy ze sztucznym opóźnieniem: ok. 80 do 150 ms w obie strony (RTT) i 1 do 2% utraty pakietów. Godot 4.7 nie ma wbudowanego symulatora. Na Windowsie jest clumsy, uruchamiany jako administrator, z presetem `localhost ipv4 udp`. Jego opóźnienie działa w obu kierunkach, więc ustawiamy połowę RTT. Druga opcja to `NetworkSimulator` z netfox.extras, gdzie `latency_ms` też liczy się w jedną stronę.

### 🔄 Przepływ Pracy (Git Workflow)
1. **Branch `main`** – zawsze stabilna, działająca gra. Nie pracujemy na nim bezpośrednio.
2. Każda nowa rzecz ma **własny branch** z prefiksem: `feature/`, `fix/`, `art/` (np. `feature/nemesis-system`, `fix/flask-desync`).
3. Merge do `main` dopiero po przetestowaniu **w co-opie online**, nie tylko lokalnie.
4. Commity opisujemy po angielsku, konsekwentnie (np. `Add shared flask sync`, `Fix parry window on client`).

### 🧰 Git w projekcie Godota (propozycja)
- Projekt zakładamy w Project Managerze z włączonymi metadanymi Git. Godot sam zapisze `.gitignore` i `.gitattributes`, który wymusza końce linii LF.
- Do repo idą pliki `.import` z ustawieniami importu oraz pliki `.uid`, które Godot od 4.4 tworzy dla skryptów i shaderów. Ignorujemy `.godot/` (cache) i folder eksportu.
- Pliku SQLite nie trzymamy w repo. Żywa baza leży w `user://`, a `.gitignore` pomija `*.db`, `*.db-journal`, `*.db-wal` i `*.db-shm`. W repo trzymamy schemat jako tekst `.sql`, dodany do filtra eksportu plików niebędących zasobami, bo inaczej nie trafi do buildu.
- Jedna scena, jeden właściciel. Sceny są cienkie, np. gracz to scena główna z podscenami walki, sieci i grafiki. Liczby do strojenia siedzą w plikach `.tres`, więc balans nie rusza sceny. Przy konflikcie w `.tscn` bierzemy jedną wersję w całości, a drugą zmianę robimy jeszcze raz w edytorze.
- `project.godot` (akcje wejścia, autoloady, nazwy warstw kolizji) zmieniamy tylko w małych, osobnych pull requestach.
- Pliki przenosimy i zmieniamy im nazwy tylko w docku FileSystem w Godocie, bo przeniesienie w Eksploratorze albo w IDE bez `.uid` i `.import` psuje referencje. Nazwy od początku w snake_case: Git na Windowsie nie widzi zmiany samej wielkości liter, a wyeksportowana gra ją rozróżnia.
- **Do ustalenia:** Git LFS, zanim pierwszy asset trafi do repo, bo LFS ustawia się przed commitem plików. Opcja A: LFS dla grafik i dźwięków od razu, jak w tabeli wyżej. Opcja B: w grze 2D na start bez LFS. GitHub Free daje 10 GiB miejsca na LFS i 10 GiB transferu miesięcznie.
- Do `main` wchodzi krótki pull request, który sprawdza druga osoba. Zmianę nazwy albo przeniesienie węzła w scenie sieciowej opisujemy w PR, bo RPC trafia tylko do węzła z tym samym `NodePath` u obu graczy.
- Osobiste gałęzie `alex-branch` i `krystian-branch` mogą zostać obok gałęzi `feature/`, `fix/` i `art/`.

### 🔗 Linki Projektowe
- *Tablica zadań (Trello/Jira):* `[DO UZUPEŁNIENIA]`
- *Dysk z grafikami:* `[DO UZUPEŁNIENIA]`
- *Repozytorium:* [github.com/KrystianRodziewicz/KryLex](https://github.com/KrystianRodziewicz/KryLex)

### 📁 Dokumenty Wykonawcze
Ten plik to wizja. Szczegóły implementacyjne żyją w `docs/`:
- [`docs/biom-1-przeklety-bor.md`](docs/biom-1-przeklety-bor.md) – klimat, karty wrogów, boss i layout bioma prototypu.
- [`docs/npc-guslarz.md`](docs/npc-guslarz.md): kwestie warunkowe Guślarza i zapytania do bazy.
- `docs/M0-netcode-spec.md` – specyfikacja prototypu sieci *(do napisania)*.

---

## 2. Świat, Eksploracja i NPC

### 🌍 Koncepcja Świata: Zejście do Nawii
Świat to pionowa oś. Gracze schodzą z Jawii (świat żywych) coraz głębiej ku Nawii (słowiańskie zaświaty, domena Welesa). Każdy kolejny biom leży niżej i jest trudniejszy. Powrót na powierzchnię możliwy przez kapliczki.

### 🗺️ Struktura Mapy
- **Biomy jako osobne strefy**, nie jedna otwarta mapa. Każdy biom to zestaw połączonych pomieszczeń/ekranów (side-scroller 2D) z własnym klimatem, bestiariuszem i bossem na dnie.
- **Układ pionowy:** biomy ułożone jedna pod drugą. Zejście niżej = wyższy poziom trudności. Wewnątrz bioma również dominuje ruch w dół (szyby, jaskinie, studnie).
- **Hub – Osada:** bezpieczna wioska na powierzchni. Tu są NPC, handel i wybór Ślubów. Dostępna z każdej kapliczki (szybka podróż).
- **Kapliczki:** punkty kontrolne. Odpoczynek odnawia flaszkę i respawnuje wrogów. Pierwsze dotknięcie kapliczki przez jednego gracza odblokowuje ją dla obojga.
- **Co-op w level designie:** pomieszczenia projektowane dla dwóch postaci – dźwignie wymagające dwóch osób, platformy, których jedna postać nie przeskoczy bez wsparcia drugiej, rozwidlenia, gdzie gracze muszą się rozdzielić i spotkać ponownie.

> **Do ustalenia:** jak daleko gracze mogą się rozejść przy rozwidleniu. Biom 1 zakłada dziś wspólne pomieszczenie: scena zmienia się obojgu, gdy oboje dotkną wyjścia albo gdy jeden skoczy do Matecznika. Opcje:
> 1. Tylko wspólne pomieszczenie, jak teraz. Rozwidlenie mieści się w jednym pomieszczeniu albo obie drogi kończą się w tym samym.
> 2. Smycz: można odejść od partnera najwyżej o jedno pomieszczenie. Strzałka partnera z sekcji 5 pokazuje drogę, a następne wyjście czeka na drugiego.
> 3. Swobodnie, bez limitu.
>
> Opcje 2 i 3 oznaczają, że host prowadzi dwa pomieszczenia naraz, każde z własnymi wrogami (szczegóły w sekcji 6).

> **[DO UZUPEŁNIENIA – Lista Biomów (od góry do dołu)]**
> 0. *Osada (hub)*
> 1. *np. Przeklęty Bór*
> 2. *np. Bagna Utopców*
> 3. *np. Kurhany*
> 4. *np. Nawia (finał)*

### 💾 Świat jako Żywa Baza Danych (SQLite przy hoście)
- Gra loguje zdarzenia: śmierci graczy (miejsce, przyczyna, zabójca), zabójstwa wrogów, pokonanych bossów, odwiedzone kapliczki, użycia flaszki, wybrane Śluby.
- Stan bazy wpływa na świat przez dwa kanały:

**1. Pamięć środowiskowa (bez tekstu)**
- W miejscu śmierci gracza pojawia się **kurhan** – mały kopiec widoczny dla obojga. Kolejne śmierci w tym samym miejscu powiększają go. Daje graczom informację „tu giniemy" bez słowa.
- Pokonany boss zostawia trwały ślad w swoim biomie (np. zgaszone ogniska, cisza, inne oświetlenie).
- Wrogowie, którzy zabili gracza, są oznaczeni (fundament pod system Nemesis).

**2. Reaktywny dialog NPC**
- NPC mają ręcznie napisane pule kwestii; zapytanie do bazy wybiera, która kwestia pasuje do historii sesji.

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

### 🗣️ NPC – Nieliczni, ale Pamiętający
Zamiast proceduralnych NPC: **mała obsada stałych postaci** z dialogiem sterowanym bazą. Każdy NPC ma domyślne kwestie oraz kwestie warunkowe zależne od danych z SQLite.

| NPC | Rola | Przykład reakcji na bazę |
|---|---|---|
| **Guślarz** | Przewodnik / narrator. Czyta historię graczy z „księgi". | „Trzykroć już Bór was pochłonął. Może czas zejść inną drogą?" |
| **Kupiec** | Handel, wymiana zużytej broni. | Zniżka po zabiciu bossa z bioma, w którym handluje. |
| **Wędrowiec** | Pojawia się w różnych biomach, daje wskazówki. | Ostrzega przed miejscem, gdzie gracze zginęli najwięcej razy. |

> **[DO UZUPEŁNIENIA – Pozostali NPC i ich imiona]**

> **Do ustalenia:** ilu NPC w pełnej wersji. Pierwsza wersja Krystiana zakładała co najmniej 20 generowanych NPC chodzących po mapie. Obecny opis stawia na małą obsadę stałych postaci, a proceduralnych NPC zostawia na pełną wersję. Opcje:
> 1. Tylko mała obsada, jak teraz.
> 2. Kilku kluczowych NPC robionych ręcznie plus tanie postacie tła składane z części: lista imion, podmiana palety, rola z krótkiej listy. Chodzą po swoim pomieszczeniu i czytają tę samą tabelę reguł co Guślarz. Wtedy 20 to tylko ustawienie, które na start może wynosić 3.
> 3. Co najmniej 20 generowanych NPC, jak w pierwszej wersji.
>
> W opcjach 2 i 3 host tworzy postacie raz, przy starcie nowej gry, i zapisuje każdą jako wiersz w bazie. Gość dostaje gotowe wiersze. Sam seed nie wystarczy: według dokumentacji Godota algorytm `RandomNumberGenerator` to szczegół implementacji, więc po zmianie wersji silnika ten sam seed może dać innych NPC.

> **Uwaga:** kwestie z liczbą albo imieniem trzeba odmieniać. Liczba mnoga ma trzy formy: 1 strzyga, 2 strzygi, 5 strzyg (12 do 14 biorą trzecią formę, 22 drugą). Do tego dochodzą przypadki (zabiliście strzygę, o strzydze) i rodzaj (zginąłeś, zginęłaś). Formę liczby mnogiej wybiera `tr_n`. Od Godota 4.6 liczbę mnogą obsługują też pliki tłumaczeń CSV: kolumna `?plural`, a wiersz `?pluralrule` ustawia regułę, gdyby polskiej nie było wśród wbudowanych. Warto to sprawdzić na 1, 2, 5, 12 i 22. Przypadków i rodzaju silnik nie obsługuje, więc kwestie lepiej pisać tak, żeby podmiotem było miejsce albo stwór („Bór zabrał was już pięć razy"), a generowane imiona zostawiać w mianowniku.

### 🏕️ Eksploracja i Środowisko
- **Sekrety nagradzające współpracę:** ukryty sprzęt za przeszkodami wymagającymi dwóch graczy.
- **Wertykalność:** skoki, drabiny, liny, zapadnie – ruch w dół jest łatwy, w górę trudny (podkreśla „zejście bez powrotu" aż do następnej kapliczki).
- *(Pełna wersja)* Mechanika latarni, niszczalne otoczenie – poza zakresem prototypu.

### 🧪 Zakres Sekcji w Prototypie
- Osada (1 ekran) + fragment bioma 1 (ok. 8–12 pomieszczeń) + arena bossa.
- 1 NPC: Guślarz, z min. 5 kwestiami warunkowymi.
- Kurhany jako jedyna reakcja środowiskowa (dowód koncepcji „świat pamięta").
- 2 kapliczki.

---

## 3. Klasy, Rozwój i Ekwipunek

### 🛡️ Zasady Projektowania Klas
1. **Pętla wzajemna** – każda para klas ma synergię w obie strony. Klasa A wzmacnia B, a B dostarcza A czegoś, czego A nie zdobędzie sama. Żadna klasa nie jest samowystarczalna.
2. **Równy czas na scenie** – w każdej synergii obaj gracze wykonują widoczną, satysfakcjonującą akcję. Jeśli jeden tylko „klika buff", a drugi „robi show" – projekt jest zły.
3. **Brak klasy leczącej** – leczenie to wspólna flaszka. Klasa healera unieważniłaby ją.
4. **Brak duplikatów** – dwóch graczy nie może wybrać tej samej klasy. Dwóch Wojowników nie ma pętli wzajemnej, więc łamie filar Współzależności. *(Do ponownej oceny w pełnej wersji.)*
5. **Fantazja ponad funkcję** – klasa ma budzić skojarzenie, a nie być etykietą („DPS", „tank").
6. **Uniwersalne czasowniki** – istnieje krótka lista kluczowych akcji, do których każda klasa musi mieć dostęp. Specjalista wykonuje je mocno i tanio; pozostałe klasy – słabo, z ograniczeniem, ale wystarczająco, by przejść dalej. Żaden wróg ani boss nie może wymagać konkretnej klasy – tylko konkretnego czasownika.

### ⚔️ Klasy Prototypu
Nazwy robocze – do zmiany po ustaleniu docelowej stylistyki.

**Wojownik** – zwarcie, miecz i tarcza, pierwsza linia.
- *Daje partnerowi:* jego walka zasila zasób Maga (patrz: Zasób współpracy). Może osłonić tarczą partnera stojącego za nim.
- *Potrzebuje od partnera:* zaklętego ostrza – bez niego jego obrażenia są przeciętne.

**Mag** – średni dystans, żywioły, kontrola pola walki.
- *Daje partnerowi:* zaklina broń Wojownika żywiołem (ogień / lód / piorun), nadając jej dodatkowe efekty.
- *Potrzebuje od partnera:* zasobu, który sam nie regeneruje się bez walki Wojownika.

**Pętla w jednym zdaniu:** Wojownik walczy → Mag zyskuje zasób → Mag zaklina broń i rzuca zaklęcia → Wojownik walczy skuteczniej. Obaj widzą, jak ich akcja napędza drugiego.

> **Zasób współpracy `[KONCEPCJA – DO ROZWINIĘCIA]`**
> Mag korzysta z zasobu, który generuje aktywność partnera, a nie czas czy własne ataki. To fundament pętli wzajemnej. Szczegóły (nazwa, tempo generowania, limit, co dzieje się przy braku) ustalimy przy pełnym planowaniu mechanik walki. W prototypie wystarczy najprostsza wersja: trafienie Wojownika = +1 punkt, zaklęcie Maga = −X punktów.

> **Powyższa synergia to przykład tego, czego można się spodziewać po każdej parze klas** – kolejne klasy będą projektowane według tych samych zasad.

> **Uwaga:** w grze dla dokładnie dwóch osób projektujemy i balansujemy parę, a nie pojedynczą klasę. Przy 4 klasach jest 6 par, przy 5 już 10, przy 6 aż 15 (w notatkach Krystiana pada 5 albo 6 klas). Każda para to własne reakcje łączone, własna animacja Ataku Zgranego i osobny balans. Do tego grafika: jedna postać gracza to ok. 85 do 140 rysowanych klatek, więc 4 klasy to ok. 340 do 560 klatek samych graczy (5 klas: 425 do 700), zanim powstanie pierwszy wróg.
>
> **Propozycja:** reakcje budować ze wspólnej tabeli statusów, np. status plus czasownik (zamrożony + *Przerwij* = roztrzaskanie). Nowa klasa dopisuje wtedy jeden wiersz (jakie statusy nakłada i które czasowniki ma), a nie 4 czy 5 nowych tabel. Ręcznie robione dla pary zostają tylko ruchy popisowe, jak Atak Zgrany. Druga opcja to obecny zapis z sekcji 5: osobna tabela reakcji dla każdej pary.

### 🔑 Uniwersalne Czasowniki
Trzy warstwy dostępu – każdy czasownik musi być osiągalny na przynajmniej dwóch z nich:

1. **Mistrz** – klasa, dla której to główna umiejętność (mocno, często, bez kosztu).
2. **Wersja słaba** – każda inna klasa ma własną, ograniczoną wersję (słabszy efekt, długi cooldown, koszt zasobu).
3. **Przedmiot / otoczenie** – zapasowy dostęp niezależny od klasy (rzucana flaszka z ogniem, koksownik w arenie, tarcza podniesiona z ziemi).

| Czasownik | Co robi | Mistrz (prototyp) | Wersja słaba (prototyp) | Przedmiot / otoczenie |
|---|---|---|---|---|
| **Osłoń** | Blokuje atak wymierzony w partnera. | Wojownik – tarcza, pełny blok, bez cooldownu. | Mag – magiczna bariera: wchłania 1 atak, cooldown ~20 s. | Przewracalna osłona terenowa w arenach bossów. |
| **Podpal / Zamroź / Poraź** | Nakłada status żywiołowy, zdejmuje osłony żywiołowe. | Mag – zaklęcia, pełna siła i czas trwania. | Wojownik – naoliwione ostrze: kilka ciosów podpala, krótko i słabo. | Rzucana flaszka z ogniem / koksowniki w poziomie. |
| **Przerwij** | Łamie postawę, przerywa atak wroga. | Wojownik – uderzenie tarczą. | Mag – impuls: krótkie ogłuszenie, wysoki koszt zasobu. | Zrzucenie głazu / wybuch beczki. |
| **Oznacz** | Wskazuje wroga lub słaby punkt partnerowi. | *(klasa przyszła)* | Każda klasa – ping (patrz sekcja 5). | – |

> **Zasada balansu:** wersja słaba ma wystarczyć do *przejścia*, nigdy do *dominacji*. Jeśli duet bez Wojownika radzi sobie z „Osłoń" równie dobrze jak z Wojownikiem – klasa straciła sens.
>
> **Lista czasowników ma pozostać krótka (4–5).** Jeśli każdy wróg wymaga innego czasownika, każda klasa musi mieć dziesięć słabych wersji – i wraca drzewko umiejętności, od którego uciekamy Ślubami.
>
> **[DO UZUPEŁNIENIA – pełna tabela czasowników po dodaniu kolejnych klas]**

### 🕰️ Pomysł do Rozwinięcia: Bohaterowie z Różnych Epok
Koncepcja: każda klasa pochodzi z **wyraźnie innej epoki i kultury**, a kontrast między nimi jest celowy i ma bawić. Średniowieczny wojownik walczy ramię w ramię z muszkieterem, mag z piratem. Świat pozostaje mroczny i słowiański – to bohaterowie są z zewnątrz.

**Dlaczego to działa:**
- **Rozpoznawalność bez tłumaczenia** – sylwetka muszkietera czy pirata mówi wszystko w jednej klatce. Rozwiązuje problem nazw, które trzeba objaśniać.
- **Epoka = unikalny styl walki** – technologia danego czasu narzuca mechanikę, nie trzeba jej wymyślać:

| Przykład klasy | Epoka | Mechanika z epoki | Naturalna pętla wzajemna |
|---|---|---|---|
| **Muszkieter** | XVII w. | Jeden potężny strzał, długie przeładowanie. | Podczas przeładowania jest bezbronny – partner musi go *Osłonić*. Jego strzał łamie postawę z dystansu, dając partnerowi okno na atak. |
| **Pirat** | XVIII w. | Szabla + pistolet, hak na linie, ciężka obrona. | Hak przyciąga wroga w zaklęcie Maga lub pod miecz Wojownika. Sam potrzebuje kogoś, kto wytrzyma w zwarciu – lekka zbroja. |
| **Husarz** | XVII w. | Szarża z kopią, ogromny impet, słaby w miejscu. | Szarża wymaga rozbiegu – partner musi przytrzymać wroga w miejscu (*Przerwij*, zamrożenie). Po szarży husarz jest odsłonięty. |
| **Alchemik** | Renesans | Mikstury rzucane, kontrola statusów. | Nakłada statusy pod reakcje łączone partnera; sam nie ma obrony i żadnego ataku bez przygotowania. |

- **Kontrast jako ton** – barwni przybysze w ponurych zaświatach tworzą napięcie, które samo w sobie jest atrakcyjne (por. Hades, Dead Cells). Humor bierze się z zestawienia, nie z żartów w dialogach – świat nie przestaje być mroczny.

**Uzasadnienie fabularne (propozycja):** w Nawii czas nie istnieje. Guślarz obrzędem Dziadów przywołuje z różnych wieków dusze tych, którzy nie dokończyli swojej drogi – stąd w słowiańskich zaświatach pirat i muszkieter. Jedno zdanie w intro wystarczy; reszta to zabawa.

**Ryzyka do przemyślenia:**
- Każda epoka to osobny zestaw grafik (broń, strój, animacje) – droższe niż klasy w jednej stylistyce.
- Filar 3 został doprecyzowany pod tę koncepcję (świat mroczny, bohaterowie barwniejsi) – przy każdej nowej klasie sprawdzajcie, czy kontrast nadal *wspiera* mrok, a nie go rozmywa.
- Lista czasowników musi pozostać krótka mimo rosnącej różnorodności – epoka zmienia *jak* klasa wykonuje czasownik, nie *które* czasowniki istnieją.

> **[DO UZUPEŁNIENIA – decyzja po prototypie: czy Wojownik i Mag stają się „średniowiecznym wojownikiem" i „magiem renesansowym", czy pozostają neutralni?]**

### 📜 System Ślubów (Vows)
Ślub to **potężna moc kupiona surowym ograniczeniem**. Zamiast drzewka umiejętności gracz wybiera Ślub w Osadzie (zmiana możliwa tylko przy kapliczce). Śluby dzielą się na:

**Śluby osobiste** – dotyczą jednego gracza, ale ich ograniczenie zawsze dotyka też partnera.

| Ślub | Moc | Cena |
|---|---|---|
| **Ślub Krwi** | Ogromne obrażenia w zwarciu. | Flaszka zablokowana, dopóki nie zadasz obrażeń. |
| **Ślub Ciężaru** | Odporność na ogłuszenie i odrzut, pancerz x2. | Brak uniku – unikasz tylko parowaniem lub krokiem w tył. Partner musi odciągać ataki obszarowe. |
| **Ślub Cienia** | Wrogowie cię ignorują, dopóki nie atakujesz. Ataki z zaskoczenia krytyczne. | Cała uwaga wrogów spada na partnera. |
| **Ślub Echa** | Twoje pingi oznaczają wroga – partner zadaje mu +30% obrażeń. | Twoje własne obrażenia −20%. Stajesz się „oczami" duetu. |
| **Ślub Płomienia** | Każde użycie flaszki wybucha, podpalając wrogów wokół ciebie. | Flaszka leczy cię tylko w połowie. |

**Śluby wspólne** – muszą je przyjąć **oboje**. Zmieniają reguły gry dla duetu.

| Ślub | Moc | Cena |
|---|---|---|
| **Ślub Więzi** | Gdy jesteście blisko siebie (ok. 1 ekran), obaj +25% obrażeń i zasób współpracy generuje się szybciej. | Oddalenie się powoduje obrażenia obojgu. Rozwidlenia w poziomach stają się dylematem. |
| **Ślub Jednej Krwi** | Jeden wspólny, podwójny pasek zdrowia. Flaszka leczy obu naraz. | Śmierć jest wspólna. Błąd jednego zabija oboje. |
| **Ślub Zamiany** | Flaszka ma +2 ładunki. | Flaszka leczy *tylko partnera*, nigdy siebie. Musisz prosić o leczenie. |
| **Ślub Dziadów** | Duch zabitego gracza (sekcja 5) zyskuje aktywne wsparcie: generuje zasób współpracy dla partnera, oznacza wrogów. | Ożywienie tylko przy kapliczce – brak wskrzeszenia przy kurhanie. |

> **Zasada:** Ślub osobisty nigdy nie może być czystym wzmocnieniem solo – jego cena musi wymuszać reakcję partnera. Dzięki temu Śluby są narzędziem synergii, nie tylko buildu.
>
> **[DO UZUPEŁNIENIA – Pełna pula Ślubów po testach prototypu]**

> **Do ustalenia:** jak resetuje się blokada w Ślubie Krwi. Przy obecnym zapisie jedno trafienie na początku walki odblokowuje flaszkę do końca tej walki, więc cena jest dużo łagodniejsza, niż brzmi. Opcje:
> 1. Jedno trafienie, jeden łyk: każdy łyk wymaga trafienia od poprzedniego łyku.
> 2. Okno po trafieniu: flaszka jest otwarta przez kilka sekund po zadaniu obrażeń. Podobnie działa Rally w Bloodborne, gdzie cios oddany w ciągu kilku sekund przywraca część straconego zdrowia.
> 3. Ślub, który można złamać: wolno wypić mimo blokady, ale moc Ślubu znika do następnej kapliczki. Ograniczenie staje się wtedy wyborem.
>
> Przy każdej opcji blokadę warto pokazać na wspólnej flaszce u obu graczy (np. kłódka), żeby partner widział, kiedy posiadacz Ślubu nie może pić. Do dopisania jednym zdaniem: co liczy się jako obrażenia (podpalenie, reakcja zaczęta przez partnera, rzut bronią)?

### 🎒 Ekwipunek i Walka Bronią
- **Sprzęt przypisany do klas** ukryty po całej mapie. Przedmiot dla Wojownika znaleziony przez Maga trzeba **przekazać** partnerowi (fizyczna interakcja – kolejny punkt kontaktu).
- **Czysto matematyczne skalowanie:** obrażenia vs pancerz bez „gąbek na pociski". Formuła jawna i jednakowa dla graczy i wrogów.
- **Zużycie broni:** brak napraw. Niszczejącą broń można **rzucić** we wroga (obrażenia krytyczne przy roztrzaskaniu) i podnieść nową. Rzut w wroga oznaczonego przez partnera lub zaklętego żywiołem = dodatkowy efekt (np. eksplozja zaklęcia).
- **Łup wspólny:** przedmioty z bossów dropią w dwóch wersjach – po jednym dla każdej klasy. Żadnego „kto pierwszy, ten lepszy".

> **Do ustalenia:** jaki wzór pancerza. Dwie typowe rodziny wzorów działają zupełnie inaczej:
> 1. **Odejmowanie** (obrażenia minus pancerz): cios słabszy od pancerza nic nie robi, chyba że dodamy minimum. Szybkie, lekkie trafienia (np. zaklęcia Maga, jeśli będą słabe i częste) prawie nie ruszą opancerzonego wroga. Wzór jest ten sam dla graczy, więc gracz ze Ślubem Ciężaru (pancerz x2) może być prawie odporny na drobne moby.
> 2. **Iloraz** (`obrażenia * K / (K + pancerz)`): zawsze coś przechodzi i obaj gracze mają wkład, ale pancerz działa jak dodatkowe HP (efektywne zdrowie rośnie `1 + pancerz / K` razy), więc mocno opancerzony wróg zaczyna przypominać gąbkę.
>
> Rozstrzygnie arkusz: nasze wartości ataków, trzy typy wrogów i liczba trafień do zabicia dla pary oraz dla jednego gracza, gdy partner jest duchem.

> **Do ustalenia:** co daje exp. Exp już krąży w sekcji 4 (Nemesis go zabiera, przeciwwaga areny daje go więcej), ale nigdzie nie jest napisane, na co się go wydaje. Opcje:
> 1. Statystyki kupowane przy kapliczce, małymi krokami (blisko poziomów postaci i mobów z pierwszych notatek).
> 2. Zamiast statystyk sloty albo ulepszenia Ślubów: postać rośnie w możliwości, a nie w liczby.
> 3. Niezależnie od tego: exp wspólny dla pary (jedna liczba na hoście, jak flaszka) albo osobny dla każdego gracza.
>
> Uwaga: osobny exp razem z Nemesis, który zabiera exp zabitemu, nakręca spiralę. Słabszy gracz traci najwięcej i zostaje coraz dalej w tyle. A wzrost przez samo dokładanie HP przywraca „gąbki na pociski”.

### 🧪 Zakres Sekcji w Prototypie
- Wojownik + Mag z działającą pętlą (zasób współpracy w najprostszej wersji + zaklinanie broni).
- 1 Ślub osobisty na klasę (propozycja: Ślub Krwi dla Wojownika, Ślub Echa dla Maga) + 1 Ślub wspólny (propozycja: Ślub Zamiany).
- 3 bronie na klasę o różnym zużyciu, rzut bronią zaimplementowany.
- Przekazywanie przedmiotów między graczami.
- Wersje słabe czasowników *Osłoń* i *Podpal* (bariera Maga, naoliwione ostrze Wojownika) – opcjonalnie, jeśli czas pozwoli.

---

## 4. Walka, Bossowie i Przeciwnicy

### ⚔️ Fundamenty Walki (side-scroller 2D)
- **Czytelność ponad wszystko:** każdy atak wroga ma wyraźną zapowiedź (animacja, dźwięk, błysk). Śmierć musi zawsze wynikać z błędu gracza, nigdy z zaskoczenia.
- **Trzy odpowiedzi na atak:** unik (przeskok / przetoczenie), parowanie (okno czasowe, nagradza ryzyko), blok (tylko tarcza – pewny, ale kosztuje wytrzymałość).
- **Postawa wroga (stagger):** każdy przeciwnik ma ukryty pasek postawy. Jego wyczerpanie = ogłuszenie i okno na atak krytyczny. To główny punkt styku z pętlą klas (ogłuszenie przez Wojownika = premia zasobu dla Maga).
- **Statusy żywiołowe:** podpalenie (obrażenia w czasie), zamrożenie (spowolnienie), porażenie (łańcuch na sąsiadów). Łączenie statusów daje reakcje (np. zamrożony + uderzony = roztrzaskanie).
- **Wertykalność w walce:** wrogowie atakują z półek nad i pod graczem; zrzucenie wroga z wysokości zadaje obrażenia od upadku.

> **Do ustalenia:** ciała i flankowanie w widoku z boku.
> 1. Czy gracze blokują siebie nawzajem i wrogów, czy wszyscy się przenikają, a kontakt idzie tylko przez hitboxy i hurtboxy (`Area2D`)? Przy obecnym zapisie (wszystko liczy host) twarde kolizje są spójne. Jeśli jednak każda maszyna będzie ruszać swoją postacią sama, twarde zderzenia z ciałami, których pozycja przychodzi z sieci, dają niewidzialne ściany i pchnięcia widoczne tylko na jednym ekranie. Każdy `CollisionObject2D` startuje z `collision_layer` i `collision_mask` równymi 1, czyli domyślnie wszystko zderza się ze wszystkim.
> 2. Pancerz kierunkowy nagradza bicie w plecy. Co robi wróg, gdy jeden gracz trzyma go z przodu, a drugi bije z tyłu: obraca się do tego, kto trafił ostatni, ma atak w obie strony z własną zapowiedzią (jak Tupnięcie Biesa), czy odskakuje, żeby mieć obu graczy po jednej stronie?

### 🐺 Trzy Poziomy Przeciwników

| Poziom | Zachowanie | Adaptacja | Rola w projekcie |
|---|---|---|---|
| **Mob** | Proste, przewidywalne wzorce. 2–3 ataki. | **Brak.** | Nauka rytmu walki, „pracownicy" świata. |
| **Elita** | Złożone wzorce, odporności, własna mini-arena. | **System Nemesis** (patrz niżej). | Wyzwanie, nagroda, trwały ślad w świecie. |
| **Boss** | Fazy, mechaniki wymagające dwóch graczy. | **Uczy się po śmierci gracza.** | Kulminacja bioma. |

### 🧩 Wrogowie Projektowani pod Czasowniki
Każdy mob, elita i boss wymaga **czasowników** (sekcja 3), nie klas. Każda cecha co-op musi dać się rozwiązać przez dowolną parę klas – łatwiej przez specjalistów, trudniej przez wersje słabe.

- **Pancerz kierunkowy** – odporny z przodu, miękki z tyłu. Wymaga: *Przerwij* lub rozdzielenia uwagi.
- **Osłona żywiołowa** – nietykalny, dopóki ktoś nie nałoży statusu. Wymaga: *Podpal / Zamroź / Poraź*. Mag zdejmie ją jednym zaklęciem; Wojownik – kilkoma ciosami naoliwionym ostrzem lub flaszką z ogniem.
- **Uciekinier** – wycofuje się przed zwarciem. Wymaga: *Przerwij* lub kontroli terenu.
- **Agresja na leczenie** – szarżuje na gracza, który użył flaszki. Wymaga: *Osłoń* od partnera. Wojownik zasłoni tarczą; Mag postawi barierę – jedną, więc musi wybrać moment.

**Bossowie:** każda mechanika dwuosobowa jest opisana czasownikiem w dokumencie bossa (np. „faza 2 wymaga *Osłoń* co ~15 s" – nie „wymaga Wojownika").

### 🩸 System Awansów (Nemesis) – tylko Elity
- Zwykłe moby **nie awansują** – pozostają stałym punktem odniesienia.
- **Elita, która zabije gracza, awansuje:** otrzymuje imię, zabiera część expa, rośnie w siłę i zyskuje cechę związaną ze sposobem, w jaki zabiła (np. zabiła ogniem → odporność na ogień).
- Awansowana Elita **pamięta**: przy kolejnym spotkaniu ma unikalną linię zachowań lub drwi gestem.
- Pokonanie Nemesis zwraca zabrany exp z nawiązką i zostawia trwały ślad w świecie (kurhan, trofeum w Osadzie, kwestia Guślarza).
- **Limit eskalacji:** maks. 3 awanse na jedną Elitę. Potem przestaje rosnąć, żeby nie blokować postępu słabszym duetom.

> **Do ustalenia:** kto może awansować. W pierwszej wersji Krystiana awansował każdy mob, który zabił gracza, a obecny zapis ogranicza to do Elit. Opcje: tylko Elity (jak teraz, moby zostają stałym punktem odniesienia), każdy mob (więcej własnych historii, ale przy częstych śmierciach awanse mogą się sypać seriami) albo każdy mob, ale najwyżej jeden żywy awansowany na biom.
>
> Przy imionach wchodzi polska gramatyka: „zabity przez Kulawą Strzygę” wymaga odmiany imienia złożonego w trakcie gry, a rodzaj zmienia czasownik („zabiła” czy „zabił”). Najprościej trzymać imię zawsze w mianowniku („Nemesis: Kulawy Leszy”) i zapisywać rodzaj stwora, żeby zgadzały się przymiotniki i czasowniki.

> **Uwaga:** System Nemesis z gry Middle-earth: Shadow of Mordor jest w USA opatentowany przez Warner Bros. (US 10,926,179 B2, udzielony 23 lutego 2021). Google Patents podaje go jako aktywny do ok. sierpnia 2036. Z tego samego zgłoszenia pochodzą kolejne dokumenty w USA: US 11,660,540 B2, US 12,201,908 B2 i oczekujące zgłoszenie US 2025/0108303 A1. Europejskich odpowiedników Google nie pokazuje. Przy hobbystycznym prototypie to informacja do zapamiętania. Zaczyna mieć znaczenie przy publicznym wydaniu, przede wszystkim płatnym, które trafia do graczy w USA. Czy nasza wersja w ogóle podpada pod ten patent, może ocenić tylko specjalista od patentów. Własna nazwa „System Awansów” w publicznych materiałach nic nie kosztuje.

### 💀 Adaptacyjni Bossowie
- Boss ma **bazowy zestaw ataków** + pulę 2–3 „nauczonych" ruchów, które odblokowuje po zabiciu gracza. Nauczony ruch jest odpowiedzią na to, co gracze robili (np. jeśli stali daleko – zyskuje szarżę; jeśli parowali – zyskuje atak nieparowalny).
- **Limit eskalacji:** boss uczy się maks. 3 razy. Po trzeciej śmierci graczy nie rośnie dalej.
- **Przeciwwaga po porażce:** gra ułatwia otoczenie areny – okoliczne moby dają więcej expa i dropu, pojawia się dodatkowa kapliczka bliżej areny. Gracze mogą szybko się wzmocnić przed rewanżem zamiast wracać przez cały biom.
- **Mechaniki dwuosobowe:** każdy boss ma przynajmniej jedną fazę, której nie da się przejść w pojedynkę (np. dwa filary do zniszczenia naraz, atak wymagający *Osłoń* od partnera).

> **Uwaga:** przeciwwagę areny da się farmić: celowo zginąć u bossa, a potem zbierać wzmocniony exp i drop. Do tego każdy nauczony ruch to nowa animacja, zapowiedź, hitboxy i balans. Tańsze są zmiany bez nowych klatek, jak futro Niedźwiedzia, które przestaje płonąć. Opcje zamiast tego albo obok:
> 1. Dodatkowa kapliczka bliżej areny, którą już mamy (krótszy powrót, jak Stakes of Marika w Elden Ring).
> 2. Wskazówka od NPC po porażce, tak jak Guślarz ma już kwestię po śmierci od Leszego.
> 3. Okoliczne moby dają narzędzia zamiast expa, np. zapasową broń do rzutu albo flaszkę z ogniem na Futro Włodarza.
> 4. Bonus do expa zostaje, ale z limitem: raz na bossa i tylko na ustaloną liczbę zabójstw.

> **Propozycja:** jedno zdarzenie śmierci, z którego czytają wszystkie systemy. To może być wiersz `player_death` z tabeli `events` w `docs/npc-guslarz.md`: obok gracza, miejsca, czasu i zabójcy dochodzi rodzaj zabójcy (mob, Elita, boss, otoczenie, upadek, partner), id konkretnego wroga i ruch, którym zabił. Do tego mała tabela: który system reaguje na którą śmierć (kurhan, Nemesis, nauka bossa, przeciwwaga areny, kwestie Guślarza), najwyżej jedna lub dwie reakcje na przypadek. Przykład: śmierć od Elity to kurhan i awans, a śmierć obojga u bossa to kurhan i albo nauka bossa, albo ułatwienie areny, nie oba naraz. Wtedy jedna śmierć nie pociąga pięciu dźwigni naraz. Przy okazji do ustalenia: czy śmierć obojga w jednej walce liczy się raz, czy dwa razy.

### 🧠 Pamięć AI – tylko Bossowie i Elity
Jeśli gracze powtarzają jeden schemat (ten sam atak, ta sama pozycja), boss lub elita zaczyna na niego reagować. Zwykłe moby **nie uczą się** – gracz ma prawo do swojego ulubionego ataku w codziennej walce. Adaptacja jest wydarzeniem, nie karą.

### 📖 Słowiański Bestiariusz
Wrogowie czerpią z mitologii słowiańskiej. Każdy biom ma własny zestaw.

> **[DO UZUPEŁNIENIA – Lista Mobów per biom]**
> *np. Bór: Leszy (elita), wilkołaki, błędne ogniki, strzygi*
>
> **[DO UZUPEŁNIENIA – Lista Elit z cechami Nemesis]**
>
> **[DO UZUPEŁNIENIA – Lista Bossów z fazami i mechanikami dwuosobowymi]**

### 🧪 Zakres Sekcji w Prototypie
- Unik, parowanie, blok, pasek postawy – w pełni zaimplementowane.
- 3 statusy żywiołowe + 1 reakcja (zamrożony → roztrzaskanie).
- 3–4 typy mobów, w tym min. 2 z cechą co-op (pancerz kierunkowy, osłona żywiołowa).
- 1 Elita **bez** systemu Nemesis – ale jej zabójstwa graczy są logowane do SQLite (fundament pod Nemesis).
- 1 Boss z 2 fazami i 1 mechaniką dwuosobową. Adaptacja **poza zakresem** – ale śmierci graczy w arenie są logowane.

---

## 5. Mechaniki Kooperacji (Online)

### 🧪 Wspólna Flaszka (Zasób Dzielony)
- Obaj gracze dysponują **jedną pulą ładunków** (prototyp: 3). Użycie przez gracza A zabiera ładunek graczowi B. Odnowienie tylko przy kapliczce.
- Pula jest **widoczna u obu graczy** w tym samym miejscu HUD, a użycie flaszki przez partnera jest sygnalizowane wyraźnie (dźwięk + animacja), nawet gdy partner jest poza ekranem.
- **Prośba o flaszkę** to ping kontekstowy (patrz niżej) – gracz nie musi niczego pisać.
- Flaszka wiąże się z resztą systemów: *Agresja na leczenie* (sekcja 4) sprawia, że moment użycia wymaga osłony partnera; *Ślub Zamiany* i *Ślub Płomienia* (sekcja 3) zmieniają jej reguły.

> **Uwaga techniczna (netcode):** użycie flaszki musi być **zatwierdzane przez hosta**. Przy jednym ładunku obaj gracze mogą wcisnąć leczenie w tej samej klatce – host rozstrzyga, kto dostał ładunek, a drugi gracz widzi odmowę. Bez tego pojawi się desynchronizacja lub „darmowe" leczenie.

### ⚔️ Wspólne Ataki (Synergia)
Dwa rodzaje – różnią się tym, czego wymagają od graczy:

**1. Atak Zgrany** – wymaga pełnego skupienia obojga.
- Ładuje się przez współpracę (np. zasób współpracy Maga + ogłuszenia Wojownika wypełniają wspólny pasek).
- Gdy pasek jest pełny, obaj gracze muszą wcisnąć przycisk w **tym samym oknie czasowym** (prototyp: ok. 0,4 s) i w zasięgu wzajemnym. Powodzenie = potężny atak obszarowy z unikalną animacją dla danej pary klas. Niepowodzenie = pasek spada o połowę.
- Jest rzadki (1–2 razy na walkę z bossem) i ma być *momentem*, nie rutyną.

> **Uwaga techniczna:** okno 0,4 s przy opóźnieniu 50–100 ms między graczami jest realne tylko z kompensacją lagu po stronie hosta (host porównuje znaczniki czasu wciśnięć, nie moment ich odbioru). Jeśli okaże się to zbyt trudne – okno rośnie, nie znika.

> **Uwaga:** żeby host mógł porównać znaczniki czasu wciśnięć, obie maszyny potrzebują wspólnego zegara, a `MultiplayerAPI` w Godocie go nie ma. Każdy komputer liczy czas po swojemu, więc goły znacznik z klienta hostowi nic nie mówi. Dwie instancje na jednym PC dzielą zegar, więc ten problem wyjdzie dopiero w grze z dwóch domów.
>
> **Do ustalenia:** jak liczymy to okno. Opcje 1 i 2 zostają przy znacznikach czasu z uwagi wyżej, opcja 3 z nich rezygnuje.
> 1. Sami szacujemy przesunięcie zegarów pingiem RPC ze znacznikami czasu, a statystyka `PEER_ROUND_TRIP_TIME` z `ENetPacketPeer` służy do kontroli.
> 2. Bierzemy gotową synchronizację czasu z addonu netfox (MIT). To dodatkowa zależność.
> 3. Host mierzy okno w chwili odbioru wciśnięć i dodaje tolerancję ok. jednego RTT (między domami zwykle kilkadziesiąt ms, na Wi-Fi bywa ponad 100 ms). Najmniej kodu, a okno po prostu trochę rośnie.

**2. Reakcje Łączone** – sekwencje akcji dwóch klas w krótkim odstępie.
- Akcja partnera w ciągu ok. 2 s po akcji pierwszego gracza wywołuje efekt większy niż suma obu.
- Przykłady z pary Wojownik + Mag:
  - *Ogłuszenie (Wojownik) → Impuls (Mag)* = wróg powalony na ziemię, otwarty na ciosy krytyczne.
  - *Zamrożenie (Mag) → Uderzenie tarczą (Wojownik)* = roztrzaskanie, obrażenia obszarowe.
  - *Podpalenie ostrza (Mag) → Rzut zniszczoną bronią (Wojownik)* = eksplozja ognia w miejscu trafienia.
- Reakcje nie wymagają timingu co do klatki – mają być **odkrywane** w trakcie gry, nie wyuczone. Każda para klas ma własną tabelę reakcji.

> **[DO UZUPEŁNIENIA – Tabela reakcji łączonych dla każdej pary klas]**

### 🖐️ Komunikacja przez Wskazywanie
Zasada: **wszystko, o czym gracze chcą powiedzieć, można pokazać.** Zero zależności od czatu głosowego.

**Ping kontekstowy (jeden przycisk):**
- Gracz przytrzymuje przycisk i wskazuje gałką kierunek – znacznik **przyciąga się** do najbliższego obiektu interaktywnego w tym kierunku (wróg, półka, przedmiot, drzwi, kapliczka).
- Znaczenie pingu zależy od celu – gracz nie wybiera komunikatu, gra go rozumie:

| Cel pingu | Znaczenie | Widok u partnera |
|---|---|---|
| Wróg | „Atakuj tego" | Obrys wroga w kolorze gracza + numer kolejności, jeśli pingów jest kilka |
| Półka / przejście | „Idź tam" | Strzałka w świecie, widoczna także zza krawędzi ekranu |
| Przedmiot | „Weź to" / „To dla ciebie" | Ikona nad przedmiotem |
| Pułapka / zagrożenie | „Uważaj" | Pulsujące ostrzeżenie |
| Własna postać | „Potrzebuję flaszki" | Ikona flaszki nad graczem + dźwięk |
| Partner | „Osłoń mnie" / „Chodź do mnie" | Ikona nad partnerem |

- Wrogowie oznaczeni pingiem są **numerowani** – „drugi od lewej" przestaje istnieć, jest „ten z dwójką".
- **Wskaźnik partnera poza ekranem:** stała strzałka na krawędzi ekranu z dystansem i paskiem zdrowia partnera. Konieczna, bo kamery są osobne.

**Koło gestów (przytrzymanie dłużej):** 4–6 komunikatów, których nie da się wskazać: *Tak / Nie / Czekaj / Wracajmy do kapliczki / Dobra robota / Przepraszam*.

> **Uwaga:** w sieci ping to pojedyncze zdarzenie, a nie stan. Najprościej wysłać go jednym RPC w trybie `any_peer` (klient może je wywołać) z `call_local` (wysyłający widzi swój ping od razu, partner chwilę później). W Godocie 4.7 RPC jest domyślnie niezawodne (reliable), więc ping nie zginie po drodze. RPC nie wyśle samego węzła, dlatego ping na wrogu niesie coś, co znają obie maszyny, np. ścieżkę węzła wroga, którą i tak muszą mieć zgodną. Znacznik przesuwa się wtedy razem z wrogiem.
>
> **Do ustalenia:**
> 1. Numery pingowanych wrogów. Przez `call_local` każdy widzi swój ping pierwszy, więc przy dwóch pingach w tej samej chwili numery mogą się zamienić między ekranami. Opcje: osobna numeracja dla każdego gracza, w jego kolorze, albo numery nadaje host (wtedy własny numer widać po jednym RTT).
> 2. Limit przeciw spamowi i po ilu sekundach ping znika.
> 3. Gesty z koła na start jako ikony albo dymki nad postacią, bo każdy animowany gest to nowe klatki pixel artu dla każdej klasy. Opcje: zostają ikony na stałe albo animacje później.

### 💀 Śmierć i Rozłączenie

**Śmierć jednego gracza – mechanika bazowa „Duch":**
- Zabity gracz staje się duchem: nie walczy i nie może zostać trafiony, ale porusza się swobodnie, **widzi ukryte przejścia** i może pingować. Pozostaje w grze – nie patrzy w ekran ładowania.
- Partner może go **wskrzesić** po zakończeniu walki (interakcja ~3 s przy kurhanie gracza, tylko poza walką) lub przy kapliczce.
- W walce z bossem wskrzeszenie jest niemożliwe – boss musi paść lub oboje wracają do kapliczki.
- Śmierć obojga = powrót do ostatniej kapliczki.
- *Ślub Dziadów* (sekcja 3) **rozszerza** ducha o aktywne wsparcie (zasób dla partnera, oznaczanie).

**Rozłączenie:**
- Rozłączenie **klienta**: gra hosta zatrzymuje się i czeka na powrót (prototyp: 120 s). Po tym czasie sesja zapisuje się w ostatniej kapliczce.
- Rozłączenie **hosta**: świat (SQLite) żyje u hosta, więc klient nie może grać dalej samodzielnie. Sesja kończy się komunikatem; postęp jest bezpieczny dzięki autozapisowi przy każdej kapliczce.
- Migracja hosta – **poza zakresem** prototypu i prawdopodobnie pełnej wersji.

> **Uwaga:** gdy partnerowi padnie gra albo internet, ENet zgłosi to dopiero po swoim domyślnym timeoucie, od 5 do 30 s. Do tego czasu jego postać stoi zamrożona w walce i może zginąć.
>
> **Propozycja:**
> 1. Komunikat „partner traci połączenie" po sekundzie lub dwóch bez pakietów, na obu ekranach. Host wtedy od razu pauzuje, bez czekania na ENet. Timeouty da się skrócić przez `ENetPacketPeer.set_timeout` (wartości w ms, peer z `ENetMultiplayerPeer.get_peer(id)`). W buildach debug odwrotnie: dłuższe timeouty po obu stronach, żeby breakpoint nie zrywał połączenia.
> 2. Rozłączenie nigdy nie jest śmiercią: bez kurhanu, bez awansu wroga, bez nauki bossa i bez zdarzenia `player_death`, które zlicza Guślarz. Osobną ścieżkę dają sygnały `peer_disconnected` (u hosta) i `server_disconnected` (u klienta), a w logu ląduje np. `session_aborted`.
> 3. Przy łączeniu sprawdzamy, czy oboje mają ten sam build. RPC leci jako numer na posortowanej liście metod węzła, więc jedno dodane albo przemianowane RPC po jednej stronie może odpalić inną funkcję, a Godot tylko wypisuje błąd w konsoli i działa dalej. `SceneMultiplayer` ma na to krok uwierzytelniania: `auth_callback`, ID buildu przez `send_auth`, `complete_auth` tylko przy zgodności. `peer_connected` przychodzi dopiero potem.
>
> **Do ustalenia:** skąd ID buildu (stała `PROTOCOL` podbijana ręcznie albo commit z gita) i czy na wspólne sesje oboje bierzemy ten sam commit.

### 🧪 Zakres Sekcji w Prototypie
- Flaszka: 3 ładunki, zatwierdzanie przez hosta, sygnał użycia przez partnera.
- 1 Atak Zgrany (Wojownik + Mag) z kompensacją lagu.
- 2 Reakcje Łączone (Ogłuszenie → Impuls, Zamrożenie → Uderzenie tarczą).
- Ping kontekstowy z przyciąganiem do celu, 4 konteksty (wróg, przejście, własna postać, partner) + wskaźnik partnera poza ekranem. Koło gestów – opcjonalnie.
- Duch po śmierci + wskrzeszenie poza walką. Obsługa rozłączenia klienta (zatrzymanie + zapis).

---

## 6. Technika: Sieć, Baza Danych i Testy

To obszar Krystiana z sekcji 1, spisany jako propozycje i pytania do wspólnego ustalenia. Punkty już ustalone są tak oznaczone.

### 🌐 Model Sieci (ustalone: opcja A)

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

### 🧭 Kto Czym Zarządza

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

### 🚪 Rozdzielanie się w poziomie

Sekcja 2 ma rozwidlenia, na których gracze się rozdzielają, a sekcja 5 osobne kamery. W obrębie jednego pomieszczenia to tanie, bo host i tak je liczy. Drożej robi się, gdy gracze są w dwóch pomieszczeniach naraz, bo wtedy host musi liczyć oba.

- RPC i synchronizatory szukają node'ów po ścieżce, więc oba komputery muszą mieć pomieszczenie pod tą samą ścieżką. `change_scene_to_file` podmienia scenę tylko lokalnie. Starą od razu wyjmuje z drzewa, a pod koniec klatki zwalnia ją razem ze wszystkim pod nią, więc słabo pasuje do świata, który ma trwać.

> **Propozycja A: reguła jednego pomieszczenia.** Zgadza się z dokumentem bioma (nowa scena ładuje się, gdy oboje dotkną wyjścia). Drzwi czekają na oboje albo po krótkim odliczaniu przeciągają partnera, a rozwidlenia zostają w obrębie pomieszczenia. Host podmienia pomieszczenie przez `MultiplayerSpawner` ze `spawn_limit` równym 1. Do ustalenia: rozpadlina w S3 i skok w K2 (gracze lądują w arenie w różnych momentach) albo przenoszą partnera razem, albo na chwilę wymagają dwóch pomieszczeń u hosta.
>
> **Propozycja B: swobodne rozdzielanie.** Sceny pomieszczeń jako dzieci jednej stałej sceny świata, która trzyma graczy i sieć. `MultiplayerSpawner` replikuje tylko bezpośrednie dzieci swojej ścieżki spawnu, zarejestrowane jako spawnowalne sceny. Każde pomieszczenie ma synchronizator z widocznością per peer (`set_visibility_for()`, `add_visibility_filter()`), więc gość dostaje tylko swoje. Wszystkie dzielą jedną przestrzeń fizyki (`World2D`), więc leżą w różnych miejscach jednej siatki świata, żeby na siebie nie wpływały. Druga droga: każde w osobnym `SubViewport`, który ma własny `World2D`. To rzadszy układ, więc najpierw mały prototyp. Ta opcja jest najbliższa pierwszemu pomysłowi Krystiana z jedną dużą mapą.

### 🗄️ Baza Danych (SQLite)

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

### 💾 Zapis Świata i Zmiana Hosta

Sekcja 1 trzyma świat w SQLite u hosta i nazywa bazę „per sesja”. Trzy rzeczy zostają otwarte.

> **Do ustalenia: co znaczy sesja.** Jeden wieczór: co wieczór nowa baza, więc kurhany, liczniki śmierci dla Guślarza i Nemesis znikają po wyjściu z gry. Całe przejście: jeden plik świata na parę, który rośnie z każdym wieczorem.
>
> **Do ustalenia: kto hostuje.** Jeśli hostujemy na zmianę, robią się dwa światy, każdy z własnymi kurhanami i logiem. Opcje:
> 1. Jeden stały host dla danego świata.
> 2. Plik zapisu wędruje z hostem. Kopiujemy go tylko przy zamkniętej grze albo jako snapshot przez `VACUUM INTO` (spójna kopia otwartej bazy) i ustalamy, która kopia wygrywa. Nigdy kopia otwartego pliku ani folder synchronizowany z chmurą: plik WAL to część stanu i oddzielony od bazy może zgubić transakcje albo ją uszkodzić.
>
> **Do ustalenia: gdzie żyje postać gościa** (klasa, Ślub, sprzęt, exp). W zapisie świata razem z postacią hosta: prosto i pasuje do stałej pary. Albo w pliku postaci, który gość przynosi: zagra z każdym partnerem, ale przekazania między dwoma plikami na dwóch PC nie mają wspólnej transakcji, więc przy awarii coś może zniknąć albo się podwoić.

### 🔌 Łączenie przez Internet

- High-level multiplayer w Godocie (ENet) używa tylko UDP. Przez internet host zwykle musi przekierować port UDP na routerze. Klasa `UPNP` może spróbować zrobić to sama, ale jej wywołania blokują (osobny `Thread`), a nie każdy router ma UPnP włączone.
- Jeśli adres WAN routera hosta leży w `100.64.0.0/10` (albo innym prywatnym zakresie), dostawca ma carrier-grade NAT i przekierowanie na naszym routerze nic nie da.
- ENet zgłasza zerwanie dopiero po swoim timeoucie, domyślnie od 5 do 30 s. Co z tym zrobić, opisuje sekcja 5 (Rozłączenie).

> **Propozycja:** na czas prac Tailscale albo ZeroTier, oba darmowe do użytku prywatnego, niekomercyjnego. Instalacja na obu PC, host podaje adres z sieci nakładkowej i nie trzeba pisać żadnego kodu. Gdy Tailscale nie zestawi bezpośredniej ścieżki, puszcza ruch przez relay z większym opóźnieniem (`tailscale ping` pokaże wtedy „via DERP”). GodotSteam dopiero przy ewentualnym wydaniu na Steam: wymaga uruchomionego Steama i testowego app ID 480, a Steam Direct to 100 USD za grę.
>
> **Propozycja:** całe zestawianie połączenia w jednym skrypcie, który tworzy `MultiplayerPeer` i ustawia `multiplayer.multiplayer_peer`. Wywołania ENet zostają poza kodem rozgrywki, więc późniejsza zmiana na Steam dotknie głównie tego pliku. Ten skrypt może też sprawdzać wersję gry przy łączeniu (sekcja 5, Rozłączenie).

### 🧪 Testowanie we Dwóch

Propozycja zestawu, żeby jedna osoba mogła testować co-op bez partnera:

- `Debug > Customize Run Instances` (od Godota 4.3) uruchamia kilka instancji naraz, każdą z własnymi argumentami i feature tagami. Argumenty: host albo join, urządzenie wejścia i nazwa profilu. Gra czyta argumenty użytkownika przez `OS.get_cmdline_user_args()`, a tagi przez `OS.has_feature()`, i pomija menu. Jedno Run daje wtedy od razu połączoną sesję.
- Obie instancje mają domyślnie ten sam folder `user://`, więc otworzyłyby ten sam plik świata. Każda dostaje podfolder nazwany od profilu (Godot nie ma na to przełącznika, folder wybiera gra). Bazę otwiera tylko host, gość dostaje stan wyłącznie przez sieć.
- W 4.7 pad trafia domyślnie do każdej uruchomionej instancji (`input_devices/joypads/ignore_joypad_on_unfocused_application` jest wyłączone). Każda instancja czyta więc tylko swoje urządzenie (`InputEvent.device`, klawiatura to `DEVICE_ID_KEYBOARD`).
- Zastępczy partner: stojący manekin, bot chodzący za graczem albo nagrane wejścia. Wystarczy, żeby jedna osoba sprawdziła flaszkę, ducha i wskrzeszenie, dźwignię na dwóch w S2 i *Uchwyt*.
- Godot nie ma symulatora opóźnień. Na Windowsie jest clumsy, uruchamiany jako administrator, z presetem „localhost ipv4 udp”. Opóźnienie działa w nim w obie strony, więc wartość Lag liczy się do RTT podwójnie. Druga droga to `NetworkSimulator` z netfox.extras: `latency_ms` to opóźnienie w jedną stronę, a symulator działa tylko przy uruchomieniu z edytora. Rozsądny zestaw przy pracy nad walką: 80 ms RTT i 1 do 2% utraty pakietów.
- Nakładka debug pod jednym klawiszem: liczniki, flagi, ostatnie zdarzenia z logu, pamięć wroga i który warunek Guślarza jest teraz spełniony. Do tego komendy, które ustawiają licznik albo flagę.
- Instancja zatrzymana na breakpoincie przestaje obsługiwać połączenie, więc druga zrywa je po timeoucie ENet. W buildach debug można ten timeout podnieść przez `ENetPacketPeer.set_timeout()`.
- Cotygodniowy test z sekcji 1 najlepiej z dwóch domów: dwa okna na jednym PC mają wspólny zegar, wspólny procesor i prawie zerowe opóźnienie.

### 🧰 Język i Narzędzia (propozycja)

Język i wersja silnika są ustalone w sekcji 1, reszta do przegadania:

- **Wersja silnika i język (ustalone):** Godot `4.7.2-stable` z 18 sierpnia 2026, build standardowy, GDScript z typami. 4.8 jest w becie (beta2 z 29 października 2026) i ją pomijamy. W README wpisujemy też wersję godot-sqlite.
- **Sieć i baza:** high-level multiplayer na ENet, zdarzenia przez RPC, pozycje przez `MultiplayerSynchronizer`, SQLite przez godot-sqlite za jednym autoloadem. Tailscale albo ZeroTier do grania przez internet w trakcie prac, GodotSteam tylko przy ewentualnym wydaniu na Steam.
- **Python obok gry, nie w niej:** pytest na tych samych plikach `.sql` (wbudowany moduł `sqlite3`), pandas albo DataGrip na logach z testów. Uwaga: SQLite w DataGrip i w Pythonie na Windowsie ma funkcje matematyczne, FTS5 i `R*Tree`, a gotowe binarki godot-sqlite nie mają żadnej z nich. Trzymamy się podstawowego SQL.
- **Testy:** GUT (9.7.1 dla 4.7.x) albo gdUnit4 (ma scene runner, który symuluje akcje wejścia). Oba działają z GDScript.
- **IDE:** na start wystarczy edytor wbudowany w Godota. JetBrains Rider jest darmowy do użytku niekomercyjnego i też obsługuje GDScript.

---

## 7. Lista Otwartych Punktów

Wszystkie pozycje `[DO UZUPEŁNIENIA]` z dokumentu w jednym miejscu. Zaznaczaj wykonane.

### Przed startem prac (M0)
- [x] Język w Godot: GDScript czy C#? GDScript z typami.
- [x] Hosting repozytorium: GitHub czy GitLab? GitHub, repo już działa.
- [x] Język commitów: polski czy angielski? Angielski.
- [ ] Linki: tablica zadań, dysk z grafikami, repozytorium.
- [x] Terminy M0 i M1. Bez terminów, robimy bez pośpiechu. Etap jest gotowy, gdy spełnia swój cel.
- [x] Wersja silnika dla obojga: Godot 4.7.2-stable, build standardowy. Aktualizujemy tylko razem, między kamieniami milowymi i bez bet.
- [ ] Git LFS: od pierwszego commitu assetów, jak w tabeli technicznej, czy na start bez LFS?
- [ ] Zasady PR do `main`: kto sprawdza i w jakim czasie (np. 48 h) i czy włączamy ochronę gałęzi `main` (przy publicznym repo działa na darmowym planie GitHuba)?
- [ ] Kto jest właścicielem repo i gry (konto osobiste czy wspólna organizacja, repo prywatne czy publiczne z licencją) i co dalej, jeśli jedno z nas przestanie?
- [ ] Kto ma ostatnie słowo, gdy się nie zgadzamy (np. osoba, która to buduje, po wysłuchaniu drugiej, albo tani test obu wersji), i gdzie zapisujemy decyzje (np. `docs/decisions/`)?
- [x] Kto rozstrzyga trafienia, parowania i uniki gościa: host, czyli prowadzący gracz (opcja A). Opcje B i C zostają jako plan B po testach przez internet.
- [ ] Gra przez internet na czas prac: Tailscale, ZeroTier czy przekierowany port UDP?
- [ ] Jak daleko gracze mogą się rozejść: tylko wspólne pomieszczenie, smycz o jedno pomieszczenie czy swobodnie?
- [ ] Widok z boku: czy postacie i wrogowie się blokują, czy przenikają, i co robi wróg bity w plecy?
- [ ] Sprawdzanie buildu przy łączeniu (`auth_callback`): ID ze stałej `PROTOCOL` podbijanej ręcznie czy z commita gita?

### W trakcie prototypu (M0 → M1)
- [ ] Nazwa i szczegóły zasobu współpracy Maga (tempo, limit, zachowanie przy braku).
- [ ] Docelowe nazwy klas (obecnie robocze: Wojownik, Mag).
- [ ] Nazwa i wygląd bioma 1 oraz Osady.
- [ ] 5 kwestii warunkowych Guślarza.
- [ ] 3–4 moby prototypu, 1 elita, 1 boss – projekty z zapisanymi czasownikami.
- [ ] Wartości balansu: okno Ataku Zgranego, okno Reakcji Łączonych, cooldowny wersji słabych.
- [ ] Framework testów: GUT czy gdUnit4? Oba działają z GDScript.
- [ ] Co znaczy „sesja” dla zapisu świata: jeden wieczór czy całe przejście?
- [ ] Stały host czy zapis wędruje z hostem, i gdzie żyje postać gościa?
- [ ] Czy robimy tabelę reguł świata? Jeśli tak: od jakich wierszy zaczynamy (Guślarz, kurhany) i gdzie ją trzymamy (SQLite, `.csv` czy `Resource`)?
- [ ] S3 i K2: co się dzieje, gdy tylko jeden gracz wpadnie w rozpadlinę albo skoczy do Matecznika? Partner leci z nim od razu, czy to już dwa pomieszczenia naraz?
- [ ] Przed pierwszą kwestią z liczbą: sprawdzić polską liczbę mnogą w `tr_n` na 1, 2, 5, 12 i 22.
- [ ] Ślub Krwi: jak resetuje się blokada flaszki (trafienie na łyk, okno po trafieniu, Ślub do złamania)?
- [ ] Wzór pancerza: odejmowanie czy iloraz? Arkusz z liczbą trafień do zabicia dla pary i dla jednego gracza.
- [ ] Po ilu sekundach bez pakietów pokazujemy „partner traci połączenie" i jakie timeouty ENet (`set_timeout`) ustawiamy w buildach debug?
- [ ] Atak Zgrany: wspólny zegar (ping RPC albo netfox) czy okno mierzone u hosta z tolerancją ok. jednego RTT?
- [ ] Numery pingowanych wrogów: osobna numeracja dla każdego gracza czy nadaje je host?
- [ ] Jakie zdarzenie zapisuje rozłączenie (np. `session_aborted`), żeby kurhany, Guślarz i awanse nigdy nie liczyły go jako śmierci?

### Po prototypie (decyzja o pełnej wersji)
- [ ] Decyzja: pełna gra czy nie?
- [ ] Grafika i dźwięk – kto wykonuje i w jakiej stylistyce.
- [ ] Lista biomów od Osady do Nawii.
- [ ] Pozostali NPC (imiona, role, reakcje na bazę).
- [ ] Kolejne klasy – czy wdrażamy koncepcję bohaterów z różnych epok? Jeśli tak: decyzja o epoce Wojownika i Maga.
- [ ] Pełna tabela uniwersalnych czasowników po dodaniu klas.
- [ ] Pełna pula Ślubów po testach.
- [ ] Tabela reakcji łączonych dla każdej pary klas.
- [ ] Lista mobów per biom, elit z cechami Nemesis, bossów z fazami.
- [ ] Ponowna ocena zakazu duplikatów klas.
- [ ] Czy w pełnej wersji dochodzą generowane postacie tła i od ilu startuje to ustawienie (pierwsza wersja: co najmniej 20)?
- [ ] Czy spawn rate i dostępność ukrytych przejść zależne od bazy (pierwsza wersja Krystiana) wracają po prototypie i z jakim limitem?
- [ ] Rozwój: co kupuje exp i czy jest wspólny dla pary, czy osobny dla każdego gracza?
- [ ] System Awansów: tylko Elity czy każdy mob? Która śmierć liczy się dla awansu i nauki bossa?
- [ ] Liczba klas w pełnej wersji (notatki: 5 lub 6) i forma reakcji łączonych: tabela na parę czy wspólna tabela statusów?
- [ ] Gesty z koła: zostają ikony czy robimy animacje dla każdej klasy?

### Różnice między wersjami (do ustalenia razem)

Pierwsza wersja to wcześniejsze README i notatki z gałęzi krystian-branch (dziś już tylko w historii gita). Obecny opis to README z gałęzi alex-branch.

| Temat | Pierwsza wersja | Obecny opis | Uwaga |
|---|---|---|---|
| Struktura mapy | Jedna rozległa mapa podzielona na biomy, z pionowymi warstwami głębi w stylu Tibii. Schodzenie w dół zwiększa trudność. | Biomy jako osobne strefy połączonych pomieszczeń, ułożone jeden pod drugim, z Osadą jako hubem i kapliczkami jako punktami kontrolnymi. Zejście niżej też oznacza większą trudność. | Zejście w głąb i rosnąca trudność są w obu wersjach, a różni się to, czy świat to jedna ciągła mapa, czy osobne strefy z pomieszczeń; warto też pamiętać, że Tibia ma widok z góry, a obecny opis zakłada widok z boku. |
| NPC | Minimum 20 proceduralnie generowanych NPC krążących po mapie (w notatkach: 20 albo więcej), którzy reagują na historię graczy, np. zniżką za zabicie lokalnego bossa albo ostrzeżeniem przed lasem, w którym gracze często giną. | Mała obsada stałych postaci (Guślarz, Kupiec, Wędrowiec) z ręcznie pisanymi kwestiami, które wybiera zapytanie do bazy. W prototypie tylko Guślarz. Proceduralni NPC są poza zakresem prototypu. | Przykłady reakcji (zniżka po bossie, ostrzeżenie przed miejscem częstych śmierci) przeszły z pierwszej wersji, a różni się liczba NPC i to, czy są generowani; proceduralni NPC są odłożeni na pełną wersję, nie skreśleni. |
| Kto może awansować (System Awansów) | Każdy zwykły mob, który zabije gracza, awansuje: zabiera część expa, rośnie w siłę i staje się mini-bossem unikalnym dla sesji. | Awansują tylko Elity, najwyżej 3 razy, a zwykłe moby nie awansują. W prototypie awanse są wyłączone, a zabójstwa graczy przez Elitę tylko trafiają do logu SQLite. | Tu wersje są sprzeczne co do tego, kto może awansować, choć sam przebieg awansu (część expa, wzrost siły) jest w obu podobny. |
| Jak baza zmienia świat | Stan bazy wpływa w czasie rzeczywistym na spawn rate wrogów, dostępność ukrytych przejść i zachowanie środowiska. | Baza działa przez pamięć środowiskową (kurhany w miejscach śmierci, trwały ślad po bossie, oznaczeni wrogowie) i przez kwestie NPC. W prototypie tylko kurhany i kwestie Guślarza. | Cel jest ten sam, świat reaguje na dane z bazy, ale zmiany spawnu i przejść w czasie rzeczywistym nie są w obecnym opisie ani zaplanowane, ani wprost odrzucone. |
| Latarnia i niszczalne otoczenie | Mechanika latarni (światło odstrasza wybrane bestie i odsłania ukryte ścieżki) oraz interakcja z otoczeniem (zrzucanie głazów, podpalanie, niszczenie kolumn, żeby przygnieść wrogów) jako część głównej eksploracji. | Latarnia i niszczalne otoczenie są poza zakresem prototypu, jako kandydaci do pełnej wersji. W tabeli czasowników zostały pojedyncze elementy otoczenia, np. rzucana flaszka z ogniem, koksowniki, zrzucenie głazu, wybuch beczki. | Te wersje raczej następują po sobie, niż się wykluczają: pomysły zostały, tylko przesunięte za prototyp, a część interakcji z otoczeniem weszła już do walki. |
| Długość gry i liczba klas | Kampania fabularna na ok. 10 godzin (w notatkach: najwyżej 10 h). Na start 4 lub 5 klas, w notatkach 5 lub 6, z bronią dla różnych klas rozrzuconą po mapie. | Prototyp na ok. 20 do 40 minut w jednym zamkniętym obszarze, z 2 klasami (Wojownik i Mag). O pełnej kampanii decyzja zapada dopiero po M1. | To raczej kolejne etapy niż sprzeczność: 10 godzin i więcej klas mogą zostać celem pełnej gry, jeśli po M1 zapadnie decyzja, że ją robimy. |
| Gałęzie i łączenie z main | Każda rzecz (postać, mapa, system) na własnym branchu, np. `feature/nowy-boss` albo `krystian-sql-zapis`, łączona z `main` po przetestowaniu całości. W notatkach: design, mapy i postacie na osobnych branchach, a potem łączymy w całość. | Gałęzie z prefiksem `feature/`, `fix/` albo `art/`, a merge do `main` dopiero po teście w co-opie online, nie tylko lokalnie. | To ta sama zasada; zmieniło się nazewnictwo (prefiksy zamiast nazw typu `krystian-sql-zapis`) i doszedł warunek testu online. |
| Przykładowe klasy | Przykłady klas: Żerca (wsparcie, magia) i Łowca (dystans, pułapki). | W prototypie Wojownik i Mag, bez klasy leczącej, bo leczenie to wspólna flaszka. Kolejne klasy być może z różnych epok (np. muszkieter, pirat, husarz, alchemik). | To różne przykłady, a nie sprzeczne zasady; jedyny punkt styku to zakaz klasy leczącej, z którym wsparcie Żercy musiałoby się zgadzać. |
| Pamięć wrogów | Wrogowie analizują ruchy graczy: jeśli ktoś cały czas używa jednego ataku, zaczynają go unikać. | Uczą się tylko bossowie i elity. Zwykłe moby się nie uczą, żeby gracz mógł używać ulubionego ataku w codziennej walce. | Mechanika jest ta sama, różni się zasięg: wszyscy wrogowie albo tylko bossowie i elity. |
