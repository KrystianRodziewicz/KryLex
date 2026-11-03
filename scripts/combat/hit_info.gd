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
