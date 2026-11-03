# tools

Wspólne.

- `check_project.gd` – ładuje każdy skrypt, scenę i zasób; kod wyjścia 1 przy błędzie. Uruchomienie: `godot --headless --path . --script res://tools/check_project.gd`.
- `smoke_test.tscn` – test dymny kroku 1 M0, sam steruje obiema postaciami przez `Input.action_press`. Uruchomienie: `godot --headless --path . res://tools/smoke_test.tscn`.

Szczegóły: `docs/uruchomienie.md`. Docelowy framework testów (GUT albo gdUnit4) jest do ustalenia w sekcji 7 README; te dwa skrypty nie potrzebują żadnego dodatku.
