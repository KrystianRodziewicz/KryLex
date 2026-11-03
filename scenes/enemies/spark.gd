class_name Spark
extends Node2D
## Iskra Błędnego Ognika: powolny pocisk, niskie obrażenia, krótkie
## podpalenie. Znika po trafieniu albo po czasie życia.

var velocity: Vector2 = Vector2.ZERO
var lifetime: float = 4.0

@onready var hitbox: Hitbox = $Hitbox as Hitbox


func launch(direction: Vector2, speed: float, damage: int, burn_seconds: float,
		life: float, source: Node2D) -> void:
	velocity = direction.normalized() * speed
	lifetime = life
	hitbox.landed.connect(_on_landed)
	hitbox.activate(damage, 40.0, source, false, 0.0, burn_seconds)


func _physics_process(delta: float) -> void:
	position += velocity * delta
	lifetime -= delta
	if lifetime <= 0.0:
		queue_free()


func _on_landed(_hit: HitInfo) -> void:
	hitbox.deactivate()
	visible = false
	queue_free()
