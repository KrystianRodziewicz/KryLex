# Uruchomienie i sprawdzenie projektu

Stan: **M0, krok 1** (dwie postacie w jednym procesie, bez sieci). Kolejne kroki: [`technika.md`](technika.md#kolejność-prac-w-m0).

![Osada w kroku 1](krok1-osada.png)
![S1 i kukła w kroku 1](krok1-s1.png)

Folder `docs/` ma plik `.gdignore`, więc Godot nie importuje tych obrazków jako zasobów gry.

## Wymagania

- Godot **4.7.2-stable**, build standardowy (bez .NET), ta sama wersja u obojga.
- Git. Git LFS dopiero, gdy ustalimy to w sekcji 7 README.

## Otwarcie w edytorze

1. Project Manager → *Import* → wskaż `project.godot` z tego folderu.
2. F5 uruchamia scenę główną `scenes/main.tscn`: Osada z Guślarzem, kapliczką i Słupem Ślubów, dalej brama do S1.

Ostrzeżenia o brakujących typach i niebezpiecznych wywołaniach są w `project.godot` ustawione na **błąd** (`debug/gdscript/warnings/*`). Skrypt bez typu nie uruchomi się, zgodnie z decyzją z sekcji 1 README.

## Sterowanie (krok 1)

| Akcja | P1 klawiatura (`kb_*`) | P2 pad (`pad_*`) |
|---|---|---|
| Ruch | A / D (strzałki) | lewa gałka, d-pad |
| Skok | Spacja | A |
| Atak | J | X |
| Unik | K | B |
| Blok (tylko Wojownik) | L | LT |
| Interakcja | E | Y |
| Flaszka (krok 3) | Q | LB |
| Ping (M1) | F | RB |

Każdy profil ma własny zestaw akcji w mapie wejścia, więc jedna postać czyta tylko klawiaturę, a druga tylko pad. W kroku 2 M0 każda instancja dostanie inny profil i to samo rozwiązanie zadziała w sieci. Numer urządzenia pada jest dziś `-1` (dowolny pad); przy dwóch padach trzeba go przypiąć w `project.godot`.

Która postać jest na którym urządzeniu i jaką ma klasę, ustawia się w inspektorze węzła `Main` (`p1_stats`, `p1_profile`, `p2_stats`, `p2_profile`).

## Sprawdzenie bez edytora

Oba polecenia zakładają, że `godot` to plik `Godot_v4.7.2-stable_win64.exe` (można go dodać do PATH). Pierwsze uruchomienie po klonie wymaga importu:

```bash
godot --headless --path . --import
```

Ładowanie każdego skryptu, sceny i zasobu (kod wyjścia 1 przy błędzie):

```bash
godot --headless --path . --script res://tools/check_project.gd
```

Test dymny, który sam steruje obiema postaciami (brama na dwóch, przejście do S1, atak na kukłę, skok na padzie):

```bash
godot --headless --path . res://tools/smoke_test.tscn
```

Test dymny wciska akcje przez `Input.action_press`, więc sprawdza tę samą ścieżkę co prawdziwe urządzenia.

## Co jest w repo

| Folder | Co | Właściciel |
|---|---|---|
| `scenes/main.tscn`, `scenes/main.gd` | Sesja lokalna: spawn dwóch postaci, podmiana pomieszczeń, punkt kontrolny, powrót po śmierci obojga. | wspólne |
| `scenes/player/` | Postać: `player.gd` (stany: bezczynność, bieg, powietrze, atak, unik, trafienie, śmierć), `player_input.gd` (profil urządzenia → `InputFrame`). | Krystian |
| `scenes/levels/` | `room.gd` (pomieszczenie), `room_exit.gd` (wyjście czekające na oboje), `graybox/` (bloki), `osada.tscn`, `s1_za_plotem.tscn`. | Alex |
| `scenes/world/` | Kapliczka, Guślarz (kwestia pierwszej wizyty), Słup Ślubów (znacznik). | Alex |
| `scenes/enemies/` | `training_dummy` – kukła do testu ataku, nie wróg z bestiariusza. | Alex |
| `scenes/ui/` | HUD: pomieszczenie, HP obu postaci, ściąga sterowania. | wspólne |
| `scripts/` | Wspólne klasy: `InputFrame`, `Hitbox`, `Hurtbox`, `HitInfo`, `Interactable`, `RoomCamera`. | wspólne |
| `resources/balance/` | `PlayerStats` i dwa `.tres`: Wojownik, Mag. | Alex |
| `net/net.gd` | Autoload `Net`: szkielet hosta i klienta na ENet (krok 2). | Krystian |
| `db/world_store.gd`, `db/migrations/` | Autoload `WorldStore`: bufor zdarzeń w pamięci (krok 1) i schemat SQL (krok 3). | Krystian |
| `tools/` | Sprawdzenie projektu i test dymny. | wspólne |

## Czego jeszcze nie ma (kolejne kroki)

- **Krok 2:** dwie instancje przez localhost (`Debug > Customize Run Instances`), host spawnuje oboje, klient wysyła `InputFrame.to_packed()`.
- **Krok 3:** wspólna flaszka zatwierdzana przez hosta, godot-sqlite za `WorldStore`, migracja `001_init.sql`.
- Pozostałe pomieszczenia Boru (S2 i dalej), pierwszy mob (wilkołak), parowanie, pasek postawy, statusy żywiołowe.
- Osobne kamery dla graczy: dziś jedna kamera śledzi środek między postaciami, bo oboje są w jednym oknie.
