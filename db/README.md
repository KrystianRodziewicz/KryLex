# db

Właściciel: Krystian.

Schemat bazy jako tekst `.sql` oraz autoload `WorldStore`, przez który przechodzi cały SQL w grze. Do bazy pisze tylko host, wsadowo w spokojnych chwilach (kapliczka, zmiana pomieszczenia, wyjście).

Żywy plik bazy leży w `user://`, nie w repo. `.gitignore` pomija `*.db`, `*.db-journal`, `*.db-wal` i `*.db-shm`.
