class_name Hitbox
extends Area2D
## Obszar zadający obrażenia. Włączany na aktywne klatki ataku przez
## [method activate], wyłączany przez [method deactivate]. Każdy hurtbox
## trafia najwyżej raz na aktywację, więc jeden cios liczy się raz,
## także gdy hit-stop wydłuży aktywne klatki (docs/technika.md).

var damage: int = 0
var knockback: float = 0.0
var source: Node2D = null

var _already_hit: Array[Hurtbox] = []

@onready var _shape: CollisionShape2D = $CollisionShape2D as CollisionShape2D


func _ready() -> void:
	monitoring = false
	monitorable = false
	area_entered.connect(_on_area_entered)


func activate(p_damage: int, p_knockback: float, p_source: Node2D) -> void:
	damage = p_damage
	knockback = p_knockback
	source = p_source
	_already_hit.clear()
	monitoring = true
	_shape.set_deferred(&"disabled", false)


func deactivate() -> void:
	monitoring = false
	_shape.set_deferred(&"disabled", true)


func _on_area_entered(area: Area2D) -> void:
	var hurtbox: Hurtbox = area as Hurtbox
	if hurtbox == null or hurtbox in _already_hit:
		return
	_already_hit.append(hurtbox)
	var hit: HitInfo = HitInfo.new()
	hit.damage = damage
	hit.knockback = knockback
	hit.source = source
	var origin: Vector2 = source.global_position if source != null else global_position
	var dx: float = hurtbox.global_position.x - origin.x
	hit.direction = Vector2(1.0 if dx >= 0.0 else -1.0, 0.0)
	hurtbox.receive_hit(hit)
