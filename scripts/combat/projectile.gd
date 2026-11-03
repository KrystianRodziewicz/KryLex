class_name Projectile
extends Node2D
## Pocisk z hitboxem: leci po prostej, znika po trafieniu albo po czasie
## życia. Warstwy kolizji ustawia scena (pocisk gracza trafia hurtboxy
## wrogów, pocisk wroga hurtboxy graczy). Kolor bierze z żywiołu.
## W sieci (krok 2 M0) spawnuje go host, a klient tylko odtwarza.

var velocity: Vector2 = Vector2.ZERO
var lifetime: float = 2.0

@onready var hitbox: Hitbox = $Hitbox as Hitbox


func launch(direction: Vector2, speed: float, damage: int, knockback: float, source: Node2D,
		element: Elements.Kind = Elements.Kind.NONE, element_seconds: float = 0.0,
		life: float = 2.0) -> void:
	velocity = direction.normalized() * speed
	lifetime = life
	rotation = velocity.angle()
	if element != Elements.Kind.NONE:
		modulate = Elements.color(element)
	hitbox.landed.connect(_on_landed)
	hitbox.activate(damage, knockback, source, false, 0.0, element, element_seconds)


func _physics_process(delta: float) -> void:
	position += velocity * delta
	lifetime -= delta
	if lifetime <= 0.0:
		queue_free()


func _on_landed(_hit: HitInfo) -> void:
	hitbox.deactivate()
	visible = false
	set_physics_process(false)
	queue_free()
