class_name Hitbox
extends Area2D
## Obszar zadający obrażenia. Włączany na aktywne klatki ataku przez
## [method activate_hit] (szablon [HitInfo]) albo wygodne [method activate],
## wyłączany przez [method deactivate]. Każdy hurtbox trafia najwyżej raz na
## aktywację, więc jeden cios liczy się raz, także gdy hit-stop wydłuży
## aktywne klatki (docs/technika.md).
##
## Po każdym trafieniu emituje [signal landed] z wypełnionym wynikiem
## ([member HitInfo.blocked], [member HitInfo.absorbed]), żeby atakujący mógł zareagować.

signal landed(hit: HitInfo)

var template: HitInfo = HitInfo.new()

var _active: bool = false
var _already_hit: Array[Hurtbox] = []

@onready var _shape: CollisionShape2D = $CollisionShape2D as CollisionShape2D


func _ready() -> void:
	monitoring = false
	monitorable = false
	area_entered.connect(_on_area_entered)


## Włącza hitbox z pełnym opisem trafienia.
func activate_hit(p_template: HitInfo) -> void:
	template = p_template
	_already_hit.clear()
	_active = true
	# Zmiana monitoringu jest zablokowana wewnątrz sygnału kolizji,
	# a deactivate() bywa wołane z reakcji na trafienie, więc oba idą z opóźnieniem.
	set_deferred(&"monitoring", true)
	_shape.set_deferred(&"disabled", false)


## Skrót dla zwykłych ciosów i pocisków.
func activate(p_damage: int, p_knockback: float, p_source: Node2D, p_knockdown: bool = false,
		p_bleed_seconds: float = 0.0, p_element: Elements.Kind = Elements.Kind.NONE,
		p_element_seconds: float = 0.0) -> void:
	var hit: HitInfo = HitInfo.new()
	hit.damage = p_damage
	hit.knockback = p_knockback
	hit.source = p_source
	hit.knockdown = p_knockdown
	hit.bleed_seconds = p_bleed_seconds
	hit.element = p_element
	hit.element_seconds = p_element_seconds
	activate_hit(hit)


func deactivate() -> void:
	_active = false
	set_deferred(&"monitoring", false)
	_shape.set_deferred(&"disabled", true)


func _on_area_entered(area: Area2D) -> void:
	if not _active:
		return
	var hurtbox: Hurtbox = area as Hurtbox
	if hurtbox == null or hurtbox in _already_hit:
		return
	if not hurtbox.enabled:
		return
	_already_hit.append(hurtbox)
	var hit: HitInfo = template.copy()
	var origin: Vector2 = hit.source.global_position if hit.source != null else global_position
	var dx: float = hurtbox.global_position.x - origin.x
	hit.direction = Vector2(1.0 if dx >= 0.0 else -1.0, 0.0)
	hurtbox.receive_hit(hit)
	landed.emit(hit)
