# ⚔️ Projekt KryLex - Game Design Document

Mroczna gra akcji/RPG w stylistyce pixel art, oparta na słowiańskiej mitologii, nastawiona na ścisłą kooperację dwóch graczy i dynamicznie reagujący świat.

---

## 📑 Spis Treści
1. [Organizacja i Założenia](#1-organizacja-i-założenia)
2. [Świat, Eksploracja i NPC](#2-świat-eksploracja-i-npc)
3. [Klasy, Rozwój i Ekwipunek](#3-klasy-rozwój-i-ekwipunek)
4. [Walka, Bossowie i Przeciwnicy](#4-walka-bossowie-i-przeciwnicy)
5. [Mechaniki Kooperacji (Online)](#5-mechaniki-kooperacji-online)

---

## 1. Organizacja i Założenia

### 🎯 Główna Wizja
- **Czas gry:** Kampania fabularna na ok. 10 godzin (z możliwością przedłużenia przez eksplorację).
- **Stylistyka:** Pixel art, mroczny, słowiański klimat.

### 👥 Podział Ról
- **Krystian (Backend / Netcode):** Architektura sieciowa, stabilność online, synchronizacja stanu gry między graczami, integracja z bazą danych (SQL).
- **Alex (Design / Mechaniki):** Game design, balans, projektowanie poziomów, zachowania AI, mechaniki walki.

### 🔄 Przepływ Pracy (Git Workflow)
1. **Branch `main`** – Zawsze zawiera stabilną, działającą grę. Nie pracujemy na nim bezpośrednio!
2. Każda nowa rzecz (postać, mapa, system) ma **własny branch** (np. `feature/nowy-boss`, `krystian-sql-zapis`).
3. Łączymy branches z `main` po przetestowaniu całości.

> **[DO UZUPEŁNIENIA - Linki projektowe]**
> - *Link do tablicy zadań (Trello/Jira):* 
> - *Link do dysku z grafikami:* 

---

## 2. Świat, Eksploracja i NPC

### 🗺️ Struktura Mapy
- Jedna, rozległa mapa podzielona na biomy. 
- Wertykalny design (warstwy głębi przypominające strukturę z Tibii) – schodzenie w dół zwiększa poziom trudności.

### 💾 Świat jako żywa Baza Danych (SQL)
- Gra na bieżąco loguje akcje w bazie (śmierci, zabójstwa, dialogi).
- Stan bazy wpływa w czasie rzeczywistym na świat: spawn rate wrogów, dostępność ukrytych przejść, zachowanie środowiska.

### 🗣️ Proceduralni NPC
- Minimum 20 proceduralnie generowanych NPC krążących po mapie.
- NPC reagują na historię graczy (np. dają zniżki za zabicie lokalnego bossa, ostrzegają przed lasem, w którym gracze często giną).

### 🏕️ Eksploracja i Środowisko
- **Mechanika Latarni:** Dynamiczne światło, które odstrasza konkretne bestie i odsłania ukryte ścieżki.
- **Interakcja z otoczeniem:** Zrzucanie głazów, podpalanie otoczenia, niszczenie kolumn, by przygnieść wrogów.

> **[DO UZUPEŁNIENIA - Projektowanie Świata]**
> - *Lista Biomów (np. 1. Bagna Utopców, 2. Przeklęty Bór):*
> - *Ważni NPC (Imiona i rola):*

---

## 3. Klasy, Rozwój i Ekwipunek

### 🛡️ Klasy Postaci
Na start dostępne 4/5 unikalnych klas, których umiejętności wzajemnie się uzupełniają.
> **[DO UZUPEŁNIENIA - Lista Klas]**
> 1. *Klasa 1 (np. Żerca - wsparcie/magia):*
> 2. *Klasa 2 (np. Łowca - dystans/pułapki):*
> 3. *Klasa 3:*
> 4. *Klasa 4:*

### 📜 System "Ślubów" (Vows)
- Zamiast standardowego drzewka, gracz zyskuje potężną umiejętność z surowym ograniczeniem.
- *Przykład:* Ślub Krwi – potężne obrażenia w zwarciu, ale zablokowane leczenie flaszką, dopóki gracz nie zada obrażeń wrogowi.
> **[DO UZUPEŁNIENIA - Pula Ślubów]**
> - *Ślub 1:*
> - *Ślub 2:*

### 🎒 Ekwipunek i Walka Bronią
- Sprzęt przypisany do klas jest ukryty po całej mapie. 
- Czysto matematyczne skalowanie obrażeń względem pancerza (brak "gąbek na pociski").
- **Zużycie broni:** Zamiast napraw, w trakcie walki można rzucić niszczejącą bronią we wroga (krytyczne obrażenia przy roztrzaskaniu) i zmienić ją na nową.

---

## 4. Walka, Bossowie i Przeciwnicy

### 🐺 Słowiański Bestiariusz i Pamięć AI
- Przeciwnicy opierają się na mitologii słowiańskiej (strzygi, lesze itp.).
- **Pamięć AI:** Wrogowie analizują ruchy graczy (jeśli cały czas używasz jednego ataku, wrogowie zaczną go unikać).

### 🩸 System Awansów (Nemesis)
- Zwykły potwór (mob), który zdoła zabić gracza, awansuje. Pobiera część expa, rośnie w siłę i zmienia się w mini-bossa unikalnego dla Waszej sesji.

### 💀 Adaptacyjni Bossowie
- Bossowie po zabiciu gracza uczą się i stają się trudniejsi (zyskują nowe ataki).
- Jednocześnie gra dynamicznie **ułatwia otoczenie** areny bossa (buff do dropu/expa na okolicznych mobach), aby gracze mogli szybko doexpić przed rewanżem.

> **[DO UZUPEŁNIENIA - Projektowanie Przeciwników]**
> - *Lista Zwykłych Mobów:*
> - *Lista Bossów z mechanikami:*

---

## 5. Mechaniki Kooperacji (Online)

### 🧪 Wspólna Flaszka (Zasób Dzielony)
- Obaj gracze mają do dyspozycji **tylko jedną współdzieloną flaszkę leczenia**. Użycie jej przez gracza "A" zabiera ładunek graczowi "B". Wymaga to ciągłej komunikacji.

### ⚔️ Wspólne Ataki (Synergia)
- Walka opiera się na łączeniu umiejętności różnych klas w potężne combo obszarowe lub nakładanie statusów (np. woda + prąd).

### 🖐️ Komunikacja Niewerbalna
- Zaawansowany system pingów i gestów.
- Szybkie oznaczanie celów, proszenie o flaszkę, ostrzeganie przed pułapkami.

> **[DO UZUPEŁNIENIA - Synergie i Gesty]**
> - *Lista wspólnych ataków do zaprogramowania:*
> - *Lista dostępnych pingów w grze:*
