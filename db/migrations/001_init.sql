-- Migracja 1: dwie tabele z docs/npc-guslarz.md plus kolumny x, y pod kurhany
-- (docs/technika.md: "Baza Danych"). Stosowana przez WorldStore przy otwarciu
-- zapisu, gdy PRAGMA user_version < 1. Trzymamy się podstawowego SQL:
-- gotowe binarki godot-sqlite nie mają FTS5, R*Tree ani funkcji matematycznych.

BEGIN;

CREATE TABLE IF NOT EXISTS events (
    id      INTEGER PRIMARY KEY,
    time    INTEGER NOT NULL,        -- unix time (sekundy)
    type    TEXT    NOT NULL,        -- player_death, enemy_killed, boss_killed, flask_used, shrine_reached, vow_chosen, session_aborted
    player  INTEGER,                 -- 1 = host, 2 = gość; NULL gdy zdarzenie nie ma gracza
    biome   TEXT,
    room    TEXT,
    killer  TEXT,                    -- id wroga, np. leszy; NULL gdy nie dotyczy
    detail  TEXT,                    -- np. shrine_2 dla shrine_reached, nazwa ruchu dla player_death
    x       REAL,
    y       REAL
);

CREATE INDEX IF NOT EXISTS idx_events_type ON events (type);
CREATE INDEX IF NOT EXISTS idx_events_type_biome ON events (type, biome);

CREATE TABLE IF NOT EXISTS npc_lines_said (
    npc     TEXT    NOT NULL,
    line_id INTEGER NOT NULL,
    time    INTEGER NOT NULL,
    PRIMARY KEY (npc, line_id)
);

PRAGMA user_version = 1;

COMMIT;
