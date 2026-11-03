class_name RoomExit
extends Area2D
## Wyjście z pomieszczenia. Domyślnie czeka na oboje graczy: to ogólna
## zasada przejść z docs/biom-1-przeklety-bor.md ("brama na dwóch" w Osadzie
## nie ma osobnego kodu). Martwy partner (duch) nie blokuje przejścia.
##
## Początek układu (origin) to lewy górny róg obszaru o rozmiarze [member size].

signal triggered(target_room: StringName, entry: StringName)

@export var target_room: StringName = &""
## Nazwa Marker2D w [code]Spawns[/code] pomieszczenia docelowego.
@export var entry: StringName = &"default"
@export var requires_both: bool = true
@export var caption: String = ""
@export var size: Vector2 = Vector2(32, 48)

var _inside: Array[Player] = []
var _fired: bool = false

@onready var _shape: CollisionShape2D = $CollisionShape2D as CollisionShape2D
@onready var _rect: ColorRect = $Rect as ColorRect
@onready var _label: Label = $Label as Label


func _ready() -> void:
	var shape: RectangleShape2D = RectangleShape2D.new()
	shape.size = size
	_shape.shape = shape
	_shape.position = size * 0.5
	_rect.position = Vector2.ZERO
	_rect.size = size
	_label.position = Vector2(-24.0, -22.0)
	_label.size = Vector2(size.x + 48.0, 20.0)
	# Wyjścia leżą przy krawędzi pomieszczenia, więc etykieta zostaje w kadrze.
	var room: Room = owner as Room
	if room != null:
		var min_x: float = room.bounds.position.x - global_position.x
		var max_x: float = room.bounds.end.x - global_position.x - _label.size.x
		_label.position.x = clampf(_label.position.x, min_x, maxf(min_x, max_x))
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	_refresh()


func _on_body_entered(body: Node2D) -> void:
	var player: Player = body as Player
	if player == null or player in _inside:
		return
	_inside.append(player)
	_check()


func _on_body_exited(body: Node2D) -> void:
	var player: Player = body as Player
	if player == null:
		return
	_inside.erase(player)
	_refresh()


func _check() -> void:
	if _fired:
		return
	var present: int = 0
	for player: Player in _inside:
		if player.is_alive():
			present += 1
	var needed: int = _alive_player_count() if requires_both else 1
	if present > 0 and present >= needed:
		_fired = true
		_label.text = caption
		triggered.emit(target_room, entry)
	else:
		_refresh()


func _refresh() -> void:
	var waiting: bool = not _inside.is_empty() and not _fired
	_label.text = caption + ("\nCzekam na partnera" if waiting else "")
	_rect.color = Color(0.9, 0.8, 0.4, 0.35) if waiting else Color(0.6, 0.6, 0.7, 0.2)


func _alive_player_count() -> int:
	var count: int = 0
	for node: Node in get_tree().get_nodes_in_group(&"players"):
		var player: Player = node as Player
		if player != null and player.is_alive():
			count += 1
	return count
