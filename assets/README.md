# assets

Wspólne.

Grafika zastępcza, dźwięki i fonty. W prototypie tylko graybox i proste kształty. Zanim trafi tu pierwszy prawdziwy asset, ustalamy Git LFS (punkt w sekcji 7 README), bo LFS ustawia się przed commitem plików.

Pliki przenosimy i zmieniamy im nazwy tylko w docku FileSystem w Godocie, inaczej psują się referencje.

`sprites/warrior/` i `sprites/mage/` to części Wojownika i Maga do rigów "z części" (`scenes/player/rigs/`). Nie rysujemy ich ręcznie: generuje je `tools/art/make_parts.py` z map ASCII, więc źródłem prawdy jest skrypt, a PNG to wynik (po kilkaset bajtów każdy, więc na razie bez Git LFS). Pliki `.import` idą do repo razem z PNG.
