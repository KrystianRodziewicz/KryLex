# ⚔️ Projekt KryLex - Game Design Document

Mroczna gra akcji/RPG 2D (side-scroller) w stylistyce pixel art, oparta na słowiańskiej mitologii, nastawiona na ścisłą kooperację dwóch graczy online i świat, który pamięta ich czyny.

> **Status dokumentu:** wersja prototypowa (październik 2026). Opisuje zakres prototypu testowego oraz kierunki rozwoju pełnej gry. Pozycje oznaczone `[DO UZUPEŁNIENIA]` zebrane są w sekcji 6.

---

## 📑 Spis Treści
1. [Organizacja i Założenia](#1-organizacja-i-założenia)
2. [Świat, Eksploracja i NPC](#2-świat-eksploracja-i-npc)
3. [Klasy, Rozwój i Ekwipunek](#3-klasy-rozwój-i-ekwipunek)
4. [Walka, Bossowie i Przeciwnicy](#4-walka-bossowie-i-przeciwnicy)
5. [Mechaniki Kooperacji (Online)](#5-mechaniki-kooperacji-online)
6. [Lista Otwartych Punktów](#6-lista-otwartych-punktów)

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
| Silnik | **Godot 4** | Darmowy, silne 2D, wbudowany high-level multiplayer (ENet / RPC). |
| Model sieci | **Host-authoritative P2P** | Jeden gracz hostuje i jest źródłem prawdy, drugi jest klientem. Brak kosztów serwera. |
| Baza danych | **SQLite przy hoście** | Stan świata żyje w sesji hosta i jest replikowany do klienta. Baza jest *per sesja*, nie globalna. |
| Język | `[DO UZUPEŁNIENIA – GDScript / C#]` | |
| Kontrola wersji | Git + `[DO UZUPEŁNIENIA – GitHub / GitLab]` | Git LFS dla grafik i dźwięków. |

> **Konsekwencja modelu sieci:** wszystko, co wpływa na stan gry (AI, fizyka otoczenia, drop, baza SQL), liczy się wyłącznie na hoście. Klient wysyła tylko input i otrzymuje stan. Mechaniki wymagające precyzyjnego timingu po stronie klienta (parowanie, uniki, Atak Zgrany) muszą uwzględniać kompensację opóźnień.

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
| M0 – Prototyp sieci | Dwie postacie biegają po jednej planszy online, wspólna flaszka działa, zapis do SQLite. | `[DO UZUPEŁNIENIA]` |
| M1 – Prototyp grywalny | Pełny zakres opisany wyżej, od startu do bossa. | `[DO UZUPEŁNIENIA]` |
| Decyzja | Czy robimy pełną grę? Jeśli tak – nowy plan i aktualizacja tego dokumentu. | po M1 |

### 🔄 Przepływ Pracy (Git Workflow)
1. **Branch `main`** – zawsze stabilna, działająca gra. Nie pracujemy na nim bezpośrednio.
2. Każda nowa rzecz ma **własny branch** z prefiksem: `feature/`, `fix/`, `art/` (np. `feature/nemesis-system`, `fix/flask-desync`).
3. Merge do `main` dopiero po przetestowaniu **w co-opie online**, nie tylko lokalnie.
4. Commity opisujemy po polsku lub angielsku – ale konsekwentnie `[DO UZUPEŁNIENIA – wybór]`.

### 🔗 Linki Projektowe
- *Tablica zadań (Trello/Jira):* `[DO UZUPEŁNIENIA]`
- *Dysk z grafikami:* `[DO UZUPEŁNIENIA]`
- *Repozytorium:* `[DO UZUPEŁNIENIA]`

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

### 🗣️ NPC – Nieliczni, ale Pamiętający
Zamiast proceduralnych NPC: **mała obsada stałych postaci** z dialogiem sterowanym bazą. Każdy NPC ma domyślne kwestie oraz kwestie warunkowe zależne od danych z SQLite.

| NPC | Rola | Przykład reakcji na bazę |
|---|---|---|
| **Guślarz** | Przewodnik / narrator. Czyta historię graczy z „księgi". | „Trzykroć już Bór was pochłonął. Może czas zejść inną drogą?" |
| **Kupiec** | Handel, wymiana zużytej broni. | Zniżka po zabiciu bossa z bioma, w którym handluje. |
| **Wędrowiec** | Pojawia się w różnych biomach, daje wskazówki. | Ostrzega przed miejscem, gdzie gracze zginęli najwięcej razy. |

> **[DO UZUPEŁNIENIA – Pozostali NPC i ich imiona]**

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

### 🎒 Ekwipunek i Walka Bronią
- **Sprzęt przypisany do klas** ukryty po całej mapie. Przedmiot dla Wojownika znaleziony przez Maga trzeba **przekazać** partnerowi (fizyczna interakcja – kolejny punkt kontaktu).
- **Czysto matematyczne skalowanie:** obrażenia vs pancerz bez „gąbek na pociski". Formuła jawna i jednakowa dla graczy i wrogów.
- **Zużycie broni:** brak napraw. Niszczejącą broń można **rzucić** we wroga (obrażenia krytyczne przy roztrzaskaniu) i podnieść nową. Rzut w wroga oznaczonego przez partnera lub zaklętego żywiołem = dodatkowy efekt (np. eksplozja zaklęcia).
- **Łup wspólny:** przedmioty z bossów dropią w dwóch wersjach – po jednym dla każdej klasy. Żadnego „kto pierwszy, ten lepszy".

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

### 💀 Adaptacyjni Bossowie
- Boss ma **bazowy zestaw ataków** + pulę 2–3 „nauczonych" ruchów, które odblokowuje po zabiciu gracza. Nauczony ruch jest odpowiedzią na to, co gracze robili (np. jeśli stali daleko – zyskuje szarżę; jeśli parowali – zyskuje atak nieparowalny).
- **Limit eskalacji:** boss uczy się maks. 3 razy. Po trzeciej śmierci graczy nie rośnie dalej.
- **Przeciwwaga po porażce:** gra ułatwia otoczenie areny – okoliczne moby dają więcej expa i dropu, pojawia się dodatkowa kapliczka bliżej areny. Gracze mogą szybko się wzmocnić przed rewanżem zamiast wracać przez cały biom.
- **Mechaniki dwuosobowe:** każdy boss ma przynajmniej jedną fazę, której nie da się przejść w pojedynkę (np. dwa filary do zniszczenia naraz, atak wymagający *Osłoń* od partnera).

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

### 🧪 Zakres Sekcji w Prototypie
- Flaszka: 3 ładunki, zatwierdzanie przez hosta, sygnał użycia przez partnera.
- 1 Atak Zgrany (Wojownik + Mag) z kompensacją lagu.
- 2 Reakcje Łączone (Ogłuszenie → Impuls, Zamrożenie → Uderzenie tarczą).
- Ping kontekstowy z przyciąganiem do celu, 4 konteksty (wróg, przejście, własna postać, partner) + wskaźnik partnera poza ekranem. Koło gestów – opcjonalnie.
- Duch po śmierci + wskrzeszenie poza walką. Obsługa rozłączenia klienta (zatrzymanie + zapis).

---

## 6. Lista Otwartych Punktów

Wszystkie pozycje `[DO UZUPEŁNIENIA]` z dokumentu w jednym miejscu. Zaznaczaj wykonane.

### Przed startem prac (M0)
- [ ] Język w Godot: GDScript czy C#?
- [ ] Hosting repozytorium: GitHub czy GitLab?
- [ ] Język commitów: polski czy angielski?
- [ ] Linki: tablica zadań, dysk z grafikami, repozytorium.
- [ ] Terminy M0 i M1.

### W trakcie prototypu (M0 → M1)
- [ ] Nazwa i szczegóły zasobu współpracy Maga (tempo, limit, zachowanie przy braku).
- [ ] Docelowe nazwy klas (obecnie robocze: Wojownik, Mag).
- [ ] Nazwa i wygląd bioma 1 oraz Osady.
- [ ] 5 kwestii warunkowych Guślarza.
- [ ] 3–4 moby prototypu, 1 elita, 1 boss – projekty z zapisanymi czasownikami.
- [ ] Wartości balansu: okno Ataku Zgranego, okno Reakcji Łączonych, cooldowny wersji słabych.

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
