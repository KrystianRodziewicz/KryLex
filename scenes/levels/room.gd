class_name Room
extends Node2D
## Jedno pomieszczenie bioma. Każde pomieszczenie to osobna scena z tym
## skryptem na korzeniu (docs/biom-1-przeklety-bor.md, sekcja 4).
##
## Konwencja węzłów:
## - [code]Geometry[/code]: bloki graybox (kolizje),
## - [code]Props[/code]: kapliczki, NPC, przedmioty,
## - [code]Exits[/code]: wyjścia [RoomExit],
## - [code]Spawns[/code]: [Marker2D] nazwane od wejścia
##   ([code]default[/code], [code]from_osada[/code] itd.).

signal exit_triggered(target_room: StringName, entry: StringName)

const FALLBACK_SPAWN: Vector2 = Vector2(64, 300)

## Stałe id do bazy świata, np. [code]osada[/code], [code]s1_za_plotem[/code].
@export var room_id: StringName = &"room"
@export var biome: StringName = &"osada"
@export var title: String = ""
## Granice kamery. Jeden ekran to 640x360.
@export var bounds: Rect2 = Rect2(0, 0, 640, 360)


func _ready() -> void:
	_connect_exits(self)


## Pozycja, w której gracze pojawiają się po wejściu przez [param entry].
func get_spawn(entry: StringName) -> Vector2:
	var spawns: Node = get_node_or_null(^"Spawns")
	if spawns == null:
		return FALLBACK_SPAWN
	var marker: Marker2D = spawns.get_node_or_null(NodePath(String(entry))) as Marker2D
	if marker == null:
		marker = spawns.get_node_or_null(^"default") as Marker2D
	if marker == null:
		push_warning("Room %s: brak Marker2D '%s' ani 'default' w Spawns" % [room_id, entry])
		return FALLBACK_SPAWN
	return marker.global_position


func _connect_exits(node: Node) -> void:
	for child: Node in node.get_children():
		var exit: RoomExit = child as RoomExit
		if exit != null:
			exit.triggered.connect(_on_exit_triggered)
		_connect_exits(child)


func _on_exit_triggered(target_room: StringName, entry: StringName) -> void:
	exit_triggered.emit(target_room, entry)
