class_name TrainingDummy
extends StaticBody2D
## Kukła do sprawdzenia ataku w kroku 1 M0. To nie wróg z bestiariusza:
## nie atakuje, nie ma AI, po "śmierci" wraca do pełnego HP. Do usunięcia
## z S1, gdy pojawi się pierwszy mob (S2, wilkołak).

@export var max_hp: int = 60

var hp: int = 0

@onready var _hurtbox: Hurtbox = $Hurtbox as Hurtbox
@onready var _body: ColorRect = $Body as ColorRect
@onready var _label: Label = $Label as Label


func _ready() -> void:
	hp = max_hp
	_hurtbox.hit_received.connect(_on_hit_received)
	_refresh()


func _on_hit_received(hit: HitInfo) -> void:
	hp -= hit.damage
	var who: String = "?"
	var player: Player = hit.source as Player
	if player != null:
		who = "P%d" % player.player_id
	print("[Kukła] %s trafia za %d, zostało %d" % [who, hit.damage, maxi(hp, 0)])
	_body.modulate = Color(2.0, 2.0, 2.0)
	_body.position.x = hit.direction.x * 3.0
	var tween: Tween = create_tween().set_parallel(true)
	tween.tween_property(_body, ^"modulate", Color.WHITE, 0.12)
	tween.tween_property(_body, ^"position:x", 0.0, 0.12)
	if hp <= 0:
		hp = max_hp
		print("[Kukła] rozbita, wraca do %d HP" % max_hp)
	_refresh()


func _refresh() -> void:
	_label.text = "Kukła %d/%d" % [hp, max_hp]
