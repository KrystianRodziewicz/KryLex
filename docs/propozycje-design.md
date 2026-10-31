# Propozycje i pytania projektowe

Otwarte pytania do README z opcjami do przegadania. Numery sekcji odnoszą się do README, a odhaczamy je w sekcji 7 README.

## Ilu NPC

> **Do ustalenia:** ilu NPC w pełnej wersji. Pierwsza wersja Krystiana zakładała co najmniej 20 generowanych NPC chodzących po mapie. Obecny opis stawia na małą obsadę stałych postaci, a proceduralnych NPC zostawia na pełną wersję. Opcje:
> 1. Tylko mała obsada, jak teraz.
> 2. Kilku kluczowych NPC robionych ręcznie plus tanie postacie tła składane z części: lista imion, podmiana palety, rola z krótkiej listy. Chodzą po swoim pomieszczeniu i czytają tę samą tabelę reguł co Guślarz. Wtedy 20 to tylko ustawienie, które na start może wynosić 3.
> 3. Co najmniej 20 generowanych NPC, jak w pierwszej wersji.
>
> W opcjach 2 i 3 host tworzy postacie raz, przy starcie nowej gry, i zapisuje każdą jako wiersz w bazie. Gość dostaje gotowe wiersze. Sam seed nie wystarczy: według dokumentacji Godota algorytm `RandomNumberGenerator` to szczegół implementacji, więc po zmianie wersji silnika ten sam seed może dać innych NPC.

## Ślub Krwi

> **Do ustalenia:** jak resetuje się blokada w Ślubie Krwi. Przy obecnym zapisie jedno trafienie na początku walki odblokowuje flaszkę do końca tej walki, więc cena jest dużo łagodniejsza, niż brzmi. Opcje:
> 1. Jedno trafienie, jeden łyk: każdy łyk wymaga trafienia od poprzedniego łyku.
> 2. Okno po trafieniu: flaszka jest otwarta przez kilka sekund po zadaniu obrażeń. Podobnie działa Rally w Bloodborne, gdzie cios oddany w ciągu kilku sekund przywraca część straconego zdrowia.
> 3. Ślub, który można złamać: wolno wypić mimo blokady, ale moc Ślubu znika do następnej kapliczki. Ograniczenie staje się wtedy wyborem.
>
> Przy każdej opcji blokadę warto pokazać na wspólnej flaszce u obu graczy (np. kłódka), żeby partner widział, kiedy posiadacz Ślubu nie może pić. Do dopisania jednym zdaniem: co liczy się jako obrażenia (podpalenie, reakcja zaczęta przez partnera, rzut bronią)?

## Pancerz i exp

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

## Kto awansuje

> **Do ustalenia:** kto może awansować. W pierwszej wersji Krystiana awansował każdy mob, który zabił gracza, a obecny zapis ogranicza to do Elit. Opcje: tylko Elity (jak teraz, moby zostają stałym punktem odniesienia), każdy mob (więcej własnych historii, ale przy częstych śmierciach awanse mogą się sypać seriami) albo każdy mob, ale najwyżej jeden żywy awansowany na biom.
>
> Przy imionach wchodzi polska gramatyka: „zabity przez Kulawą Strzygę” wymaga odmiany imienia złożonego w trakcie gry, a rodzaj zmienia czasownik („zabiła” czy „zabił”). Najprościej trzymać imię zawsze w mianowniku („Nemesis: Kulawy Leszy”) i zapisywać rodzaj stwora, żeby zgadzały się przymiotniki i czasowniki.

## Przeciwwaga areny

> **Uwaga:** przeciwwagę areny da się farmić: celowo zginąć u bossa, a potem zbierać wzmocniony exp i drop. Do tego każdy nauczony ruch to nowa animacja, zapowiedź, hitboxy i balans. Tańsze są zmiany bez nowych klatek, jak futro Niedźwiedzia, które przestaje płonąć. Opcje zamiast tego albo obok:
> 1. Dodatkowa kapliczka bliżej areny, którą już mamy (krótszy powrót, jak Stakes of Marika w Elden Ring).
> 2. Wskazówka od NPC po porażce, tak jak Guślarz ma już kwestię po śmierci od Leszego.
> 3. Okoliczne moby dają narzędzia zamiast expa, np. zapasową broń do rzutu albo flaszkę z ogniem na Futro Włodarza.
> 4. Bonus do expa zostaje, ale z limitem: raz na bossa i tylko na ustaloną liczbę zabójstw.
