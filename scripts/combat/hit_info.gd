class_name HitInfo
extends RefCounted
## Opis jednego trafienia przekazywany z [Hitbox] do [Hurtbox].
## W sieci (krok 2 M0) odpowiada zdarzeniu "trafienie" z id, które host
## rozsyła obu graczom.

var damage: int = 0
var source: Node2D = null
## Kierunek od źródła do celu w poziomie: (1, 0) albo (-1, 0).
var direction: Vector2 = Vector2.RIGHT
var knockback: float = 0.0
## Powalenie: dłuższe ogłuszenie celu (szarża wilkołaka, Uchwyt).
var knockdown: bool = false
## Krwawienie w sekundach; 0 = brak.
var bleed_seconds: float = 0.0
## Podpalenie w sekundach; 0 = brak. Status żywiołowy z README, sekcja 4.
var burn_seconds: float = 0.0

## Wynik, wypełnia go cel: true, gdy trafienie zatrzymała tarcza.
## Źródło czyta to z sygnału [signal Hitbox.landed] (wilk odbija się od tarczy).
var blocked: bool = false
