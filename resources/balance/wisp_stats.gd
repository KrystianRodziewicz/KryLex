class_name WispStats
extends EnemyStats
## Liczby Błędnego Ognika (karta w docs/biom-1-przeklety-bor.md, sekcja 2).
## HP bardzo niskie (jedno trafienie), postawy brak: posture_max tak duże,
## że nigdy nie pęknie, a grawitacja 0, bo się unosi.

@export_group("Unoszenie")
## Ok. 2 m nad ziemią; w graybox 32 px.
@export var hover_height: float = 32.0
@export var bob_amplitude: float = 3.0
@export var bob_speed: float = 4.0

@export_group("Ucieczka")
## Zauważa gracza z tej odległości i od tej pory patrzy tylko na niego.
@export var notice_distance: float = 170.0
## Gracz bliżej niż to: ognik się cofa.
@export var flee_distance: float = 96.0
@export var flee_speed: float = 118.0

@export_group("Kuszenie")
## Gracz stoi dłużej niż tyle sekund: ognik wraca i miga.
@export var tempt_delay: float = 1.0
@export var tempt_speed: float = 55.0
## Podlatuje na taką odległość, nie bliżej.
@export var tempt_hold_distance: float = 120.0

@export_group("Iskra")
## Rzuca tylko, gdy gracz jest dalej niż to.
@export var throw_distance: float = 150.0
@export var throw_cooldown: float = 3.0
@export var spark_speed: float = 95.0
@export var spark_damage: int = 4
@export var spark_burn_seconds: float = 2.0
@export var spark_lifetime: float = 4.0
