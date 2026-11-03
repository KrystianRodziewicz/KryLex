class_name HitInfo
extends RefCounted
## Opis jednego trafienia przekazywany z [Hitbox] do [Hurtbox].
## W sieci (krok 2 M0) odpowiada zdarzeniu "trafienie" z id, które host
## rozsyła obu graczom. Ten sam obiekt służy jako szablon przy włączaniu
## hitboxa ([method Hitbox.activate_hit]).

var damage: int = 0
var source: Node2D = null
## Kierunek od źródła do celu w poziomie: (1, 0) albo (-1, 0).
var direction: Vector2 = Vector2.RIGHT
var knockback: float = 0.0
## Powalenie: dłuższe ogłuszenie celu (szarża wilkołaka, Uchwyt).
var knockdown: bool = false
## Krwawienie w sekundach; 0 = brak.
var bleed_seconds: float = 0.0
## Żywioł trafienia i czas statusu (README, sekcja 4). NONE = cios fizyczny.
var element: Elements.Kind = Elements.Kind.NONE
var element_seconds: float = 0.0
## Obrażenia postawy; -1 = tyle, ile obrażeń zdrowia.
var posture_damage: int = -1
## Przerwij: łamie postawę i przerywa bieżący atak celu (uderzenie tarczą, impuls).
var interrupt: bool = false
## Ogłuszenie narzucone przez Przerwij, gdy postawa nie pękła sama.
var stun_seconds: float = 0.0

## Wynik, wypełnia go cel: true, gdy trafienie zatrzymała tarcza.
## Źródło czyta to z sygnału [signal Hitbox.landed] (wilk odbija się od tarczy).
var blocked: bool = false
## Wynik: true, gdy trafienie wchłonęła bariera Maga (bez odbicia, bez ogłuszenia).
var absorbed: bool = false


func copy() -> HitInfo:
	var other: HitInfo = HitInfo.new()
	other.damage = damage
	other.source = source
	other.direction = direction
	other.knockback = knockback
	other.knockdown = knockdown
	other.bleed_seconds = bleed_seconds
	other.element = element
	other.element_seconds = element_seconds
	other.posture_damage = posture_damage
	other.interrupt = interrupt
	other.stun_seconds = stun_seconds
	return other


## Czy to cios fizyczny, który może roztrzaskać zamrożonego wroga.
func is_physical() -> bool:
	return element == Elements.Kind.NONE and damage > 0
