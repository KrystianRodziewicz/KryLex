# 📖 Guślarz – kwestie warunkowe (prototyp)

> Dokument wykonawczy. Uzupełnia README (sekcja 2: NPC) i `biom-1-przeklety-bor.md`.
> Właściciel: Alex. Sekcja „Dane" jest dla Krystiana.

## Kim jest

Stoi w Osadzie przy kapliczce 1, z otwartą księgą. Nie rozmawia – wypowiada. Nie tłumaczy – zapisuje. Gracze słyszą go po wejściu do gry, po każdej szybkiej podróży i po śmierci obojga (powrót do kapliczki 1).

Ton: surowy, rytmiczny, rymowany jak zaklęcie. Lekcja z Boru jest w każdej kwestii, ale schowana w obrazie – nigdy jako instrukcja. Kto nie zrozumie, i tak dostanie wiedzę od wilków, Leszego i strzyg; Guślarz ma sprawić, że *potem* sobie to skojarzy.

## Zasady działania

1. **Jedna kwestia na wizytę.** Brak drzewka dialogowego.
2. **Priorytet, nie losowość.** Warunki sprawdzane od góry tabeli; pierwszy spełniony wygrywa.
3. **Każda kwestia warunkowa pada raz.** Baza zapisuje, że została powiedziana; potem Guślarz wraca do domyślnej.
4. **Każda kwestia uczy albo zamyka.** Nic dla samego klimatu.

## Kwestie

### Domyślne

**Pierwsza wizyta** *(raz, na starcie gry)*
> Dwoje wchodzi – dwoje piszę.
> Bór ma oczy. Bór ma ciszę.
> Nie miecz go budzi, nie tarcza –
> krok między wami mu starcza.

**Domyślna** *(żaden warunek nie jest spełniony)*
> Karta pełna, pióro schnie.
> Idźcie w dół. Bór już wie.

### Warunkowe – sprawdzane od góry, pierwsza spełniona wygrywa

| # | Warunek | Kwestia | Ukryta lekcja |
|---|---|---|---|
| 1 | Boss biomu 1 pokonany | *Włodarz legł. Gasną oczy w Borze.*<br>*Nie cieszcie się – cisza to nie zorze.*<br>*Cisza to oddech. Ktoś niżej*<br>*nie ma oczu – i słyszy bliżej.* | Zamknięcie biomu. Zwycięstwo jako ostrzeżenie, nie nagroda. |
| 2 | Leszy zabił gracza ≥ 1 raz | *Nie on rośnie. To wy znikacie,*<br>*gdy od siebie w las uciekacie.*<br>*Stańcie blisko. Ramię w ramię.*<br>*Wtedy pęka. Wtedy się łamie.* | Mechanika Leszego – dla tych, którzy jej nie odczytali. |
| 3 | Różnica śmierci między graczami ≥ 3 *(wzrok na tym, który ginie częściej)* | *Jedno pada. Drugie stoi.*<br>*Nie pytam, które z was się boi.*<br>*Pytam tylko: kto stał tam,*<br>*gdzie tarcza nie mogła służyć wam.* | *Osłoń* – skierowane do duetu, nie do jednostki. |
| 4 | Śmierci graczy w biomie 1 ≥ 3 (łącznie) | *Trzykroć Bór otworzył grób,*<br>*trzykroć usypał – i został próg.*<br>*Kopiec nie mówi, kto w nim śpi.*<br>*Mówi, gdzie Bór pragnie krwi.* | Kurhany jako informacja – dla tych, którzy ich nie zauważyli. |
| 5 | Kapliczka 2 osiągnięta, flaszka użyta 0 razy | *Nie piliście. Krwi nie było.*<br>*Włodarz śpi – lecz nozdrze żyło.*<br>*Gdy przyjdzie pić, pijcie w cieniu*<br>*cudzych pleców. Nie w spojrzeniu.* | Zapowiedź *Węchu krwi* przed bossem. |

> Teksty są do szlifowania przy wdrożeniu – rytm sprawdza się dopiero na ekranie lub w nagraniu.

## 🔧 Dane (dla Krystiana)

Wystarczą dwie tabele:

```
events(id, time, type, player, biome, room, killer, detail)
npc_lines_said(npc, line_id, time)
```

Typy zdarzeń potrzebne w prototypie: `player_death`, `enemy_killed`, `boss_killed`, `flask_used`, `shrine_reached`, `vow_chosen`.

Warunki jako zapytania (pseudo-SQL):

| # | Zapytanie |
|---|---|
| 1 | `COUNT(*) FROM events WHERE type='boss_killed' AND biome='bor'` ≥ 1 |
| 2 | `COUNT(*) FROM events WHERE type='player_death' AND killer='leszy'` ≥ 1 |
| 3 | `ABS(deaths(A) − deaths(B))` ≥ 3, gdzie `deaths(X) = COUNT(*) FROM events WHERE type='player_death' AND player=X` |
| 4 | `COUNT(*) FROM events WHERE type='player_death' AND biome='bor'` ≥ 3 |
| 5 | `EXISTS(shrine_reached, detail='shrine_2')` AND `COUNT(*) FROM events WHERE type='flask_used'` = 0 |

Każde zapytanie poprzedzone sprawdzeniem `NOT EXISTS(npc_lines_said WHERE npc='guslarz' AND line_id=N)`. Pierwsza wizyta to `line_id=0`, sprawdzana przed wszystkimi.

Dla warunku 3 Guślarz potrzebuje wiedzieć, *który* gracz ginie częściej (kierunek spojrzenia) – zapytanie zwraca id gracza, nie tylko różnicę.

## Poza zakresem prototypu
- Kwestie po wyborze Ślubu (`vow_chosen` jest logowane, ale nieużywane).
- Reakcja na Nemesis (Leszy awansowany).
- Kupiec i Wędrowiec – README, sekcja 2.
