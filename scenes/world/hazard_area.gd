class_name HazardArea
extends Area2D
## Strefa obrażeń bez hitboxa: dno rozpadliny, kolce. Każdy gracz dostaje
## obrażenia raz na wejście. Początek układu to lewy górny róg.

signal player_damaged(player: Player, amount: int)

@export var damage: int = 20
@export var caption: String = "upadek"
## Id zabójcy do zdarzenia player_death (rodzaj: otoczenie, upadek).
@export var hazard_id: StringName = &"fall"
@export var size: Vector2 = Vector2(64, 16)
## Ten sam gracz nie dostaje obrażeń częściej niż co tyle sekund.
## 0 = raz na wizytę w pomieszczeniu (skok w miejscu na dnie rozpadliny
## to nie kolejny upadek). Kolce dostaną wartość dodatnią.
@export var cooldown_seconds: float = 0.0

var _recent: Array[Player] = []
var _recent_left: Array[float] = []

@onready var _shape: CollisionShape2D = $CollisionShape2D as CollisionShape2D


func _ready() -> void:
	var shape: RectangleShape2D = RectangleShape2D.new()
	shape.size = size
	_shape.shape = shape
	_shape.position = size * 0.5
	body_entered.connect(_on_body_entered)


func _process(delta: float) -> void:
	if cooldown_seconds <= 0.0:
		return
	var i: int = _recent.size() - 1
	while i >= 0:
		_recent_left[i] -= delta
		if _recent_left[i] <= 0.0:
			_recent.remove_at(i)
			_recent_left.remove_at(i)
		i -= 1


func _on_body_entered(body: Node2D) -> void:
	var player: Player = body as Player
	if player == null or not player.is_alive() or player in _recent:
		return
	_recent.append(player)
	_recent_left.append(cooldown_seconds)
	player.apply_direct_damage(damage, self)
	print("[%s] P%d dostaje %d obrażeń" % [caption, player.player_id, damage])
	player_damaged.emit(player, damage)
